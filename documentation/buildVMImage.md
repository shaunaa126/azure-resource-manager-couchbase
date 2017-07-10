# Build VM Image

This README describes how we build the VM that the templates use.  Users should not need to do this.

## Documentation

Documentation on the process is here.  It is incomplete at best.
* https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-capture-image
* https://azure.microsoft.com/en-us/documentation/articles/marketplace-publishing-vm-image-creation/
* https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-classic-create-upload-vhd/
* https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-classic-capture-image

## Identify the VM Image to Use

    az vm image list-skus --publish Canonical --location westus --offer UbuntuServer

## Create a VM

    az group create --name resourcegroup --location westus
    az storage account create --sku Premium_LRS --resource-group resourcegroup --location westus --name sa34859435734
    az vm create --name vm --resource-group resourcegroup --image Canonical:UbuntuServer:14.04.5-LTS:latest --admin-username couchbase --use-unmanaged-disk --storage-account sa34859435734

SSH into the image using the command:

    ssh couchbase@<publicIpAddress>

## Clear the History

    sudo waagent -deprovision+user -force
    exit

## Deallocate and Generalize the VM Image

    az vm deallocate --resource-group resourcegroup --name vm
    az vm generalize --resource-group resourcegroup --name vm

## Get the SAS URL

First off let's set the connection variable.

    azure storage account connectionstring show sa34859435734 --resource-group resourcegroup
    connection="DefaultEndpointsProtocol=https;AccountName=sa34859435734;AccountKey=<your key>"

Now make sure the image is a vhd.

    azure storage blob list vhds -c $connection

We need to create a URL for the image.  

The Publish Portal could potentially print an error: "The SAS URL start date (st) for the SAS URL should be one day before the current date in UTC, please ensure that the start date for SAS link is on or before mm/dd/yyyy. Please ensure that the SAS URL is generated following the instructions available in the [help link](https://docs.microsoft.com/en-us/azure/marketplace-publishing/marketplace-publishing-vm-image-creation)."

    azure storage container sas create vhds rl 08/04/2017 -c $connection --start 07/04/2017

The Shared Access URL should look like this:

    https://sa34859435734.blob.core.windows.net/vhds?st=2017-03-22T07%3A00%3A00Z&se=2017-04-22T07%3A00%3A00Z&sp=rl&sv=2015-04-05&sr=c&sig=6lL4F5GHcsEJ6o3UV0kwFqmjskTv0IHX6kE%2FiY4MLz4%3D

To get the SAS URL, add the name of the os disk as follows.  You can find it early in your terminal session or in the [Portal](http://portal.azure.com).  Stick that value in a variable so we can use it later.

    url="https://sa34859435734.blob.core.windows.net/vhds/osdisk_PgSDWOnoai.vhd?st=2017-03-22T07%3A00%3A00Z&se=2017-04-22T07%3A00%3A00Z&sp=rl&sv=2015-04-05&sr=c&sig=6lL4F5GHcsEJ6o3UV0kwFqmjskTv0IHX6kE%2FiY4MLz4%3D"

Make sure it works by running:

    wget $url

Once you can successfully get the image, proceed to the [Publisher Portal](https://publish.windowsazure.com).
