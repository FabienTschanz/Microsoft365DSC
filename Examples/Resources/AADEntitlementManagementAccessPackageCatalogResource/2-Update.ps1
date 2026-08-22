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
        AADEntitlementManagementAccessPackageCatalogResource 'myAccessPackageCatalogResource'
        {
            ApplicationId         = $ApplicationId;
            CatalogId             = "My Catalog";
            CertificateThumbprint = $CertificateThumbprint;
            DisplayName           = "MyGroup";
            OriginSystem          = "AADGroup";
            OriginId              = '849b3661-61a8-44a8-92e7-fcc91d296235'
            AddedBy               = "admin@$TenantId";
            AddedOn               = "2026-01-01T00:00:00.0000000Z";
            Description           = "Microsoft DSC Group";
            ResourceType          = "O365 Group";
            Url                   = "https://portal.azure.com/Microsoft_AAD_IAM/GroupDetailsMenuBlade/Overview/groupId/849b3661-61a8-44a8-92e7-fcc91d296235";
            Ensure                = "Present";
            IsPendingOnboarding   = $False;
            TenantId              = $TenantId;
        }
    }
}
