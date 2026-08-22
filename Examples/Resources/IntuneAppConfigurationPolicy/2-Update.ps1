<#
This example creates a new App Configuration Policy.
#>

Configuration Example
{
    param
    (
        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Import-DscResource -ModuleName Microsoft365DSC

    Node localhost
    {
        IntuneAppConfigurationPolicy 'IntuneAppConfigurationPolicy-Example'
        {
            DisplayName           = 'ContosoNew'
            Description           = 'New Contoso Policy'
            CustomSettings        = @(
                MSFT_IntuneAppConfigurationPolicyCustomSetting {
                    name  = 'com.microsoft.intune.mam.managedbrowser.BlockListURLs'
                    value = 'https://www.aol.com'
                }
                MSFT_IntuneAppConfigurationPolicyCustomSetting {
                    name  = 'com.microsoft.intune.mam.managedbrowser.bookmarks'
                    value = 'Outlook Web|https://outlook.office.com||Bing|https://www.bing.com'
                }
                MSFT_IntuneAppConfigurationPolicyCustomSetting { # Updated Property
                    name  = 'com.microsoft.intune.mam.managedbrowser.homepage'
                    value = 'https://portal.contoso.com'
                });
            Ensure                = 'Present'
            ApplicationId         = $ApplicationId;
            TenantId              = $TenantId;
            CertificateThumbprint = $CertificateThumbprint;
        }
    }
}
