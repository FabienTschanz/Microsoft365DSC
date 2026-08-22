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
        SCUnifiedAuditLogRetentionPolicy 'SCUnifiedAuditLogRetentionPolicy-Example'
        {
            Credential            = $Credentials
            Ensure                = 'Present'
            Name                  = 'Seven Day Audit Retention'
            Priority              = 1
            RetentionDuration     = 'SevenDays'
            ApplicationId         = $ApplicationId
            TenantId              = $TenantId
            CertificateThumbprint = $CertificateThumbprint
        }
    }
}
