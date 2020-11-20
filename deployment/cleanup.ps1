. "$PSScriptRoot\common\validator.ps1"

$parameters=get-content "$PSScriptRoot\parameters.json" | convertfrom-json

function validate-params() {
    param(
        [parameter(mandatory=$true)]
        [string]$ResourceGroupName,

        [parameter(mandatory=$true)]
        [string]$WebAppName
    )

    $valid=$true

    $valid=$valid -and (validate-parameterresourcegroupname $ResourceGroupName)

    return $valid
}

function cleanup-webapp() {
    write-host "az webapp delete --name $todo --resource-group $todo"
}

$valid=validate-params `
 -ResourceGroupName $parameters.resourceGroup `
 -WebAppName $parameters.webapp

if (! $valid) {
    return
}

cleanup-webapp
