<#
This example adds a new Teams Events Policy.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $credsTeamsAdmin
    )

    Import-DscResource -ModuleName Microsoft365DSC

    Node localhost
    {
        TeamsEventsPolicy 'TeamsEventsPolicy-Example'
        {
            Identity                                = "CorporateEvents"
            Description                             = "Lets the marketing team run town halls and webinars"
            AllowEmailEditing                       = "Enabled"
            AllowEventIntegrations                  = $true
            AllowWebinars                           = "Enabled"
            AllowTownhalls                          = "Enabled"
            AllowedQuestionTypesInRegistrationForm  = "AllQuestions"
            AllowedTownhallTypesForRecordingPublish = "EveryoneInCompanyIncludingGuests"
            AllowedWebinarTypesForRecordingPublish  = "EveryoneInCompanyIncludingGuests"
            BackroomChat                            = "Enabled"
            BroadcastPremiumApps                    = "Enabled"
            ExternalPresenterJoinVerification       = "eOTP"
            ImmersiveEvents                         = "Enabled"
            RecordingForTownhall                    = "Enabled"
            RecordingForWebinar                     = "Enabled"
            Registration                            = "Enabled"
            TownhallChatExperience                  = "Optimized"
            TownhallEventAttendeeAccess             = "EveryoneInOrganizationAndGuests"
            TownhallMaxResolution                   = "Max1080p"
            TranscriptionForTownhall                = "Enabled"
            TranscriptionForWebinar                 = "Enabled"
            UseMicrosoftECDN                        = $true
            EventAccessType                         = "EveryoneInCompanyExcludingGuests"
            Ensure                                  = "Present"
            Credential                              = $credsTeamsAdmin
        }
    }
}
