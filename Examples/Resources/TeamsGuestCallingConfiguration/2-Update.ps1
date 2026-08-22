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
        TeamsGuestCallingConfiguration 'ConfigureGuestCalling'
        {
            IsSingleInstance    = 'Yes';
            AllowPrivateCalling = $True
            Credential          = $Credscredential
        }
    }
}
