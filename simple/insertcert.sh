#!/bin/bash

#set -e

usage()
{
    echo usage: insertcert.sh '<password> <certpemfile> <keypemfile> <cacertpemfile>'
    echo The cacertpem file is optional. The template will accept a self-signed cert and key.
}

convertcert()
{
    local cert=$1
    local key=$2
    local pfxfile=$3
    local pass=$4

    echo Creating PFX $pfxfile
    openssl pkcs12 -export -out $pfxfile -inkey $key -in $cert -password pass:$pass 2> /dev/null
    cat $pfxfile | base64 >> tmp.txt
    if [ $? -eq 1 ]
    then
        echo problem converting $key and $cert to pfx
        exit 1
    fi    
    pfxencode=$( cat tmp.txt )
    fingerprint=$(openssl x509 -in $cert -noout -fingerprint | cut -d= -f2 | sed 's/://g' )
}

convertcacert()
{
    local cert=$1
    local pfxfile=$2
    local pass=$3

    echo Creating PFX $pfxfile
    openssl pkcs12 -export -out $pfxfile -nokeys -in $cert -password pass:$pass 2> /dev/null
    cat $pfxfile | base64 >> tmp.txt
    if [ $? -eq 1 ]
    then
        echo problem converting $cert to pfx
        exit 1
    fi    
    pfxencode=$( cat tmp.txt )
    fingerprint=$(openssl x509 -in $cert -noout -fingerprint | cut -d= -f2 | sed 's/://g' )
}

pwd=$1
certfile=$2
keyfile=$3
cacertfile=$4

certpfxfile=${certfile%.*crt}.pfx
cacertpfxfile=${cacertfile%.*crt}.pfx

# converting SSL cert to pfx
convertcert $certfile $keyfile $certpfxfile $pwd
certstring=$pfxencode
certprint=$fingerprint
echo $certpfxfile encoded string is $certstring
rm -f $certpfxfile
rm -f tmp.txt

if [ ! -z $cacertfile ]
then
    # converting CA cert to pfx
    convertcacert $cacertfile $cacertpfxfile $pwd
    echo $cacertpfxfile fingerprint is $fingerprint
    cacertstring=$pfxencode
    cacertprint=$fingerprint
    echo $cacertpfxfile encoded string is $cacertstring
    rm -f $cacertpfxfile
    rm -f tmp.txt
fi

# make sure pattern substitution succeeds
cp ./mainTemplateParameters.json.template ./mainTemplateParameters.json

# update parameters file 
sed -i -e 's|REPLACE_BASEENCODEDPFX|'$certstring'|g' ./mainTemplateParameters.json
sed -i -e 's|REPLACE_PFXPASS|'$pwd'|g' ./mainTemplateParameters.json

echo Done