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
        IntuneMobileAppsManagedGooglePlayApp "IntuneMobileAppsManagedGooglePlayApp-Example"
        {
            DisplayName           = "Office";
            PackageId             = "com.microsoft.office";
            RoleScopeTagIds       = @("0");
            Ensure                = "Present";
            Assignments           = @(
                MSFT_DeviceManagementManagedGooglePlayMobileAppAssignment{
                    groupDisplayName                           = 'All devices'
                    deviceAndAppManagementAssignmentFilterType = 'none'
                    dataType                                   = '#microsoft.graph.allDevicesAssignmentTarget'
                    intent                                     = 'required'
                }
                MSFT_DeviceManagementManagedGooglePlayMobileAppAssignment{
                    dataType         = '#microsoft.graph.exclusionGroupAssignmentTarget'
                    groupDisplayName = 'Policy Exclusions'
                }
            );
            ApplicationId         = $ApplicationId;
            TenantId              = $TenantId;
            CertificateThumbprint = $CertificateThumbprint;
        }
    }
}
