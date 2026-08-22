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
        AADFilteringPolicyRule "AADFilteringPolicyRule-Example1"
        {
            ApplicationId         = $ApplicationId;
            CertificateThumbprint = $CertificateThumbprint;
            Ensure                = "Absent";
            Name                  = "MyFQDN";
            Policy                = "MyPolicy";
            TenantId              = $TenantId;
        }
        AADFilteringPolicyRule "AADFilteringPolicyRule-Example2"
        {
            ApplicationId         = $ApplicationId;
            CertificateThumbprint = $CertificateThumbprint;
            Destinations          = @(
                MSFT_AADFilteringPolicyRuleDestination{
                    name = 'ChildAbuseImages'
                }
            );
            Ensure                = "Absent";
            Name                  = "MyWebContentRule";
            Policy                = "MyPolicy";
            RuleType              = "webCategory";
            TenantId              = $TenantId;
        }
    }
}
