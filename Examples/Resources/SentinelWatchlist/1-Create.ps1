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
        SentinelWatchlist "SentinelWatchlist-Example"
        {
            Alias                 = "MyAlias";
            ApplicationId         = $ApplicationId;
            CertificateThumbprint = $CertificateThumbprint;
            DefaultDuration       = "P1DT3H";
            Description           = "My description";
            DisplayName           = "My Display Name";
            Ensure                = "Present";
            ItemsSearchKey        = "IPAddress";
            Name                  = "MyWatchList";
            NumberOfLinesToSkip   = 1;
            RawContent            = 'MyContent'
            ResourceGroupName     = "MyResourceGroup";
            SourceType            = "Local";
            SubscriptionId        = "<subscription-id>";
            TenantId              = $TenantId;
            WorkspaceName         = "MyWorkspace";
        }
    }
}
