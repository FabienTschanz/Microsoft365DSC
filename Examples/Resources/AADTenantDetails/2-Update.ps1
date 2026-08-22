<#
This example is used to test new resources and showcase the usage of new resources being worked on.
It is not meant to use as a production baseline.
#>

Configuration Example {
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

    Node Localhost
    {
        AADTenantDetails 'AADTenantDetails-Example'
        {
            IsSingleInstance                     = 'Yes'
            TechnicalNotificationMails           = "it-operations@contoso.com"
            MarketingNotificationEmails          = "marketing@contoso.com"
            SecurityComplianceNotificationMails  = @("security@contoso.com", "compliance@contoso.com")
            SecurityComplianceNotificationPhones = @("+1 425 555 0101")
            ApplicationId                        = $ApplicationId
            TenantId                             = $TenantId
            CertificateThumbprint                = $CertificateThumbprint
        }
    }
}
