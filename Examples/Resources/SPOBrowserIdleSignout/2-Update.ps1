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
        SPOBrowserIdleSignout 'SPOBrowserIdleSignout-Example'
        {
            IsSingleInstance = "Yes"
            Enabled          = $True
            SignOutAfter     = "04:00:00"
            WarnAfter        = "03:30:00"
            Credential       = $Credscredential
        }
    }
}
