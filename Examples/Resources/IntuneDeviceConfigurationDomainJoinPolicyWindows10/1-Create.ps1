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
        IntuneDeviceConfigurationDomainJoinPolicyWindows10 'IntuneDeviceConfigurationDomainJoinPolicyWindows10-Example'
        {
            ActiveDirectoryDomainName         = "corp.contoso.com";
            Assignments                       = @(
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    dataType                                   = '#microsoft.graph.groupAssignmentTarget'
                    deviceAndAppManagementAssignmentFilterType = 'none'
                    groupDisplayName                           = 'Autopilot Hybrid Join Devices'
                }
            );
            ComputerNameStaticPrefix          = "WKS";
            ComputerNameSuffixRandomCharCount = 11;
            Description                       = "Joins newly provisioned workstations to the corporate Active Directory domain";
            DisplayName                       = "Domain Join";
            Ensure                            = "Present";
            OrganizationalUnit                = "OU=Workstations,OU=Contoso,DC=corp,DC=contoso,DC=com";
            RoleScopeTagIds                   = @("0");
            ApplicationId                     = $ApplicationId;
            TenantId                          = $TenantId;
            CertificateThumbprint             = $CertificateThumbprint;
        }
    }
}
