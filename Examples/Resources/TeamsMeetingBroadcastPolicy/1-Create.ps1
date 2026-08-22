<#
This examples create a new Teams Meeting Broadcast Policy.
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
        TeamsMeetingBroadcastPolicy 'TeamsMeetingBroadcastPolicy-Example'
        {
            Identity                        = "MyDemoPolicy"
            AllowBroadcastScheduling        = $True
            AllowBroadcastTranscription     = $False
            BroadcastAttendeeVisibilityMode = "EveryoneInCompany"
            BroadcastRecordingMode          = "AlwaysEnabled"
            Ensure                          = "Present"
            Credential                      = $Credscredential
        }
    }
}
