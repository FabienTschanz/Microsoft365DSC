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
        IntuneSettingCatalogASRRulesPolicyWindows10 'IntuneSettingCatalogASRRulesPolicyWindows10-Example'
        {
            DisplayName                                                                = 'Attack Surface Reduction Rules'
            Assignments                                                                = @(
                MSFT_DeviceManagementConfigurationPolicyAssignments {
                    deviceAndAppManagementAssignmentFilterType = 'none'
                    dataType                                   = '#microsoft.graph.allLicensedUsersAssignmentTarget'
                })
            attacksurfacereductiononlyexclusions                                       = @('C:\Program Files\Contoso\Ledger', 'C:\ProgramData\Contoso\Cache', 'D:\LineOfBusiness')
            blockabuseofexploitedvulnerablesigneddrivers                               = 'audit' # Updated Property
            blockexecutablefilesrunningunlesstheymeetprevalenceagetrustedlistcriterion = 'audit'
            Description                                                                = 'Attack surface reduction rules for corporate Windows devices'
            Ensure                                                                     = 'Present'
            ApplicationId                                                              = $ApplicationId;
            TenantId                                                                   = $TenantId;
            CertificateThumbprint                                                      = $CertificateThumbprint;
        }
    }
}
