<#
This example is used to test new resources and showcase the usage of new resources being worked on.
It is not meant to use as a production baseline.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $Credscredential
    )

    Import-DscResource -ModuleName Microsoft365DSC

    Node localhost
    {
        TeamsAppPermissionPolicy "TeamsAppPermissionPolicy-Example"
        {
            Credential             = $Credscredential;
            DefaultCatalogApps     = "com.microsoft.teamspace.tab.web"; # Updated Property
            DefaultCatalogAppsType = "AllowedAppList";
            Description            = "Restricts apps for the sales department";
            Ensure                 = "Present";
            GlobalCatalogAppsType  = "BlockedAppList";
            Identity               = "SalesAppPermissions";
            PrivateCatalogAppsType = "BlockedAppList";
        }
    }
}
