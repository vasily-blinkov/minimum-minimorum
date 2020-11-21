. "$PSScriptRoot\common\validator.ps1"

$parameters=get-content "$PSScriptRoot\parameters.json" | convertfrom-json

function validate-params {
    param(
        [parameter(mandatory=$true)]
        [string]$SubscriptionID,

        [parameter(mandatory=$true)]
        [string]$ResourceGroupName,

        [parameter(mandatory=$true)]
        [string]$AppServicePlanName,

        [parameter(mandatory=$true)]
        [string]$WebAppName,

        [parameter(mandatory=$true)]
        [string]$GitHubRepositoryURL
    )

    $valid=$true

    $valid=$valid -and (validate-parameterresourcegroupname $ResourceGroupName)
    $valid=$valid -and (validate-parametersubscriptionid $SubscriptionID)
    $valid=$valid -and (validate-parametergithubrepourl $GitHubRepositoryURL)
    $valid=$valid -and (validate-parameterappservice $AppServicePlanName)

    return $valid
}

function deploy-webapp {
    param(
        [parameter(mandatory=$true)]
        [string]$SubscriptionID,

        [parameter(mandatory=$true)]
        [string]$ResourceGroupName,

        [parameter(mandatory=$true)]
        [string]$AppServicePlanName,

        [parameter(mandatory=$true)]
        [string]$WebAppName,

        [parameter(mandatory=$true)]
        [string]$GitHubRepositoryURL
    )

    write-host '- Should I create a web app?'
    If ((az webapp list --query "[?name=='$WebAppName'].name" | convertfrom-json | measure).Count -EQ 0) {
        write-host '- Yes, I should.'
        az webapp create `
         --name "$WebAppName" `
         --plan "$AppServicePlanName" `
         --resource-group "$ResourceGroupName" `
         --deployment-source-url "$GitHubRepositoryURL"
    }
    Else {
        write-host '- No, I needn''t.'
    }
    
    write-host '- Now I''m performing synchronization.'
    az webapp deployment source sync `
     --name "$WebAppName" `
     --resource-group "$ResourceGroupName"
    write-host '- I''m finished.'
}

$valid=validate-params `
 -SubscriptionID $parameters.subscription `
 -ResourceGroupName $parameters.resourceGroup `
 -AppServicePlanName $parameters.appservicePlan `
 -WebAppName $parameters.webapp `
 -GitHubRepositoryURL $parameters.githubRepo

if (! $valid) {
    return
}

deploy-webapp `
 -SubscriptionID $parameters.subscription `
 -ResourceGroupName $parameters.resourceGroup `
 -AppServicePlanName $parameters.appservicePlan `
 -WebAppName $parameters.webapp `
 -GitHubRepositoryURL $parameters.githubRepo
