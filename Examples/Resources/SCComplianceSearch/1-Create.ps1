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
            Language                              = "iv"
            AllowNotFoundExchangeLocationsEnabled = $False
            SharePointLocation                    = @("All")
            Credential                            = $Credscredential
            Ensure                                = "Present"
        }
    }
}
