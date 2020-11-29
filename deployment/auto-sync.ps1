. "$PSScriptRoot\common\read-token.ps1"

$parameters=get-content "$PSScriptRoot\parameters.json" | convertfrom-json

az webapp create `
 --subscription $parameters.subscription `
 --name $parameters.webapp `
 --plan $parameters.appservicePlan `
 --resource-group $parameters.resourceGroup `
 --deployment-source-url $parameters.githubRepo

az webapp deployment source config `
 --subscription $parameters.subscription `
 --resource-group $parameters.resourceGroup `
 --name $parameters.webapp `
 --repo-url $parameters.githubRepo `
 --git-token (read-token -Prompt "GitHub Personal Access Token") `
 --branch master `
 --repository-type github
