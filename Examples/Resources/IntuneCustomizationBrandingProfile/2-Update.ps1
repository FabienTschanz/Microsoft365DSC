<#
This example is used to test new resources and showcase the usage of new resources being worked on.
It is not meant to use as a production baseline.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $Credscredential
    )

    Import-DscResource -ModuleName Microsoft365DSC

    Node localhost
    {
        IntuneCustomizationBrandingProfile "IntuneCustomizationBrandingProfile-Example"
        {
            ApplicationId                  = $ApplicationId;
            Assignments                    = @(
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    dataType                                   = "#microsoft.graph.groupAssignmentTarget"
                    groupId                                    = "00000000-0000-0000-0000-000000000000"
                    deviceAndAppManagementAssignmentFilterType = "none"
                    groupDisplayName                           = "Include"
                }
            );
            CertificateThumbprint          = $CertificateThumbprint;
            CompanyPortalBlockedActions    = @(
                MSFT_MicrosoftGraphcompanyPortalBlockedAction{
                    Action    = "remove"
                    OwnerType = "company"
                    Platform  = "windows10AndLater"
                }
            );
            ContactITEmailAddress          = "servicedesk@contoso.com";
            ContactITName                  = "Contoso Service Desk";
            ContactITNotes                 = "Open Monday to Friday, 07:00 - 19:00 CET";
            ContactITPhoneNumber           = "+1 425 555 0134";
            CustomCanSeePrivacyMessage     = "**What Contoso IT can see** Device model, serial number and the apps installed by IT. Read the full [privacy notice](https://privacy.contoso.com).";
            CustomCantSeePrivacyMessage    = "**What Contoso IT cannot see** Your photos, browsing history, text messages and personal files. Read the full [privacy notice](https://privacy.contoso.com).";
            DisableDeviceCategorySelection = $False;
            DisplayName                    = "Company";
            EnrollmentAvailability         = "availableWithPrompts";
            Ensure                         = "Present";
            LandingPageCustomizedImage     = MSFT_MicrosoftGraphMimeContent{
                Type  = "image/jpeg"
                Value = "Base64EncodedString"
            };
            LightBackgroundLogo            = MSFT_MicrosoftGraphMimeContent{
                Type  = "image/png"
                Value = "Base64EncodedString"
            };
            OnlineSupportSiteName          = "Contoso Support";
            OnlineSupportSiteUrl           = "https://support.contoso.com";
            PrivacyUrl                     = "https://www.example.com";
            ProfileDescription             = "";
            ProfileName                    = "IntuneCustomizationBrandingProfile_1";
            RoleScopeTagIds                = @("0");
            ShowAzureADEnterpriseApps      = $True;
            ShowConfigurationManagerApps   = $True;
            ShowDisplayNameNextToLogo      = $True;
            ShowLogo                       = $True;
            ShowOfficeWebApps              = $True;
            TenantId                       = $TenantId;
            ThemeColor                     = MSFT_MicrosoftGraphRgbColor{
                B = 198
                G = 114
                R = 0
            };
            ThemeColorLogo                 = MSFT_MicrosoftGraphMimeContent{
                Type  = "image/png"
                Value = "Base64EncodedString"
            };
        }
    }
}
