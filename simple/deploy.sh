#!/bin/sh

RESOURCE_GROUP=$1

# Azure CLI 1.0 commands
azure group create $RESOURCE_GROUP westus
azure group deployment create --template-uri https://raw.githubusercontent.com/shaunaa126/azure-resource-manager-couchbase/master/simple/mainTemplate.json --parameters-file mainTemplateParameters.json $RESOURCE_GROUP couchbase

# Azure CLI 2.0 commands
#az group create --name $RESOURCE_GROUP --location westus
#az group deployment create --template-uri https://raw.githubusercontent.com/shaunaa126/azure-resource-manager-couchbase/master/simple/mainTemplate.json --parameters @mainTemplateParameters.json --resource-group $RESOURCE_GROUP
