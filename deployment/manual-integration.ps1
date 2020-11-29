. "$PSScriptRoot\common\validator.ps1"

$parameters=get-content "$PSScriptRoot\parameters.json" | convertfrom-json

function test-params {
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

function configure-deployment {
    param(
        [parameter(mandatory=$true)]
        [string]$WebAppName,

        [parameter(mandatory=$true)]
        [string]$ResourceGroupName,

        [parameter(mandatory=$true)]
        [string]$GitHubRepositoryURL,

        [parameter(mandatory=$true)]
        [string]$SubscriptionID
    )

    write-host '- Configuring app deployment.'
    az webapp deployment source config `
     --subscription "$SubscriptionID" `
     --resource-group "$ResourceGroupName" `
     --name "$WebAppName" `
     --repo-url "$GitHubRepositoryURL" `
     --manual-integration
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
        [string]$GitHubRepositoryURL,

        [parameter(mandatory=$true)]
        [string]$SubscriptionID
    )

    $Target="$($WebAppName.ToLower()).azurewebsites.net"
    if (ping-uri $Target) {
        write-error "The name '$Target' is already taken by another developer; change the webapp name."
        return $false
    }

    write-host '- Creating a web app.'
    az webapp create `
     --subscription "$SubscriptionID" `
     --name "$WebAppName" `
     --plan "$AppServicePlanName" `
     --resource-group "$ResourceGroupName" `
     --deployment-source-url "$GitHubRepositoryURL"
    
    configure-deployment `
     -SubscriptionID "$SubscriptionID" `
     -ResourceGroupName "$ResourceGroupName" `
     -WebAppName "$WebAppName" `
     -GitHubRepositoryURL "$GitHubRepositoryURL"

    return $true
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

function workout-repourl {
    param(
        [parameter(mandatory=$true)]
        [string]$SubscriptionID,

        [parameter(mandatory=$true)]
        [string]$ResourceGroupName,

        [parameter(mandatory=$true)]
        [string]$WebAppName,

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
        write-host '- Yes, therefore I should update the repository.'
    
        configure-deployment `
         -SubscriptionID "$SubscriptionID" `
         -ResourceGroupName "$ResourceGroupName" `
         -WebAppName "$WebAppName" `
         -GitHubRepositoryURL "$GitHubRepositoryURL"
    }
    else {
        write-host '- No, no need to update the repository.'
    }
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

    workout-repourl `
     -SubscriptionID $SubscriptionID `
     -WebAppName $WebAppName `
     -ResourceGroupName $ResourceGroupName `
     -GitHubRepositoryURL $GitHubRepositoryURL

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

    $Updatable=$true
    write-host '- Should I create a web app?'
    if ((az webapp list --query "[?name=='$WebAppName'].name" | convertfrom-json | measure).Count -EQ 0) {
        write-host '- Yes, I should.'
        $Updatable=create-webapp `
         -WebAppName $WebAppName `
         -AppServicePlanName $AppServicePlanName `
         -ResourceGroupName $ResourceGroupName `
         -GitHubRepositoryURL $GitHubRepositoryURL `
         -SubscriptionID $SubscriptionID
    }
    else {
        write-host '- No, I needn''t.'
    }
    
    if ($Updatable) {
        update-webapp `
         -WebAppName $WebAppName `
         -ResourceGroupName $ResourceGroupName `
         -SubscriptionID $SubscriptionID `
         -GitHubRepositoryURL $GitHubRepositoryURL
    }

    write-host '- I''m finished.'
}

$valid=test-params `
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
