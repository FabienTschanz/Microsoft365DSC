<#
This example adds a new Teams Messaging Policy.
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
        TeamsMessagingPolicy 'TeamsMessagingPolicy-Example'
        {
            Identity                = "CorporateMessaging"
            Description             = "Messaging defaults for corporate staff"
            ReadReceiptsEnabledType = "UserPreference"
            AllowImmersiveReader    = $True
            AllowGiphy              = $True
            AllowStickers           = $True
            AllowUrlPreviews        = $false
            AllowUserChat           = $True
            AllowUserDeleteMessage  = $false
            AllowUserEditMessage    = $false
            AllowUserTranslation    = $True
            AllowRemoveUser         = $false
            AllowPriorityMessages   = $True
            GiphyRatingType         = "MODERATE"
            AllowMemes              = $False
            AudioMessageEnabledType = "ChatsOnly"
            AllowOwnerDeleteMessage = $False
            Ensure                  = "Present"
            Credential              = $Credscredential
        }
    }
}
