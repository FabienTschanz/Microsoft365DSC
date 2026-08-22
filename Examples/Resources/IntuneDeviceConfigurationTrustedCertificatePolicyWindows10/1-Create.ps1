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
        IntuneDeviceConfigurationTrustedCertificatePolicyWindows10 'IntuneDeviceConfigurationTrustedCertificatePolicyWindows10-Example'
        {
            Assignments            = @(
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    deviceAndAppManagementAssignmentFilterType = 'none'
                    dataType                                   = '#microsoft.graph.allLicensedUsersAssignmentTarget'
                }
            );
            CertFileName           = "RootCA.cer";
            DestinationStore       = "computerCertStoreRoot";
            DisplayName            = "Trusted Cert";
            Ensure                 = "Present";
            TrustedRootCertificate = "<base64-encoded-root-certificate>"
            ApplicationId          = $ApplicationId;
            TenantId               = $TenantId;
            CertificateThumbprint  = $CertificateThumbprint;
        }
    }
}
