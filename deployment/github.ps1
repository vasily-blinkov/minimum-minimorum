$SubID = "0efe8e0b-fdce-4064-a660-008339591626"
$ResGrpNomini = "SwallowTheDictionary-rg"
$AppSvcPlanNomini = "SwallowTheDictionary-plan"

$WebAppNomini = "MinimumMinimorum"
$GHRepoURL = "https://github.com/vasily-blinkov/minimum-minimorum"

write-host '- Should I create a web app?'
If ((az webapp list --query "[?name=='MinimumMinimorum'].name" | convertfrom-json | measure).Count -EQ 0) {
    write-host '- Yes, I should.'
    az webapp create `
     --name "$WebAppNomini" `
     --plan "/subscriptions/$SubID/resourceGroups/$ResGrpNomini/providers/Microsoft.Web/serverfarms/$AppSvcPlanNomini" `
     --resource-group "$ResGrpNomini" `
     --deployment-source-url "$GHRepoURL"
}
Else {
    write-host '- No, I needn''t.'
}

write-host '- Now I''m performing a synchronization.'
az webapp deployment source sync `
 --name "$WebAppNomini" `
 --resource-group "$ResGrpNomini"
write-host '- I''m finished.'
