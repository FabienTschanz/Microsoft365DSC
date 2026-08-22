<#
This example is used to test new resources and showcase the usage of new resources being worked on.
It is not meant to use as a production baseline.
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
        IntuneSecurityBaselineWindows10 'IntuneSecurityBaselineWindows10-Example'
        {
            DisplayName           = 'Windows 10 Security Baseline'
            DeviceSettings        = MSFT_MicrosoftGraphIntuneSettingsCatalogDeviceSettings_IntuneSecurityBaselineWindows10
            {
                Pol_MSS_DisableIPSourceRoutingIPv6           = '1'
                DisableIPSourceRoutingIPv6                   = '0'
                BlockExecutionOfPotentiallyObfuscatedScripts = 'block'
                HardenedUNCPaths_Pol_HardenedPaths           = '1'
                pol_hardenedPaths                            = @(
                    MSFT_MicrosoftGraphIntuneSettingsCatalogpol_hardenedpaths{
                        Key   = '\\*\SYSVOL'
                        Value = 'RequireMutualAuthentication=1,RequireIntegrity=1'
                    }
                )
            }
            UserSettings          = MSFT_MicrosoftGraphIntuneSettingsCatalogUserSettings_IntuneSecurityBaselineWindows10
            {
                AllowWindowsSpotlight = '1'
            }
            Ensure                = 'Present'
            ApplicationId         = $ApplicationId;
            TenantId              = $TenantId;
            CertificateThumbprint = $CertificateThumbprint;
        }
    }
}
