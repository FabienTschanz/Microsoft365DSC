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
        SentinelAlertRule "SentinelAlertRule-Example"
        {
            ApplicationId         = $ApplicationId;
            CertificateThumbprint = $CertificateThumbprint;
            Description           = "Raises an incident when a cloud application is accessed from an unrecognised location";
            DisplayName           = "MyNRTRule";
            Ensure                = "Absent";
            ResourceGroupName     = "ResourceGroupName";
            Severity              = "Medium";
            SubscriptionId        = "<subscription-id>";
            TenantId              = $TenantId;
            WorkspaceName         = "SentinelWorkspace";
        }
    }
}
