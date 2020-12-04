. "$PSScriptRoot\common\read-token.ps1"
. "$PSScriptRoot\common\assert-webapp.ps1"

$ParametersPath="$PSScriptRoot\parameters.json"
write-host "- Reading '$ParametersPath'"
$parameters=get-content $ParametersPath | convertfrom-json

write-host "- Assert if the '$($parameters.webapp)' web app exists"
if (! (assert-webapp $parameters.webapp)) {
    write-host "- Web app does not exist. Creating"
    az webapp create `
     --subscription $parameters.subscription `
     --name $parameters.webapp `
     --plan $parameters.appservicePlan `
     --resource-group $parameters.resourceGroup `
     --deployment-local-git
}
else {
    write-host "- Web app exists. Skipping creation"
}

write-host "- Configuring web app deployment from the Git repo"
az webapp deployment source config-local-git `
 --subscription $parameters.subscription `
 --resource-group $parameters.resourceGroup `
 --name $parameters.webapp `

$GitRemote="https://$($parameters.deploymentUsername)@$($parameters.webapp).scm.azurewebsites.net/$($parameters.webapp).git"
write-host "- Assert if the '$GitRemote' git remote added"
if ((git remote | where-object {$_ -eq "origin"} | measure-object).count -ne 1<#todo move the cond to assert-gitremote.ps1#>) {
    write-host "- The '$GitRemote' git remote didn't add. Adding"
    git remote add azure "$GitRemote"
}
else {
    write-host "- The '$GitRemote' git remote did add already. Skipping addition"
}
#TODO: Test the script for new web apps
#TODO: Test the script for existing web apps
#TODO: Add removing the azure git remote to the cleanup script
