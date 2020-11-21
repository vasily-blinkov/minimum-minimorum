. "$PSScriptRoot\common\validator.ps1"

$parameters=get-content "$PSScriptRoot\parameters.json" | convertfrom-json

function validate-params() {
    param(
        [parameter(mandatory=$true)]
        [string]$ResourceGroupName
    )

    $valid=$true

    $valid=$valid -and (validate-parameterresourcegroupname $ResourceGroupName)

    return $valid
}

function cleanup-webapp() {
    param(
        [parameter(mandatory=$true)]
        [string]$ResourceGroupName,

        [parameter(mandatory=$true)]
        [string]$WebAppName
    )

    az webapp delete --name $WebAppName --resource-group $ResourceGroupName
}

$valid=validate-params `
 -ResourceGroupName $parameters.resourceGroup

if (! $valid) {
    return
}

cleanup-webapp `
 -ResourceGroupName $parameters.resourceGroup `
 -WebAppName $parameters.webapp
