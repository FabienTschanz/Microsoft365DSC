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
        SCDLPCompliancePolicy 'SCDLPCompliancePolicy-Example'
        {
            Name               = "MyPolicy"
            Comment            = "Blocks sharing of credit card numbers"
            Priority           = 1
            SharePointLocation = "https://contoso.sharepoint.com/sites/finance"
            Ensure             = "Present"
            Credential         = $Credscredential
        }
    }
}
