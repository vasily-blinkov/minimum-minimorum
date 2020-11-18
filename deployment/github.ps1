$SubID = "0efe8e0b-fdce-4064-a660-008339591626"
$ResGrpNomini = "SwallowTheDictionary-rg"
$AppSvcPlanNomini = "SwallowTheDictionary-plan"

$WebAppNomini = "MinimumMinimorum"
$GHRepoURL = "https://github.com/vasily-blinkov/minimum-minimorum"

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

    # validate resourcegroupname
    if ((az group list --query "[?name=='SwallowTheDictionary-rg']" | convertfrom-json  | measure).Count -EQ 0) {
        write-error "There is no a resource group named '$ResourceGroupName' found"
        $valid=$false
    }

    # validate subscriptionid
    write-host 'todo'

    # validate githubrepositoryurl
    write-host 'todo'

    # validate appserviceplanname
    write-host 'todo'

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
         --plan "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/serverfarms/$AppServicePlanName" `
         --resource-group "$ResourceGroupName" `
         --deployment-source-url "$GitHubRepositoryURL"
    }
    Else {
        write-host '- No, I needn''t.'
    }
    
    write-host '- Now I''m performing a synchronization.'
    az webapp deployment source sync `
     --name "$WebAppName" `
     --resource-group "$ResourceGroupName"
    write-host '- I''m finished.'
}

$valid=validate-params `
 -SubscriptionID $SubID `
 -ResourceGroupName $ResGrpNomini `
 -AppServicePlanName $AppSvcPlanNomini `
 -WebAppName $WebAppNomini `
 -GitHubRepositoryURL $GHRepoURL

if (! $valid) {
    return
}

deploy-webapp `
 -SubscriptionID $SubID `
 -ResourceGroupName $ResGrpNomini `
 -AppServicePlanName $AppSvcPlanNomini `
 -WebAppName $WebAppNomini `
 -GitHubRepositoryURL $GHRepoURL
