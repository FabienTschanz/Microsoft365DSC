<#
This example demonstrates how to assign users to a Teams Upgrade Policy.
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
        TeamsUpgradePolicy 'TeamsUpgradePolicy-Example'
        {
            Identity               = 'Islands'
            Users                  = @("adele.vance@contoso.com")
            MigrateMeetingsToTeams = $false
            Credential             = $Credscredential
        }
    }
}
