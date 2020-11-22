function ping-uri {
    param(
        [parameter(mandatory=$true)]
        [string]$URI
    )

    return (invoke-webrequest $URI -SkipHttpErrorCheck).StatusCode -EQ 200
}