<#
This example is used to test new resources and showcase the usage of new resources being worked on.
It is not meant to use as a production baseline.
#>

Configuration Example
{
    param(
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

    node localhost
    {
        AADGroupLifecyclePolicy 'GroupLifecyclePolicy'
        {
            IsSingleInstance            = "Yes"
            AlternateNotificationEmails = @("john.smith@$TenantId")
            GroupLifetimeInDays         = 99
            ManagedGroupTypes           = "Selected"
            Ensure                      = "Present"
            ApplicationId         = $ApplicationId
            TenantId              = $TenantId
            CertificateThumbprint = $CertificateThumbprint
        }
    }
}
