function validate-params() {
    #todo
}

function cleanup-webapp() {
    az webapp delete --name $todo --resource-group $todo
}

$valid=validate-params

if (! $valid) {
    return
}

cleanup-webapp
