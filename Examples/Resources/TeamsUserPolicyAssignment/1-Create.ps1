<#
This examples configure a TeamsUserPolicyAssignment.
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
        TeamsUserPolicyAssignment 'TeamsUserPolicyAssignment-Example'
        {
            Credential                      = $Credential
            CallingLineIdentity             = "CorporateCallerID";
            ExternalAccessPolicy            = "CorporateFederation";
            OnlineVoicemailPolicy           = "CorporateVoicemail";
            OnlineVoiceRoutingPolicy        = "NewVoiceRoutingPolicy";
            TeamsAppPermissionPolicy        = "SalesAppPermissions";
            TeamsAppSetupPolicy             = "Frontline App Setup";
            TeamsAudioConferencingPolicy    = "CorporateAudioConferencing";
            TeamsCallHoldPolicy             = "CorporateCallHold";
            TeamsCallingPolicy              = "AllowCalling";
            TeamsCallParkPolicy             = "CorporateCallPark";
            TeamsChannelsPolicy             = "New Channels Policy";
            TeamsEmergencyCallingPolicy     = "Headquarters Emergency Calling Policy";
            TeamsEmergencyCallRoutingPolicy = "Amsterdam Office";
            TeamsEnhancedEncryptionPolicy   = "CorporateEncryption";
            TeamsEventsPolicy               = "CorporateEvents";
            TeamsMeetingBroadcastPolicy     = "CorporateBroadcast";
            TeamsMeetingPolicy              = "Corporate Meeting Policy";
            TeamsMessagingPolicy            = "CorporateMessaging";
            TeamsMobilityPolicy             = "CorporateMobility";
            TeamsUpdateManagementPolicy     = "EarlyAdopters";
            TeamsUpgradePolicy              = "UpgradeToTeams";
            TenantDialPlan                  = "AmsterdamPlan";
            User                            = "john.smith@contoso.com";
        }
    }
}
