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
        SCSensitivityLabel 'SCSensitivityLabel-Example'
        {
            Name                                           = 'Confidential'
            Comment                                        = 'Applied to internal business documents'
            ToolTip                                        = 'Use for information that must stay inside the company'
            DisplayName                                    = 'Confidential'
            ApplyContentMarkingFooterAlignment             = 'Center'
            ApplyContentMarkingFooterEnabled               = $true
            ApplyContentMarkingFooterFontColor             = '#FF0000'
            ApplyContentMarkingFooterFontSize              = 10
            ApplyContentMarkingFooterMargin                = 5
            ApplyContentMarkingFooterText                  = 'Contoso Confidential'
            ApplyContentMarkingHeaderAlignment             = 'Center'
            ApplyContentMarkingHeaderEnabled               = $true
            ApplyContentMarkingHeaderFontColor             = '#FF0000'
            ApplyContentMarkingHeaderFontSize              = 10
            ApplyContentMarkingHeaderMargin                = 5
            ApplyContentMarkingHeaderText                  = 'Confidential - Do Not Distribute'
            ApplyWaterMarkingEnabled                       = $true
            ApplyWaterMarkingFontColor                     = '#FF0000'
            ApplyWaterMarkingFontSize                      = 10
            ApplyWaterMarkingLayout                        = 'Diagonal'
            ApplyWaterMarkingText                          = 'Confidential'
            SiteAndGroupProtectionAllowAccessToGuestUsers  = $true
            SiteAndGroupProtectionAllowEmailFromGuestUsers = $true
            SiteAndGroupProtectionAllowFullAccess          = $true
            SiteAndGroupProtectionAllowLimitedAccess       = $true
            SiteAndGroupProtectionBlockAccess              = $true
            SiteAndGroupProtectionEnabled                  = $true
            SiteAndGroupProtectionPrivacy                  = 'Private'
            LocaleSettings                                 = @(
                MSFT_SCLabelLocaleSettings
                {
                    LocaleKey     = 'DisplayName'
                    LabelSettings = @(
                        MSFT_SCLabelSetting
                        {
                            Key   = 'en-us'
                            Value = 'English Display Names'
                        }
                        MSFT_SCLabelSetting
                        {
                            Key   = 'fr-fr'
                            Value = "Nom da'ffichage francais"
                        }
                    )
                }
                MSFT_SCLabelLocaleSettings
                {
                    LocaleKey     = 'StopColor'
                    LabelSettings = @(
                        MSFT_SCLabelSetting
                        {
                            Key   = 'en-us'
                            Value = 'RedGreen'
                        }
                        MSFT_SCLabelSetting
                        {
                            Key   = 'fr-fr'
                            Value = 'Rouge'
                        }
                    )
                }
            )
            AdvancedSettings                               = @(
                MSFT_SCLabelSetting
                {
                    Key   = 'AllowedLevel'
                    Value = @('Sensitive', 'Classified')
                }
                MSFT_SCLabelSetting
                {
                    Key   = 'LabelStatus'
                    Value = 'Enabled'
                }
            )
            AutoLabelingSettings                           = MSFT_SCSLAutoLabelingSettings
            {
                Operator      = 'And'
                AutoApplyType = 'Recommend'
                PolicyTip     = 'This document contains financial data and will be labelled Confidential.'
                Groups        = @(
                    MSFT_SCSLSensitiveInformationGroup
                    {
                        Name                     = 'Group1'
                        Operator                 = 'Or'
                        SensitiveInformationType = @(
                            MSFT_SCSLSensitiveInformationType
                            {
                                name            = 'ABA Routing Number'
                                confidencelevel = 'High'
                                maxcount        = -1
                                mincount        = 1
                            }
                        )
                        TrainableClassifier      = @(
                            MSFT_SCSLTrainableClassifiers
                            {
                                name = 'Legal Affairs'
                            }
                        )
                    }
                    MSFT_SCSLSensitiveInformationGroup
                    {
                        Name                     = 'Group2'
                        Operator                 = 'And'
                        SensitiveInformationType = @(
                            MSFT_SCSLSensitiveInformationType
                            {
                                name            = 'All Full Names'
                                confidencelevel = 'High'
                                maxcount        = 100
                                mincount        = 10
                            }
                        )
                        TrainableClassifier      = @(
                            MSFT_SCSLTrainableClassifiers
                            {
                                name = 'Threat'
                            }
                        )
                    }
                )
            }
            ParentId                                       = 'Personal'
            Ensure                                         = 'Present'
            Credential                                     = $Credscredential
        }
    }
}
