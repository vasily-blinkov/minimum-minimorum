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
    if ((az group list --query "[?name=='$ResourceGroupName']" | convertfrom-json  | measure).Count -EQ 0) {
        write-error "There is no a resource group named '$ResourceGroupName' found"
        $valid=$false
    }

    # validate subscriptionid
    if ((az account list --query "[?id=='$SubscriptionID'].name" | convertfrom-json | measure).Count -EQ 0) {
        write-error "There is no a subscription with id '$SubscriptionID' found"
        $valid=$false
    }

    # validate githubrepositoryurl
    if ((invoke-webrequest $GitHubRepositoryURL -SkipHttpErrorCheck).StatusCode -NE 200) {
        write-error "There is a problem accessing the repository at '$GitHubRepositoryURL'"
        $valid=$false
    }

    # validate appserviceplanname
    if ((az appservice plan list --query "[?name=='$AppServicePlanName'].id" | convertfrom-json | measure).Count -EQ 0) {
        write-error "There is no an App Service plan with name '$AppServicePlanName'"
        $valid=$false
    }

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
