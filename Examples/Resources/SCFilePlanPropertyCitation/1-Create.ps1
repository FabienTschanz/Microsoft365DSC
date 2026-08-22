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
        SCFilePlanPropertyCitation 'SCFilePlanPropertyCitation-Example'
        {
            Name                 = "Sarbanes-Oxley Act"
            CitationURL          = "https://contoso.com"
            CitationJurisdiction = "Federal"
            Ensure               = "Present"
            Credential           = $Credscredential
        }
    }
}
