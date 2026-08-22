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
        SCRetentionComplianceRule 'SCRetentionComplianceRule-Example'
        {
            Name                      = "Keep Finance Content"
            Policy                    = "ContosoPolicy"
            Comment                   = "Keeps content in the finance site indefinitely"
            RetentionComplianceAction = "Keep"
            RetentionDuration         = "Unlimited"
            Ensure                    = "Present"
            Credential                = $Credscredential
        }
    }
}
