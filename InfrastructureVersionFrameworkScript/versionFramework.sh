# This function queries the environment for the current version and then applies only 
# the changes necessary to bring the environment up to the latest version.
# The latest version variable needs to be manually updated each time you
# add a new Up function. This function expects two parameters as folows:
#
# INFRAME - local variable used to idenityf the infrastructure name.
#           This value is stored in the DB as row key
#
# LATESTVERSION - local vaiable used to identify the latest version held
#                 in this script. This needs to be manually updated
#                 each time a new version Up method is created
#
updateVersion() {
    INFRANAME=$1
    LATESTVERSION=$2

    # get current version of infrastructure
    CURRENTVERSION=0
    echo "getting infrastructure version"
    curlResponse="$(curl --max-time 12 --request GET "https://$IAC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME.azurewebsites.net/api/InfraVersionRetriever?tablename=$IAC_INFRATABLENAME&stage=$IAC_DEPLOYMENTSTAGE&infraname=$INFRANAME")"
    echo "curlResponce: $curlResponse"
    if [ -z $curlResponse ] ;
    then
        echo "curl response is empty, setting current version to 0"
        CURRENTVERSION=0
    else
        CURRENTVERSION=$curlResponse
    fi
    echo "current infrastructure version: $CURRENTVERSION"

    # call the correct up  
    if [  $CURRENTVERSION -ge $LATESTVERSION ] ;
    then
        echo "infrastructure version up to date"
    else 
        echo "current infrastructure version: $CURRENTVERSION"
        echo "updating infrastructure to version: $LATESTVERSION"
    fi
    for (( methodIndex=$((CURRENTVERSION + 1)); methodIndex<=$LATESTVERSION; methodIndex++))
    do
        echo "executing $methodIndex""_Up()"
        "$methodIndex"_Up
        echo "done with $methodIndex""_Up()"

        # register new version of infrastructure deployed
        echo ""
        echo "registering new version of infrastructure"
        curlResponse="$(curl --request GET "https://$IAC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME.azurewebsites.net/api/InfraVersionUpdater?tablename=$IAC_INFRATABLENAME&stage=$IAC_DEPLOYMENTSTAGE&infraname=$INFRANAME")"
        echo ""
        echo "curl response: $curlResponse"
    done
}

# this figures out the latest version in the IaC shell script 
# file. This also figures out the name of the infrastrucure as code file. 
# These two values will then be used by the updateVersion function.
#
allFunctions="$(declare -F)"
latestVersion="$(echo $allFunctions | grep -oP "\d_Up" | wc -l)"
sourceFile="$(basename "$0")"

updateVersion $sourceFile $latestVersion 