function assert-webapp {
    param(
        [parameter(mandatory=$true)]    
        [string] $WebAppName
    )

    return (az webapp list --query "[?name=='$WebAppName'].name" | convertfrom-json | measure-object).Count -NE 0
}