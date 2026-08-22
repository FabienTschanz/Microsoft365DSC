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
        AADAuthenticationMethodPolicyExternal "AADAuthenticationMethodPolicyExternal-Cisco Duo"
        {
            ApplicationId         = $ApplicationId
            TenantId              = $TenantId
            CertificateThumbprint = $CertificateThumbprint
            AppId                 = "c1a3d8f2-5b47-4e19-9f0a-2d6b8e4c7a35"; # Updated Property
            DisplayName           = "Cisco Duo";
            Ensure                = "Present";
            ExcludeTargets        = @(
                MSFT_AADAuthenticationMethodPolicyExternalExcludeTarget{
                    Id = 'Design'
                    TargetType = 'group'
                }
            );
            IncludeTargets        = @(
                MSFT_AADAuthenticationMethodPolicyExternalIncludeTarget{
                    Id = 'Contoso'
                    TargetType = 'group'
                }
            );
            OpenIdConnectSetting  = MSFT_AADAuthenticationMethodPolicyExternalOpenIdConnectSetting{
                discoveryUrl = 'https://graph.microsoft.com/'
                clientId = '7698a352-4939-486e-9974-4ea5aff93f74'
            };
            State                 = "disabled";
        }
    }
}
