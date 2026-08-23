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
                    dataType                                   = "#microsoft.graph.allLicensedUsersAssignmentTarget"
                    deviceAndAppManagementAssignmentFilterType = "none"
                }
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    dataType                                   = "#microsoft.graph.exclusionGroupAssignmentTarget"
                    deviceAndAppManagementAssignmentFilterType = "none"
                    groupDisplayName                           = "Exclude"
                }
            );
            CertFileName           = "RootNew.cer"; # Updated Property
            Description            = "Distributes the Contoso enterprise root certification authority to Windows devices";
            DestinationStore       = "computerCertStoreRoot";
            DisplayName            = "Contoso Root CA Trust";
            Ensure                 = "Present";
            RoleScopeTagIds        = @("0");
            TrustedRootCertificate = "<base64-encoded-root-certificate>"
            ApplicationId          = $ApplicationId;
            TenantId               = $TenantId;
            CertificateThumbprint  = $CertificateThumbprint;
        }
    }
}
