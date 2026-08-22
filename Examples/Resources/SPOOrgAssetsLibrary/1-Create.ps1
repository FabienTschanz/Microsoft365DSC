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
        SPOOrgAssetsLibrary 'SPOOrgAssetsLibrary-Example'
        {
            LibraryUrl   = "https://contoso.sharepoint.com/sites/org/Branding"
            ThumbnailUrl = "https://contoso.sharepoint.com/sites/org/Branding/Logo/Owagroup.png"
            CdnType      = "Public"
            Ensure       = "Present"
            Credential   = $Credscredential
        }
    }
}
