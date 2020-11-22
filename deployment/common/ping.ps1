function ping-uri {
    param(
        [parameter(mandatory=$true)]
        [string]$URI
    )

    $Status=200

    try {
        $Status=(invoke-webrequest $URI -SkipHttpErrorCheck).StatusCode
    }
    catch {
        $Status=404
    }

    return $Status -EQ 200
}