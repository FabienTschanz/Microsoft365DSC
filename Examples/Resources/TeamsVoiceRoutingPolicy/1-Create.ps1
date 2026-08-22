<#
This example adds a new Teams Voice Routing Policy.
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
        TeamsVoiceRoutingPolicy 'TeamsVoiceRoutingPolicy-Example'
        {
            Identity         = 'NewVoiceRoutingPolicy'
            OnlinePstnUsages = @('Long Distance', 'Local', 'Internal')
            Description      = 'Grants long distance and local calling to corporate users'
            Ensure           = 'Present'
            Credential       = $Credscredential
        }
    }
}
