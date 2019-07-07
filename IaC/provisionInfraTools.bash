# This script creates the infrastructure in azure for the my infrastructure
# tools. This consists of a DNS alias checker as well as an infrastructure 
# versioning system
#

# This creates the resource group used to house this application
#
echo "Creating resource group $IAC_EXCLUSIVE_RESOURCEGROUPNAME in region $IAC_RESOURCEGROUPREGION"
az group create \
    --name $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
    --location $IAC_RESOURCEGROUPREGION
echo "Done creating resource group"
echo ""

#
# This creates the storage account used by the infrastructure tools
#
echo "create storage account for infra tools"
az storage account create \
	--name $IAC_EXCLUSIVE_INFRATOOLSSTORAGENAME \
	--location $IAC_INFRATOOLSSTORAGEREGION \
	--resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
	--sku $IAC_INFRATOOLSSTORAGESKU
echo "done creating storage account"
echo ""


# This creates the function app for the infra tools
#
echo "create the function app for the infrastructure tools"
az functionapp create \
	--resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
	--consumption-plan-location $IAC_INFRATOOLSFUNCTIONCONSUMPTIONPLANREGION \
	--name $IAC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME \
	--storage-account $IAC_EXCLUSIVE_INFRATOOLSSTORAGENAME \
	--runtime $IAC_INFRATOOLSFUNCTIONRUNTIME
echo "done creating function app"
echo ""

# This sets the connection string for our function app
#
echo "getting connection string from storage account"
responseString="$(az storage account show-connection-string \
	--resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
	--name $IAC_EXCLUSIVE_INFRATOOLSSTORAGENAME)"
connectionString="$(echo "$responseString" | jq '.["connectionString"]')"
# this strips off the begin and end quotes
connectionString="$(sed -e 's/^"//' -e 's/"$//' <<<"$connectionString")"
echo "connection string: $connectionString"

echo "setting connection string to the app config"
az webapp config connection-string set \
	--connection-string-type SQLAzure \
	--resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
	--name $IAC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME \
	--settings myconnectionstring="$connectionString"
echo "done setting connection string"
echo ""