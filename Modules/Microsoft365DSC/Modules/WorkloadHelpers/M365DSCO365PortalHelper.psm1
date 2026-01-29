function Invoke-M365DSCO365PortalWebRequest
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Uri,

        [Parameter()]
        [ValidateSet('GET', 'POST')]
        [System.String]
        $Method = 'GET',

        [Parameter()]
        [System.Object]
        $Body
    )

    $headers = @{
        Authorization = (Get-MSCloudLoginConnectionProfile -Workload 'O365Portal').AccessToken
    }

    if ($Uri -notlike "https://*" -and $Uri -notlike "*/admin/api/*")
    {
        $Uri = "https://admin.microsoft.com/admin/api/" + $Uri.TrimStart("/")
    }

    $bodyValue = $null
    if (-not [System.String]::IsNullOrEmpty($Body))
    {
        $bodyValue = ConvertTo-Json $Body -Depth 20 -Compress
    }

    try
    {
        $response = Invoke-WebRequest -Method $Method `
                        -Uri $Uri `
                        -Headers $headers `
                        -Body $bodyValue `
                        -ContentType 'application/json; charset=utf-8' `
                        -UseBasicParsing
    }
    catch
    {
        throw $_
    }

    $result = $null
    if ($response.Content.Length -gt 0)
    {
        $result = ConvertFrom-Json $response.Content -ErrorAction SilentlyContinue
    }
    return $result
}
