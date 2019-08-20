function Update-InfrastructureVersion {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $infraToolsFunctionName,

        [Parameter(Mandatory = $True)]
        [string]
        $infraToolsTableName,

        [Parameter(Mandatory = $True)]
        [string]
        $deploymentStage
    )
    Write-Output "Updating version..."

    # getting the name of IaC script file
    $fullScriptName = $MyInvocation.PSCommandPath
    $sourceFile = Split-Path $fullScriptName -leaf
    Write-Output "source file: $sourceFile"

    # get latest version defined in the IaC file
    $latestVersion = $(getUpFunctionTotal -parentFile $fullScriptName)
    Write-Output "latest version: $latestVersion"

    $currentVersion = 0
    $couldNotReachInfraTools = $false
    try {
        # this lets me call Invoke-RestMethod to my azure function by allowing TLS, TLS 1.1 and TLS1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
        $currentVersion = $(Invoke-RestMethod "https://$infraToolsFunctionName.azurewebsites.net/api/InfraVersionRetriever?tablename=$infraToolsTableName&stage=$deploymentStage&infraname=$sourceFile")
        Write-Output "Current version is: $currentVersion"
    }
    catch {
        Write-Output "Could not reach infra tools function. Set current version to: $currentVersion"
    }
    
    if ($currentVersion -eq $latestVersion) {
        Write-Output "Environment is up to date, no change."
        $couldNotReachInfraTools = $true;
    }
    Write-Output ""
    # call all the Up functions needed to get to the latest version
    for ($methodIndex=($currentVersion+1); $methodIndex -le $latestVersion; $methodIndex++)
    {
        # execute the up function
        Write-Output "Executing $($methodIndex)_Up()"
        & "$($methodIndex)_Up"
        Write-Output ""

        # update infrastructure version by 1
        Write-Output "Registering new version of infrastructure..."
        try {
            $updateResponse = $(Invoke-RestMethod "https://$infraToolsFunctionName.azurewebsites.net/api/InfraVersionUpdater?tablename=$infraToolsTableName&stage=$deploymentStage&infraname=$sourceFile")
        }
        catch {
            if ($couldNotReachInfraTools -eq $true) {
                Write-Output "Could not reach infra tools, not updating version"
            }
            else {
                Write-Error "Could not reach infra tools: $PSItem"
            }
        }
        Write-Output "Done registering new infrastructure version, response: $updateResponse"
        Write-Output ""
    }
}


function getUpFunctionTotal {
    param($parentFile)

    $tokens = $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $parentFile,
    [ref]$tokens,
    [ref]$errors)

    # Get only function definition ASTs
    $functionDefinitions = $ast.FindAll({
        param([System.Management.Automation.Language.Ast] $Ast)

        $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        # Class methods have a FunctionDefinitionAst under them as well, but we don't want them.
        ($PSVersionTable.PSVersion.Major -lt 5 -or
        $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])

    }, $true)

    # calculating latest version by finding the number of #_Up functions
    $latestVersion = 0;
    $functionDefinitions | ForEach-Object {
        if ($_.Name -match '\d_Up') {
            $latestVersion++
        }
    }
    return $latestVersion
}