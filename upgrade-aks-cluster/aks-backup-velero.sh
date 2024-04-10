#!/bin/bash

AZURE_STORAGE_ACCOUNT="velero-backup2024"
REGION="eastus"
AZURE_RESOURCE_GROUP="velero-rg"
SKU="Standard_GRS"
BLOB_CONTAINER= "velero"
#AZURE_SUBSCRIPTION_ID=""  ### You can provide your desired azure subscription here and install the velero server component, in this shell script I am using the current Azure Subscription Id.

AZURE_SUBSCRIPTION_ID=`az account show |head -4 |tail -1 |cut -d ":" -f2| sed 's/.$//'| tr -d ' '| sed "s/\"//g"`       ### I am using the current Azure Subscription Id. In case you want to provide another subscription ID then comment this line, uncomment above line and provide the desired subscription Id.


##################################### Install velero cli ############################################
wget https://github.com/vmware-tanzu/velero/releases/download/v1.8.1/velero-v1.8.1-linux-amd64.tar.gz -P /opt
tar -xvf /opt/velero-v1.8.1-linux-amd64.tar.gz --directory /opt
mv /opt/velero-v1.8.1-linux-amd64/velero /usr/local/bin/

######################### Create Azure Resource Group ##############################
az group create --location $REGION --name $AZURE_RESOURCE_GROUP

######################### Create Azure Storage Account #############################
az storage account create --name $AZURE_STORAGE_ACCOUNT --resource-group $AZURE_RESOURCE_GROUP --sku $SKU --encryption-services blob --https-only true --kind BlobStorage --access-tier Hot --location eastus --min-tls-version TLS1_2

######################### Create Blob Container ####################################
az storage container create -n $BLOB_CONTAINER --public-access off --account-name $AZURE_STORAGE_ACCOUNT_ID

############## Create Service Principle and use it for velero backup ###############
az ad sp create-for-rbac --name velero-backup --role Contributor --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID > sp.json
AZURE_TENANT_ID=`tail -2 sp.json| head -1| cut -d ":" -f2| | sed "s/\"//g"`
AZURE_CLIENT_ID=`head -2 sp.json|tail -1 |cut -d ":" -f2| sed 's/.$//'| tr -d ' '| sed "s/\"//g"`
AZURE_CLIENT_PASSWORD=`tail -3| head -1| cut -d ":" -f2| sed 's/.$//'| tr -d ' '| sed "s/\"//g"`

echo -e "AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID\nAZURE_TENANT_ID=$AZURE_TENANT_ID\nAZURE_CLIENT_ID=$AZURE_CLIENT_ID\nAZURE_CLIENT_SECRET=$AZURE_CLIENT_PASSWORD\nAZURE_RESOURCE_GROUP=$AZURE_RESOURCE_GROUP" > ./credentials-velero

######################## Install velero server component ###########################
velero install --provider azure --plugins velero/velero-plugin-for-microsoft-azure:v1.4.0 --bucket $BLOB_CONTAINER --secret-file ./credentials-velero --backup-location-config resourceGroup=$AZURE_RESOURCE_GROUP,storageAccount=$AZURE_STORAGE_ACCOUNT,subscriptionId=$AZURE_SUBSCRIPTION_ID --snapshot-location-config apiTimeout=5m,resourceGroup=$AZURE_RESOURCE_GROUP,subscriptionId=$AZURE_SUBSCRIPTION_ID --use-restic

