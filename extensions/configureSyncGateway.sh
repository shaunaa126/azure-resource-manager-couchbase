#!/usr/bin/env bash

echo "Running configureSyncGateway.sh"

adminUsername=$1
adminPassword=$2
uniqueString=$3
location=$4
certprint=$5

echo "Using the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo uniqueString \'$uniqueString\'
echo location \'$location\'
echo certprint \'$certprint\'

serverDNS='vm0.server-'$uniqueString'.'$location'.cloudapp.azure.com'
sslcertfilename=$certprint'.crt'
sslkeyfilename=$certprint'.prv'

file="/home/sync_gateway/sync_gateway.json"
echo '
{
  "SSLCert": "/var/lib/waagent/'$sslcertfilename'",
  "SSLKey": "/var/lib/waagent/'$sslkeyfilename'",
  "interface": "0.0.0.0:4984",
  "adminInterface": "0.0.0.0:4985",
  "log": ["*"],
  "databases": {
    "database": {
      "server": "http://'${serverDNS}':8091",
      "bucket": "sync_gateway",
      "users": {
        "GUEST": { "disabled": false, "admin_channels": ["*"] }
      }
    }
  }
}
' > ${file}
chmod 755 ${file}
chown sync_gateway ${file}
chgrp sync_gateway ${file}
chmod -R 755 /var/lib/waagent

# Need to restart to load the changes
service sync_gateway stop
service sync_gateway start
