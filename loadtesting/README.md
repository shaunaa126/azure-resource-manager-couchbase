# azure-resource-manager-couchbase - load testing

You will need nodejs, faker, artillery.io and their dependencies installed on the machine you are testing from.

See: https://artillery.io/

Here is how I execute the script (both the sgt.yml file and my-functions.js need to be in same directory). Update the sgt.yml file to refer to your Couchbase test instance.

    artillery run sgt.yml --insecure

You can turn on DEBUG by doing an export DEBUG=http,http:response to see in detail what is being sent and received.