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
        SCComplianceSearch 'SCComplianceSearch-Example'
        {
            Case                                  = "Contoso Litigation 2026"
            HoldNames                             = @()
            Name                                  = "Budget Mailbox Search"
            Language                              = "en-US"
            AllowNotFoundExchangeLocationsEnabled = $False
            ContentMatchQuery                     = "(subject:Budget) AND (sent>=2026-01-01)"
            Description                           = "Locates mail and documents related to the annual budget review"
            ExchangeLocation                      = @("All")
            ExchangeLocationExclusion             = @("servicedesk@contoso.com")
            IncludeUserAppContent                 = $False
            PublicFolderLocation                  = @("All")
            SharePointLocation                    = @("All")
            SharePointLocationExclusion           = @("https://contoso.sharepoint.com/sites/PublicRelations")
            Credential                            = $Credscredential
            Ensure                                = "Present"
        }
    }
}
