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
        TeamsNetworkRoamingPolicy 'TeamsNetworkRoamingPolicy-Example'
        {
            AllowIPVideo   = $true;
            Credential     = $Credscredential;
            Ensure         = "Present";
            Description    = "Video and media limits for staff roaming outside the office";
            Identity       = "Amsterdam Roaming";
            MediaBitRateKb = 50000;
        }
    }
}
