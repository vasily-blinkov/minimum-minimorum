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
        [string]$GitHubRepositoryURL
    )

    $valid=$true

    $valid=$valid -and (validate-parameterresourcegroupname $ResourceGroupName)
    $valid=$valid -and (validate-parametersubscriptionid $SubscriptionID)
    $valid=$valid -and (validate-parametergithubrepourl $GitHubRepositoryURL)
    $valid=$valid -and (validate-parameterappservice $AppServicePlanName)

    return $valid
}

function create-webapp {
    param(
        [parameter(mandatory=$true)]
        [string]$WebAppName,

        [parameter(mandatory=$true)]
        [string]$AppServicePlanName,

        [parameter(mandatory=$true)]
        [string]$ResourceGroupName,

        [parameter(mandatory=$true)]
        [string]$GitHubRepositoryURL
    )

    az webapp create `
        --name "$WebAppName" `
        --plan "$AppServicePlanName" `
        --resource-group "$ResourceGroupName" `
        --deployment-source-url "$GitHubRepositoryURL"
}

function compare-repourl {
    param(
        [parameter(mandatory=$true)]
        [string]$WebAppName,

        [parameter(mandatory=$true)]
        [string]$ResourceGroupName,

        [parameter(mandatory=$true)]
        [string]$SubscriptionID,

        [parameter(mandatory=$true)]
        [string]$GitHubRepositoryURL
    )

    $RepoURL=(az webapp deployment source show `
     --name $WebAppName `
     --resource-group $ResourceGroupName `
     --subscription $SubscriptionID `
     --output json `
     --query "{repoUrl: repoUrl}" `
    | convertfrom-json).repoUrl

    return $RepoURL -EQ $GitHubRepositoryURL
}

function update-repourl {
    write-host "todo update repoUrl (az webapp deployment source)"
}

function update-webapp {
    param(
        [parameter(mandatory=$true)]
        [string]$WebAppName,

        [parameter(mandatory=$true)]
        [string]$ResourceGroupName,

        [parameter(mandatory=$true)]
        [string]$SubscriptionID,

        [parameter(mandatory=$true)]
        [string]$GitHubRepositoryURL
    )

    write-host '- Was repository changed since the previous deployment?'
    $RepoURLActual=compare-repourl `
     -WebAppName $WebAppName `
     -ResourceGroupName $ResourceGroupName `
     -SubscriptionID $SubscriptionID `
     -GitHubRepositoryURL $GitHubRepositoryURL
    
    if (! $RepoURLActual) {
        write-host '- Yes, therefore I should update the deployment configuration.'
        update-repourl
    }
    else {
        write-host '- No, no need to update the deployment configuration.'
    }

    write-host '- Now I''m performing synchronization.'
    az webapp deployment source sync `
     --name "$WebAppName" `
     --resource-group "$ResourceGroupName"
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
    if ((az webapp list --query "[?name=='$WebAppName'].name" | convertfrom-json | measure).Count -EQ 0) {
        write-host '- Yes, I should.'
        create-webapp `
         -WebAppName $WebAppName `
         -AppServicePlanName $AppServicePlanName `
         -ResourceGroupName $ResourceGroupName `
         -GitHubRepositoryURL $GitHubRepositoryURL
    }
    else {
        write-host '- No, I needn''t.'
    }
    
    update-webapp `
     -WebAppName $WebAppName `
     -ResourceGroupName $ResourceGroupName `
     -SubscriptionID $SubscriptionID `
     -GitHubRepositoryURL $GitHubRepositoryURL

    write-host '- I''m finished.'
}

$valid=validate-params `
 -SubscriptionID $parameters.subscription `
 -ResourceGroupName $parameters.resourceGroup `
 -AppServicePlanName $parameters.appservicePlan `
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
