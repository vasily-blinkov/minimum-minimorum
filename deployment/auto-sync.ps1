. "$PSScriptRoot\common\read-token.ps1"

$parameters=get-content "$PSScriptRoot\parameters.json" | convertfrom-json

#TODO: Проверить, что приложение отсутствует; если отсутствует, выполнить следующую кмд.
az webapp create `
 --subscription $parameters.subscription `
 --name $parameters.webapp `
 --plan $parameters.appservicePlan `
 --resource-group $parameters.resourceGroup `
 --deployment-local-git
#TODO: Иначе (т.е. если приложение существует), выполнить следующую кмд, предварительно исправив ее согласно `az webapp deployment source config-local-git -h`.
az webapp deployment source config-local-git `
 --subscription $parameters.subscription `
 --resource-group $parameters.resourceGroup `
 --name $parameters.webapp `
 --repo-url $parameters.githubRepo `
 --git-token (read-token -Prompt "GitHub Personal Access Token") `
 --branch master `
 --repository-type github
