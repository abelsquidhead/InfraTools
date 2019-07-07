[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)]
    [string]
    $abelVariable1,

    [Parameter(Mandatory = $True)]
    [string]
    $abelVariable2
)
function 1_Up {
    Write-Output "at 1_Up"
}

function 2_Up {
    Write-Output "at 2_Up"
}

function fuckyou {
    Write-Output "FUCK!!!"
}

Install-Module -Name VersionInfrastructure -Force
Update-InfrastructureVersion