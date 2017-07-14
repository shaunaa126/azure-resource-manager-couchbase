#!/bin/sh

RESOURCE_GROUP=$1
REGION=$2
APPGW_PASSWORD=$3
APPGW_CERT=$4
APPGW_KEY=$5
KEYVAULT_SECRET=$6
SYNCGW_PASSWORD=$7
SYNCGW_CERT=$8
SYNCGW_KEY=$9

# Generate and insert SSL keys
./insertcert.sh $APPGW_PASSWORD $APPGW_CERT $APPGW_KEY
./keyvault.sh ${RESOURCE_GROUP}-keyvault $RESOURCE_GROUP $REGION $KEYVAULT_SECRET $SYNCGW_PASSWORD $SYNCGW_CERT $SYNCGW_KEY

# Azure CLI 1.0 commands
azure group create $RESOURCE_GROUP $REGION
azure group deployment create --template-uri https://raw.githubusercontent.com/shaunaa126/azure-resource-manager-couchbase/master/simple/mainTemplate.json --parameters-file mainTemplateParameters.json $RESOURCE_GROUP couchbase

# Azure CLI 2.0 commands
#az group create --name $RESOURCE_GROUP --location $REGION
#az group deployment create --template-uri https://raw.githubusercontent.com/shaunaa126/azure-resource-manager-couchbase/master/simple/mainTemplate.json --parameters @mainTemplateParameters.json --resource-group $RESOURCE_GROUP