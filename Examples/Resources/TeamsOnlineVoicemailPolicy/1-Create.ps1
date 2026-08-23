<#
This example adds a new Teams Meeting Policy.
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
        TeamsOnlineVoicemailPolicy 'TeamsOnlineVoicemailPolicy-Example'
        {
            Credential                          = $credsCredential;
            EnableEditingCallAnswerRulesSetting = $true;
            EnableTranscription                 = $true;
            EnableTranscriptionProfanityMasking = $false;
            EnableTranscriptionTranslation      = $true;
            Ensure                              = "Present";
            Identity                            = "CorporateVoicemail";
            MaximumRecordingLength              = 600;
            PreamblePostambleMandatory          = $false;
            PrimarySystemPromptLanguage         = "en-US";
            SecondarySystemPromptLanguage       = "fr-FR";
            ShareData                           = "Defer";
        }
    }
}
