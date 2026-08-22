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
            Assignments                = @(
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    deviceAndAppManagementAssignmentFilterType = 'none'
                    dataType                                   = '#microsoft.graph.allDevicesAssignmentTarget'
                }
            );
            Description                = "";
            DeviceNameTemplate         = "CONTOSO-%RAND:6%";
            DeviceType                 = "windowsPc";
            DisplayName                = "AAD";
            EnableWhiteGlove           = $False; # Updated Property
            Ensure                     = "Present";
            ExtractHardwareHash        = $True;
            Language                   = "";
            OutOfBoxExperienceSettings = MSFT_MicrosoftGraphoutOfBoxExperienceSettings1{
                HideEULA                  = $False
                HideEscapeLink            = $True
                HidePrivacySettings       = $True
                DeviceUsageType           = 'singleUser'
                SkipKeyboardSelectionPage = $True
                UserType                  = 'administrator'
            };
            ApplicationId              = $ApplicationId;
            TenantId                   = $TenantId;
            CertificateThumbprint      = $CertificateThumbprint;
        }
    }
}
