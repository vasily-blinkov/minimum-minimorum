function validate-parameterresourcegroupname() {
    param(
        [parameter(mandatory=$true)]
        [string]$ResourceGroupName
    )

    if ((az group list --query "[?name=='$ResourceGroupName']" | convertfrom-json  | measure).Count -EQ 0) {
        write-error "There is no a resource group named '$ResourceGroupName' found"
        return $false
    }
    else {
        return $true
    }
}

function validate-parametersubscriptionid() {
    param(
        [parameter(mandatory=$true)]
        [string]$SubscriptionID
    )

    if ((az account list --query "[?id=='$SubscriptionID'].name" | convertfrom-json | measure).Count -EQ 0) {
        write-error "There is no a subscription with id '$SubscriptionID' found"
        return $false
    }
    else {
        return $true
    }
}

function validate-parametergithubrepourl() {
    param(
        [parameter(mandatory=$true)]
        [string]$GitHubRepositoryURL
    )

    if ((invoke-webrequest $GitHubRepositoryURL -SkipHttpErrorCheck).StatusCode -NE 200) {
        write-error "Repository at '$GitHubRepositoryURL' doesn't exist"
        return $false
    }
    else {
        return $true
    }
}
