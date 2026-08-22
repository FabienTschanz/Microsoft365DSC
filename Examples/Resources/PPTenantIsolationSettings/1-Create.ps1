<#
This example sets Power Platform tenant isolation settings.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $Credscredential
    )

    Import-DscResource -ModuleName Microsoft365DSC

    Node localhost
    {
        PPTenantIsolationSettings 'PPTenantIsolationSettings-Example'
        {
            IsSingleInstance = 'Yes'
            Enabled          = $true
            Rules            = @(
                MSFT_PPTenantRule
                {
                    TenantName = 'contoso.onmicrosoft.com'
                    Direction  = 'Outbound'
                }
                MSFT_PPTenantRule
                {
                    TenantName = 'fabrikam.onmicrosoft.com'
                    Direction  = 'Both'
                }
            )
            Credential       = $Credscredential
        }
    }
}
