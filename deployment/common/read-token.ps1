function read-token {
    param(
        [parameter(mandatory=$true)]
        [string]$Prompt
    )

    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(
            (Read-Host -Prompt $Prompt -AsSecureString)
        )
    )
}
