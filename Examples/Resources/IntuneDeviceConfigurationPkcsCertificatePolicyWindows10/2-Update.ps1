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
        IntuneDeviceConfigurationPkcsCertificatePolicyWindows10 'IntuneDeviceConfigurationPkcsCertificatePolicyWindows10-Example'
        {
            Assignments                    = @(
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    deviceAndAppManagementAssignmentFilterType = 'none'
                    dataType                                   = '#microsoft.graph.allLicensedUsersAssignmentTarget'
                }
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    dataType         = '#microsoft.graph.exclusionGroupAssignmentTarget'
                    groupDisplayName = 'Policy Exclusions'
                }
            );
            CertificateStore               = "user";
            CertificateTemplateName        = "ContosoUserAuthentication";
            CertificateValidityPeriodScale = "years";
            CertificateValidityPeriodValue = 1;
            CertificationAuthority         = "ca01.contoso.com\Contoso Issuing CA 01";
            CertificationAuthorityName     = "Contoso Issuing CA 01";
            CustomSubjectAlternativeNames  = @(
                MSFT_MicrosoftGraphcustomSubjectAlternativeName{
                    SanType = 'domainNameService'
                    Name    = 'contoso.com'
                }
            );
            DisplayName                    = "PKCS";
            Ensure                         = "Present";
            KeyStorageProvider             = "usePassportForWorkKspOtherwiseFail";
            RenewalThresholdPercentage     = 30; # Updated Property
            SubjectAlternativeNameType     = "none";
            SubjectNameFormat              = "custom";
            SubjectNameFormatString        = "CN={{UserName}},E={{EmailAddress}}";
            ApplicationId                  = $ApplicationId;
            TenantId                       = $TenantId;
            CertificateThumbprint          = $CertificateThumbprint;
        }
    }
}
