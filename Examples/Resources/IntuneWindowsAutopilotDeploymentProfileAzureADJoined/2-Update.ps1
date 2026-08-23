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
        IntuneWindowsAutopilotDeploymentProfileAzureADJoined 'IntuneWindowsAutopilotDeploymentProfileAzureADJoined-Example'
        {
            Assignments                    = @(
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    dataType                                   = "#microsoft.graph.allDevicesAssignmentTarget"
                    deviceAndAppManagementAssignmentFilterType = "none"
                }
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    dataType         = "#microsoft.graph.exclusionGroupAssignmentTarget"
                    groupDisplayName = "Autopilot Provisioning Exclusions"
                }
            );
            Description                    = "User-driven provisioning for Entra joined laptops";
            DeviceNameTemplate             = "CONTOSO-%RAND:6%";
            DeviceType                     = "windowsPc";
            DisplayName                    = "AAD";
            EnableWhiteGlove               = $false; # Updated Property
            EnrollmentStatusScreenSettings = MSFT_MicrosoftGraphwindowsEnrollmentStatusScreenSettings1{
                AllowDeviceUseBeforeProfileAndAppInstallComplete = $false
                AllowDeviceUseOnInstallFailure                   = $true
                AllowLogCollectionOnInstallFailure               = $true
                BlockDeviceSetupRetryByUser                      = $false
                CustomErrorMessage                               = "Setup could not be completed. Please contact the service desk on extension 4500."
                HideInstallationProgress                         = $false
                InstallProgressTimeoutInMinutes                  = 60
            };
            Ensure                         = "Present";
            ExtractHardwareHash            = $true;
            Language                       = "en-US";
            ManagementServiceAppId         = "<application-id>";
            OutOfBoxExperienceSettings     = MSFT_MicrosoftGraphoutOfBoxExperienceSettings1{
                DeviceUsageType           = "singleUser"
                HideEULA                  = $false
                HideEscapeLink            = $true
                HidePrivacySettings       = $true
                SkipKeyboardSelectionPage = $true
                UserType                  = "administrator"
            };
            RoleScopeTagIds                = @("0");
            ApplicationId                  = $ApplicationId;
            TenantId                       = $TenantId;
            CertificateThumbprint          = $CertificateThumbprint;
        }
    }
}
