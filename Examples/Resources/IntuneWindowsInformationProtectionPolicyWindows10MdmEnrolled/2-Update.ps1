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
        IntuneWindowsInformationProtectionPolicyWindows10MdmEnrolled 'IntuneWindowsInformationProtectionPolicyWindows10MdmEnrolled-Example'
        {
            DisplayName                            = 'WIP'
            AzureRightsManagementServicesAllowed   = $False
            Description                            = 'Protects corporate data on managed Windows 10 devices'
            EnforcementLevel                       = 'encryptAndAuditOnly'
            EnterpriseDomain                       = 'domain.com' # Updated Property
            EnterpriseIPRanges                     = @(
                MSFT_MicrosoftGraphWindowsInformationProtectionIPRangeCollection{
                    DisplayName = 'ipv4 range'
                    Ranges      = @(
                        MSFT_MicrosoftGraphIpRange{
                            UpperAddress = '1.1.1.3'
                            LowerAddress = '1.1.1.1'
                            odataType    = '#microsoft.graph.iPv4Range'
                        }
                    )
                }
            )
            EnterpriseIPRangesAreAuthoritative     = $True
            EnterpriseProxyServersAreAuthoritative = $True
            IconsVisible                           = $False
            IndexingEncryptedStoresOrItemsBlocked  = $False
            ProtectedApps                          = @(
                MSFT_MicrosoftGraphwindowsInformationProtectionApp {
                    Description   = 'Microsoft.MicrosoftEdge'
                    odataType     = '#microsoft.graph.windowsInformationProtectionStoreApp'
                    Denied        = $False
                    PublisherName = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
                    ProductName   = 'Microsoft.MicrosoftEdge'
                    DisplayName   = 'Microsoft Edge'
                }
            )
            ProtectionUnderLockConfigRequired      = $False
            RevokeOnUnenrollDisabled               = $False
            Ensure                                 = 'Present'
            ApplicationId                          = $ApplicationId;
            TenantId                               = $TenantId;
            CertificateThumbprint                  = $CertificateThumbprint;
        }
    }
}
