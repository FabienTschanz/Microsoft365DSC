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
        IntuneDeviceConfigurationEmailProfilePolicyWindows10 'IntuneDeviceConfigurationEmailProfilePolicyWindows10-Example'
        {
            AccountName           = "Contoso Mail";
            Assignments           = @(
                MSFT_DeviceManagementConfigurationPolicyAssignments{
                    dataType                                   = '#microsoft.graph.groupAssignmentTarget'
                    deviceAndAppManagementAssignmentFilterType = 'none'
                    groupDisplayName                           = 'Corporate Mailbox Users'
                }
            );
            Description           = "Configures the built-in Windows mail app for Exchange Online mailboxes"; # Updated Property
            DisplayName           = "Corporate Mail Profile";
            DurationOfEmailToSync = "unlimited";
            EmailAddressSource    = "primarySmtpAddress";
            EmailSyncSchedule     = "fifteenMinutes";
            Ensure                = "Present";
            HostName              = "outlook.office365.com";
            RequireSsl            = $true;
            RoleScopeTagIds       = @("0");
            SyncCalendar          = $true;
            SyncContacts          = $true;
            SyncTasks             = $true;
            UserDomainNameSource  = "fullDomainName";
            UsernameAADSource     = "userPrincipalName";
            UsernameSource        = "userPrincipalName";
            ApplicationId         = $ApplicationId;
            TenantId              = $TenantId;
            CertificateThumbprint = $CertificateThumbprint;
        }
    }
}
