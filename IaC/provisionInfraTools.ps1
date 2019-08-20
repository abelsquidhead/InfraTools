[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipal,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipalSecret,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipalTenantId,

    [Parameter(Mandatory = $True)]
    [string]
    $azureSubscriptionName,

    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupName,

    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupRegion,

    [Parameter(Mandatory = $True)]
    [string]
    $infraToolsStorageName,

    [Parameter(Mandatory = $True)]
    [string]
    $infraToolsStorageRegion,

    [Parameter(Mandatory = $True)]
    [string]
    $infraToolsStorageSku,

    [Parameter(Mandatory = $True)]
    [string]
    $infraToolsFunctionRegion,

    [Parameter(Mandatory = $True)]
    [string]
    $infraToolsFunctionName
)


#region Login ##################################################################

# This logs in a service principal
#
Write-Output "Logging in to Azure with a service principal..."
az login `
    --service-principal `
    --username $servicePrincipal `
    --password $servicePrincipalSecret `
    --tenant $servicePrincipalTenantId
Write-Output "Done logging in to Azure"
Write-Output ""

# This sets the subscription to the subscription I need all my apps to
# run in
#
Write-Output "Setting default azure subscription..."
az account set `
    --subscription $azureSubscriptionName
Write-Output "Done setting default subscription"
Write-Output ""
#endregion #####################################################################


# This creates the resources for infra tools. Resource group, storage and function
#
function 1_Up {
    #region Create resource group ##################################################

    # This creates the resource group 
    #
    Write-Output "Creating resource group..."
    az group create `
        --name $resourceGroupName `
        --location $resourceGroupRegion
    Write-Output "Done creating resource group"
    Write-Output ""
    #endregion #####################################################################



    #region Create storage for infra tools #########################################

    # This creates the Azure Storage used by infra tools for an azure
    # table to track infrastructure version as well as to hold data for
    # the azure function hosting the apis
    #
    Write-Output "Creating storage account for infra tools..."
    az storage account create `
        --name $infraToolsStorageName `
        --location $infraToolsStorageRegion `
        --resource-group $resourceGroupName `
        --sku $infraToolsStorageSku
    Write-Output "Done creating storage account"
    Write-Output ""
    #endregion #####################################################################



    #region Create function to host inra tools api #################################

    # This creates the Azure Function which hosts the infra tools api
    #
    Write-Output "Creating azure function for infra tools..."
    az functionapp create `
        --resource-group $resourceGroupName `
        --consumption-plan-location $infraToolsFunctionRegion `
        --name $infraToolsFunctionName `
        --storage-account $infraToolsStorageName `
        --runtime dotnet
    Write-Output "Done creating function"
    Write-Output ""

    # This gets the connection string from the storage account
    #
    Write-Output "Getting connection string from storage account..."
    $responseString = $(az storage account show-connection-string `
        --resource-group $resourceGroupName `
        --name $infraToolsStorageName)
    $responseObj = $responseString | ConvertFrom-Json
    $connectionString = $responseObj.connectionString
    Write-Output "Done getting connection string"
    Write-Output ""

    # This sets the connection string the the functions app 
    # service settings
    #
    Write-Output "Setting connection string to the app config..."
    az webapp config connection-string set `
        --connection-string-type SQLAzure `
        --resource-group $resourceGroupName `
        --name $infraToolsFunctionName `
        --settings myconnectionstring="$connectionString"
    Write-Output "Done setting connection string"
    Write-Output ""
    #endregion #####################################################################
}

Install-Module -Name VersionInfrastructure -Force -Scope CurrentUser
Update-InfrastructureVersion `
    -infraToolsFunctionName $Env:INFRATOOLS_FUNCTIONNAME `
    -infraToolsTableName $Env:INFRATOOLS_TABLENAME `
    -deploymentStage $Env:INFRATOOLS_DEPLOYMENTSTAGE