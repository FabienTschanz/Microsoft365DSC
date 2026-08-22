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
        SCCaseHoldRule 'SCCaseHoldRule-Example'
        {
            Name              = "My Rule"
            Policy            = "My Policy"
            Comment           = "Limits the hold to budget spreadsheets"
            Disabled          = $false
            ContentMatchQuery = "filename:2016 budget filetype:xlsx"
            Ensure            = "Present"
            Credential        = $Credscredential
        }
    }
}
