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
        IntuneDeviceConfigurationHealthMonitoringPolicyWindows10 'IntuneDeviceConfigurationHealthMonitoringPolicyWindows10-Example'
        {
            AllowDeviceHealthMonitoring             = "enabled";
            Assignments                             = @(
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    deviceAndAppManagementAssignmentFilterType = 'none'
                    dataType                                   = '#microsoft.graph.allLicensedUsersAssignmentTarget'
                }
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    dataType         = '#microsoft.graph.exclusionGroupAssignmentTarget'
                    groupDisplayName = 'Policy Exclusions'
                }
            );
            ConfigDeviceHealthMonitoringCustomScope = "healthMonitoring,privilegeManagement";
            ConfigDeviceHealthMonitoringScope       = @("bootPerformance","windowsUpdates");
            Description                             = "Collects boot performance, Windows Update and privilege management health data from managed laptops"; # Updated Property
            DisplayName                             = "Health Monitoring Configuration";
            Ensure                                  = "Present";
            RoleScopeTagIds                         = @("0");
            ApplicationId                           = $ApplicationId;
            TenantId                                = $TenantId;
            CertificateThumbprint                   = $CertificateThumbprint;
        }
    }
}
