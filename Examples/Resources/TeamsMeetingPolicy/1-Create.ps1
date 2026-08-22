<#
This example adds a new Teams Meeting Policy.
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
        TeamsMeetingPolicy 'TeamsMeetingPolicy-Example'
        {
            Identity                                   = "Corporate Meeting Policy"
            AllowAnonymousUsersToStartMeeting          = $False
            AllowChannelMeetingScheduling              = $True
            AllowCloudRecording                        = $True
            AllowExternalParticipantGiveRequestControl = $False
            AllowIPVideo                               = $True
            AllowMeetNow                               = $True
            AllowOutlookAddIn                          = $True
            AllowParticipantGiveRequestControl         = $True
            AllowPowerPointSharing                     = $True
            AllowPrivateMeetingScheduling              = $True
            AllowSharedNotes                           = $True
            AllowTranscription                         = $False
            AllowWhiteboard                            = $True
            AutoAdmittedUsers                          = "Everyone"
            Description                                = "Meeting defaults for corporate staff"
            MediaBitRateKb                             = 50000
            ScreenSharingMode                          = "EntireScreen"
            Ensure                                     = "Present"
            Credential                                 = $Credscredential
        }
    }
}
