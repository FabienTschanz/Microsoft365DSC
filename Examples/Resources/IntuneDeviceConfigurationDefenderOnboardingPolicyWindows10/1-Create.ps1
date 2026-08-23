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
        IntuneDeviceConfigurationDefenderOnboardingPolicyWindows10 'IntuneDeviceConfigurationDefenderOnboardingPolicyWindows10-Example'
        {
            AdvancedThreatProtectionAutoPopulateOnboardingBlob = $false;
            AdvancedThreatProtectionOffboardingBlob            = "<offboarding-blob>";
            AdvancedThreatProtectionOffboardingFilename        = "WindowsDefenderATP.offboarding";
            AdvancedThreatProtectionOnboardingBlob             = "<onboarding-blob>";
            AdvancedThreatProtectionOnboardingFilename         = "WindowsDefenderATP.onboarding";
            AllowSampleSharing                                 = $true;
            Assignments                                        = @(
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    dataType                                   = '#microsoft.graph.groupAssignmentTarget'
                    deviceAndAppManagementAssignmentFilterType = 'none'
                    groupDisplayName                           = 'Corporate Windows Devices'
                }
            );
            Description                                        = "Onboards corporate Windows endpoints to Microsoft Defender for Endpoint";
            DisplayName                                        = "MDE onboarding Legacy";
            EnableExpeditedTelemetryReporting                  = $true;
            Ensure                                             = "Present";
            RoleScopeTagIds                                    = @("0");
            ApplicationId                                      = $ApplicationId;
            TenantId                                           = $TenantId;
            CertificateThumbprint                              = $CertificateThumbprint;
        }
    }
}
