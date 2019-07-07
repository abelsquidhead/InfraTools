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

function 3_Up {
    Write-Output "at 3_Up"
}

function 4_Up {
    Write-Output "at 4_Up"
    Write-Output "abel variabel 1: $abelVariable1"
}

function 5_Up {
    Write-Output "at 5_Up"
    Write-Output "abel variable 2: $abelVariable2"
}

function 6_Up {
    Write-Output "at 6_Up"
}

function 7_Up {
    Write-Output "at 7_Up"
    Write-Output "abel variabel 1: $abelVariable1"
}
function 8_Up {
    Write-Output "at 8_Up"
    Write-Output "abel variable 2: $abelVariable2"
}

function 9_Up {
    Write-Output "at 9_Up"
    Write-Output "abel variable 2: $abelVariable2"
}

function fuckyou {
    Write-Output "FUCK!!!"
}

Install-Module -Name VersionInfrastructure -Force -Scope CurrentUser
Update-InfrastructureVersion