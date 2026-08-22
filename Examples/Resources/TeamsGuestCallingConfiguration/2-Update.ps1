<#
This example configures the Teams Guest Calling Configuration.
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
        TeamsGuestCallingConfiguration 'TeamsGuestCallingConfiguration-Example'
        {
            IsSingleInstance    = 'Yes';
            AllowPrivateCalling = $True
            Credential          = $Credscredential
        }
    }
}
