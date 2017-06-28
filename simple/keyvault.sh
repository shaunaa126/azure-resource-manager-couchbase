#!/bin/bash

#set -e

usage()
{
    echo usage: keyvault.sh '<keyvaultname> <resource group name> <location> <secretname> <password> <certpemfile> <keypemfile> <cacertpemfile>'
    echo The cacertpem file is optional. The template will accept a self-signed cert and key.
}

creategroup()
{

    azure group show $rgname 2> /dev/null  
    if [ $? -eq 0 ]
    then    
        echo Resource Group $rgname already exists. Skipping creation.
    else
        # Create a resource group for the keyvault
        azure group create -n $rgname -l $location
    fi

}

createkeyvault()
{

    azure keyvault show $vaultname 2> /dev/null
    if [ $? -eq 0 ]
    then    
        echo Key Vault $vaultname already exists. Skipping creation.
    else   
        echo Creating Key Vault $vaultname.

        creategroup 
        # Create the key vault
        azure keyvault create --vault-name $vaultname --resource-group $rgname --location $location
    fi  

    azure keyvault set-policy -u $vaultname -g $rgname --enabled-for-template-deployment true --enabled-for-deployment true

}

convertcert()
{
    local cert=$1
    local key=$2
    local pfxfile=$3
    local pass=$4
    local cerfile=$5

    echo Creating PFX $pfxfile
    openssl pkcs12 -export -out $pfxfile -inkey $key -in $cert -password pass:$pass 2> /dev/null
    if [ $? -eq 1 ]
    then
        echo problem converting $key and $cert to pfx
        exit 1
    fi

    echo Creating CER $cerfile
    openssl x509 -outform der -in $cert -out $cerfile 2> /dev/null
    if [ $? -eq 1 ]
    then
        echo problem converting $cert to cer
        exit 1
    fi

    fingerprint=$(openssl x509 -in $cert -noout -fingerprint | cut -d= -f2 | sed 's/://g' )
}

convertcacert()
{
    local cert=$1
    local pfxfile=$2
    local pass=$3
    local cerfile=$4

    echo Creating PFX $pfxfile
    openssl pkcs12 -export -out $pfxfile -nokeys -in $cert -password pass:$pass 2> /dev/null
    if [ $? -eq 1 ]
    then
        echo problem converting $cert to pfx
        exit 1
    fi    

    echo Creating CER $cerfile
    openssl x509 -outform der -in $cert -out $cerfile 2> /dev/null
    if [ $? -eq 1 ]
    then
        echo problem converting $cert to cer
        exit 1
    fi

    fingerprint=$(openssl x509 -in $cert -noout -fingerprint | cut -d= -f2 | sed 's/://g' )
}

storesecret()
{
    local secretfile=$1
    local name=$2
    filecontentencoded=$( cat $secretfile | base64 )

json=$(cat << EOF
{
"data": "${filecontentencoded}",
"dataType" :"pfx",
"password": "${pwd}"
}
EOF
)

    jsonEncoded=$( echo $json | base64 )

    r=$(azure keyvault secret set --vault-name $vaultname --secret-name $name --value $jsonEncoded)
    if [ $? -eq 1 ]
    then
        echo problem storing secret $name in $vaultname 
        exit 1
    fi    

    id=$(echo $r | grep -o 'https:\/\/[a-z0-9.]*/secrets\/[a-z0-9]*/[a-z0-9]*')
    echo Secret ID is $id
}

outputcert()
{
    local cert=$1

    echo Outputing Base64 encoded $cert
    cat $cert | base64 >> tmp.txt    
    encodedstring=$( cat tmp.txt )
    rm -f tmp.txt
}

vaultname=$1
rgname=$2
location=$3
secretname=$4
pwd=$5
certfile=$6
keyfile=$7
cacertfile=$8

certpfxfile=${certfile%.*crt}.pfx
certcerfile=${certfile%.*crt}.cer
cacertpfxfile=${cacertfile%.*crt}.pfx
cacertcerfile=${cacertfile%.*crt}.cer
casecretname=ca$secretname

createkeyvault

# converting SSL cert to pfx
convertcert $certfile $keyfile $certpfxfile $pwd $certcerfile
certprint=$fingerprint
echo $certpfxfile fingerprint is $fingerprint
outputcert $certcerfile
certstring=$encodedstring
echo $certcerfile encoded string is $certstring
# storing pfx in keyvault
echo Storing $certpfxfile as $secretname
storesecret $certpfxfile $secretname
certid=$id   
#rm -f $certpfxfile

if [ ! -z $cacertfile ]
then
    # converting CA cert to pfx
    convertcacert $cacertfile $cacertpfxfile $pwd $cacertcerfile
    cacertprint=$fingerprint
    echo $cacertpfxfile fingerprint is $fingerprint
    outputcert $cacertcerfile
    cacertstring=$encodedstring
    echo $cacertcerfile encoded string is $cacertstring
    # storing pfx in key vault
    echo Storing $cacertpfxfile as $casecretname
    storesecret $cacertpfxfile $casecretname   
    cacertid=$id
    #rm -f $cacertpfxfile
fi

# make sure pattern substitution succeeds
# cp ./mainTemplateParameters.json.template ./mainTemplateParameters.json

# update parameters file 
sed -i -e 's|REPLACE_CERTURL|'$certid'|g' ./mainTemplateParameters.json
sed -i -e 's|REPLACE_CACERTURL|'$cacertid'|g' ./mainTemplateParameters.json
sed -i -e 's/REPLACE_CERTPRINT/'$certprint'/g' ./mainTemplateParameters.json
sed -i -e 's/REPLACE_CACERTPRINT/'$cacertprint'/g' ./mainTemplateParameters.json
sed -i -e 's/REPLACE_VAULTNAME/'$vaultname'/g' ./mainTemplateParameters.json
sed -i -e 's/REPLACE_VAULTRG/'$rgname'/g' ./mainTemplateParameters.json
sed -i -e 's|REPLACE_BASEENCODEDCERT|'$certstring'|g' ./mainTemplateParameters.json

echo Done