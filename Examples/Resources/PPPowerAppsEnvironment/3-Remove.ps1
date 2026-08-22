<#
This example creates a new PowerApps environment in production.
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
        PPPowerAppsEnvironment 'PPPowerAppsEnvironment-Example'
        {
            DisplayName       = "Contoso Production"
            EnvironmentSKU    = "Production"
            Location          = "canada"
            ProvisionDatabase = $true
            LanguageName      = 1033;
            CurrencyName      = "CAD";
            Ensure            = "Absent"
            Credential        = $Credscredential
        }
    }
}
