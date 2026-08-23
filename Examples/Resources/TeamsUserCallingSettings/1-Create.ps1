<#
This example adds a new Teams Channels Policy.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $credsCredential
    )

    Import-DscResource -ModuleName Microsoft365DSC

    Node localhost
    {
        TeamsUserCallingSettings 'TeamsUserCallingSettings-Example'
        {
            CallGroupOrder            = "Simultaneous";
            CallGroupTargets          = @("megan.bowen@contoso.com", "alex.wilber@contoso.com");
            Credential                = $credsCredential;
            Ensure                    = "Present";
            ForwardingTarget          = "alex.wilber@contoso.com";
            ForwardingTargetType      = "SingleTarget";
            ForwardingType            = "Simultaneous";
            GroupNotificationOverride = "Ring";
            Identity                  = "John.Smith@contoso.com";
            IsForwardingEnabled       = $true;
            IsUnansweredEnabled       = $true;
            UnansweredDelay           = "00:00:20";
            UnansweredTarget          = "megan.bowen@contoso.com";
            UnansweredTargetType      = "SingleTarget";
        }
    }
}
