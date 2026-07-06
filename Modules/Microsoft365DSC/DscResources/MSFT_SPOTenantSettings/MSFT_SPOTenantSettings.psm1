Confirm-M365DSCModuleDependency -ModuleName 'MSFT_SPOTenantSettings'
$script:CurrentResource = ($PSCommandPath | Split-Path -Leaf).Replace('MSFT_', '').Replace('.psm1', '')

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.Boolean]
        $EnableAzureADB2BIntegration,

        [Parameter()]
        [System.UInt32]
        $MinCompatibilityLevel,

        [Parameter()]
        [System.UInt32]
        $MaxCompatibilityLevel,

        [Parameter()]
        [System.Boolean]
        $SearchResolveExactEmailOrUPN,

        [Parameter()]
        [System.Boolean]
        $OfficeClientADALDisabled,

        [Parameter()]
        [System.Boolean]
        $OneDriveRequestFilesLinkEnabled,

        [Parameter()]
        [ValidateRange(0, 730)]
        [System.Int32]
        $OneDriveRequestFilesLinkExpirationInDays,

        [Parameter()]
        [System.Boolean]
        $LegacyAuthProtocolsEnabled,

        [Parameter()]
        [System.String]
        $SignInAccelerationDomain,

        [Parameter()]
        [System.Boolean]
        $UsePersistentCookiesForExplorerView,

        [Parameter()]
        [System.Boolean]
        $PublicCdnEnabled,

        [Parameter()]
        [System.String]
        $PublicCdnAllowedFileTypes,

        [Parameter()]
        [System.Boolean]
        $UseFindPeopleInPeoplePicker,

        [Parameter()]
        [System.Boolean]
        $NotificationsInSharePointEnabled,

        [Parameter()]
        [System.Boolean]
        $OwnerAnonymousNotification,

        [Parameter()]
        [System.Boolean]
        $AllowCommentsTextOnEmailEnabled,

        [Parameter()]
        [System.Boolean]
        $AllowWebPropertyBagUpdateWhenDenyAddAndCustomizePagesIsEnabled,

        [Parameter()]
        [System.Boolean]
        $ApplyAppEnforcedRestrictionsToAdHocRecipients,

        [Parameter()]
        [System.String]
        $ArchiveRedirectUrl,

        [Parameter()]
        [System.Boolean]
        $BlockSendLabelMismatchEmail,

        [Parameter()]
        [System.Boolean]
        $CoreRequestFilesLinkEnabled,

        [Parameter()]
        [ValidateRange(0, 730)]
        [System.Int32]
        $CoreRequestFilesLinkExpirationInDays,

        [Parameter()]
        [System.Boolean]
        $FilePickerExternalImageSearchEnabled,

        [Parameter()]
        [System.Boolean]
        $HideDefaultThemes,

        [Parameter()]
        [System.Boolean]
        $HideSyncButtonOnODB,

        [Parameter()]
        [System.Boolean]
        $HideSyncButtonOnTeamSite,

        [Parameter()]
        [System.Boolean]
        $LegacyBrowserAuthProtocolsEnabled,

        [Parameter()]
        [System.Boolean]
        $EnableDiscoverableByOrganizationForVideos,

        [Parameter()]
        [System.String]
        $RestrictedAccessControlforSitesErrorHelpLink,

        [Parameter()]
        [System.Boolean]
        $Workflow2010Disabled,

        [Parameter()]
        [System.Boolean]
        $HideSyncButtonOnDocLib,

        [Parameter()]
        [System.Int32]
        $StreamLaunchConfig,

        [Parameter()]
        [System.Boolean]
        $EnableMediaReactions,

        [Parameter()]
        [System.Boolean]
        $ContentSecurityPolicyEnforcement,

        [Parameter()]
        [System.Boolean]
        $DisableSpacesActivation,

        [Parameter()]
        [System.Boolean]
        $AllowAppsBypassOfUnmanagedDevicePolicy,

        [Parameter()]
        [System.String[]]
        $DisabledAdaptiveCardExtensionIds,

        [Parameter()]
        [System.Boolean]
        $EnableNotificationsSubscriptions,

        [Parameter()]
        [System.Boolean]
        $EnforceRequestDigest,

        [Parameter()]
        [ValidateSet('Audit', 'None', 'PassiveEnforcement', 'StrictEnforcement')]
        [System.String]
        $TlsTokenBindingPolicyValue,

        [Parameter()]
        [ValidateSet('DefaultAAD', 'Disabled', 'Enabled')]
        [System.String]
        $AuthContextResilienceMode,

        [Parameter()]
        [System.String]
        $AllOrganizationSecurityGroupId,

        [Parameter()]
        [System.Boolean]
        $AllowFileArchive,

        [Parameter()]
        [System.Boolean]
        $AllowFileArchiveOnNewSitesByDefault,

        [Parameter()]
        [System.String[]]
        $ContentTypeSyncSiteTemplatesList,

        [Parameter()]
        [System.Boolean]
        $DisableDocumentLibraryDefaultLabeling,

        [Parameter()]
        [System.Boolean]
        $IsEnableAppAuthPopUpEnabled,

        [Parameter()]
        [System.Int32]
        $ExpireVersionsAfterDays,

        [Parameter()]
        [System.Int32]
        $MajorVersionLimit,

        [Parameter()]
        [System.Boolean]
        $EnableAutoExpirationVersionTrim,

        [Parameter()]
        [System.Boolean]
        $DisableVivaConnectionsAnalytics,

        [Parameter()]
        [ValidateSet('Unspecified', 'On', 'Off')]
        [System.String]
        $CoreBlockGuestsAsSiteAdmin,

        [Parameter()]
        [System.Boolean]
        $IsWBFluidEnabled,

        [Parameter()]
        [System.Boolean]
        $IsCollabMeetingNotesFluidEnabled,

        [Parameter()]
        [ValidateSet('Unspecified', 'On', 'Off')]
        [System.String]
        $AllowAnonymousMeetingParticipantsToAccessWhiteboards,

        [Parameter()]
        [System.Boolean]
        $IBImplicitGroupBased,

        [Parameter()]
        [System.Boolean]
        $ShowOpenInDesktopOptionForSyncedFiles,

        [Parameter()]
        [System.Boolean]
        $ShowPeoplePickerGroupSuggestionsForIB,

        [Parameter()]
        [System.Boolean]
        $ReduceTempTokenLifetimeEnabled,

        [Parameter()]
        [System.Int32]
        $ReduceTempTokenLifetimeValue,

        [Parameter()]
        [System.Boolean]
        $ViewersCanCommentOnMediaDisabled,

        [Parameter()]
        [System.String]
        $ConditionalAccessPolicyErrorHelpLink,

        [Parameter()]
        [System.String]
        $CustomizedExternalSharingServiceUrl,

        [Parameter()]
        [System.Boolean]
        $IncludeAtAGlanceInShareEmails,

        [Parameter()]
        [System.Boolean]
        $MassDeleteNotificationDisabled,

        [Parameter()]
        [System.Boolean]
        $IsDataAccessInCardDesignerEnabled,

        [Parameter()]
        [ValidateSet('AllowExternalSharing', 'BlockExternalSharing')]
        [System.String]
        $MarkNewFilesSensitiveByDefault,

        [Parameter()]
        [ValidateSet('Disabled', 'Enabled')]
        [System.String]
        $MediaTranscription,

        [Parameter()]
        [ValidateSet('Disabled', 'Enabled')]
        [System.String]
        $MediaTranscriptionAutomaticFeatures,

        [Parameter()]
        [System.Guid[]]
        $DisabledWebPartIds,

        [Parameter()]
        [System.Boolean]
        $IsFluidEnabled,

        [Parameter()]
        [System.Boolean]
        $SocialBarOnSitePagesDisabled,

        [Parameter()]
        [System.Boolean]
        $CommentsOnSitePagesDisabled,

        [Parameter()]
        [System.Boolean]
        $EnableAIPIntegration,

        [Parameter()]
        [System.Boolean]
        $EnableSensitivityLabelForPDF,

        [Parameter()]
        [System.Boolean]
        $SiteOwnerManageLegacyServicePrincipalEnabled,

        [Parameter()]
        [System.String]
        $TenantDefaultTimezone,

        [Parameter()]
        [System.Boolean]
        $ExemptNativeUsersFromTenantLevelRestricedAccessControl,

        [Parameter()]
        [System.String[]]
        $AllowSelectSGsInODBListInTenant,

        [Parameter()]
        [System.String[]]
        $DenySelectSGsInODBListInTenant,

        [Parameter()]
        [System.String[]]
        $DenySelectSecurityGroupsInSPSitesList,

        [Parameter()]
        [System.String[]]
        $AllowSelectSecurityGroupsInSPSitesList,

        [Parameter()]
        [System.Boolean]
        $MobileFriendlyUrlEnabledInTenant,

        [Parameter()]
        [System.Boolean]
        $AllowDownloadingNonWebViewableFiles,

        [Parameter()]
        [System.Boolean]
        $AllowEditing,

        [Parameter()]
        [System.Boolean]
        $AppBypassInformationBarriers,

        [Parameter()]
        [ValidateSet('TeamsMeetingRecording')]
        [System.String[]]
        $BlockDownloadFileTypeIds,

        [Parameter()]
        [System.Boolean]
        $BlockDownloadFileTypePolicy,

        [Parameter()]
        [ValidateSet('Open', 'Explicit', 'Implicit', 'OwnerModerated', 'Mixed')]
        [System.String]
        $DefaultOneDriveInformationBarrierMode,

        [Parameter()]
        [System.Boolean]
        $DisableCustomAppAuthentication,

        [Parameter()]
        [System.String[]]
        $DisabledModernListTemplateIds,

        [Parameter()]
        [System.Boolean]
        $DisablePersonalListCreation,

        [Parameter()]
        [System.Boolean]
        $DisplayNamesOfFileViewersInSpo,

        [Parameter()]
        [System.String[]]
        $ExcludedBlockDownloadGroupIds,

        [Parameter()]
        [System.Boolean]
        $IsLoopEnabled,

        [Parameter()]
        [System.Boolean]
        $IsSharePointAddInsDisabled,

        [Parameter()]
        [System.Boolean]
        $IsSharePointNewsfeedEnabled,

        [Parameter()]
        [System.Boolean]
        $IsSiteCreationEnabled,

        [Parameter()]
        [System.Boolean]
        $IsSiteCreationUiEnabled,

        [Parameter()]
        [System.Boolean]
        $IsSitePagesCreationEnabled,

        [Parameter()]
        [System.Boolean]
        $KnowledgeAgentEnabled,

        [Parameter()]
        [System.Boolean]
        $KnowledgeAgentSelectedSitesList,

        [Parameter()]
        [System.String]
        $NoAccessRedirectUrl,

        [Parameter()]
        [ValidateSet('On', 'Off', 'Unspecified')]
        [System.String]
        $OneDriveBlockGuestsAsSiteAdmin,

        [Parameter()]
        [ValidateRange(14, 93)]
        [System.Int32]
        $RecycleBinRetentionPeriod,

        [Parameter()]
        [System.Boolean]
        $RequireAcceptingAccountMatchInvitedAccount,

        [Parameter()]
        [ValidateSet('NoPreference', 'Allowed', 'Disallowed')]
        [System.String]
        $SpecialCharactersStateInFileFolderNames,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    if ($PSEdition -ne 'Core')
    {
        Invoke-PowerShellCoreResource -Path $PSCommandPath -FunctionName $MyInvocation.MyCommand.Name -Parameters $PSBoundParameters
        return
    }

    Write-Verbose -Message 'Getting configuration for SPO Tenant'

    try
    {
        if (-not $Script:ExportMode)
        {
            $null = New-M365DSCConnection -Workload 'MicrosoftGraph' `
                -InboundParameters $PSBoundParameters

            $null = New-M365DSCConnection -Workload 'PNP' `
                -InboundParameters $PSBoundParameters

            #Ensure the proper dependencies are installed in the current environment.
            Confirm-M365DSCDependencies

            #region Telemetry
            $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
            $CommandName = $MyInvocation.MyCommand
            $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
                -CommandName $CommandName `
                -Parameters $PSBoundParameters
            Add-M365DSCTelemetryEvent -Data $data
            #endregion
        }

        $nullReturn = $PSBoundParameters
        $nullReturn.Ensure = 'Absent'

        $SPOTenantSettings = Get-PnPTenant -ErrorAction Stop
        $SPOTenantGraphSettings = Get-MgAdminSharepointSetting -Property *
        $CompatibilityRange = $SPOTenantSettings.CompatibilityRange.Split(',')
        $MinCompat = $null
        $MaxCompat = $null
        if ($CompatibilityRange.Length -eq 2)
        {
            $MinCompat = $CompatibilityRange[0]
            $MaxCompat = $CompatibilityRange[1]
        }

        # Additional Properties via REST
        $parametersToRetrieve = @(
            'ExemptNativeUsersFromTenantLevelRestricedAccessControl',
            'AllowSelectSGsInODBListInTenant',
            'DenySelectSGsInODBListInTenant',
            'DenySelectSecurityGroupsInSPSitesList',
            'AllowSelectSecurityGroupsInSPSitesList',
            'HideSyncButtonOnODB',
            'MobileFriendlyUrlEnabledInTenant'
        )

        $response = Invoke-PnPSPRestMethod -Method Get `
            -Url "$((Get-MSCloudLoginConnectionProfile -Workload PnP).AdminUrl)/_api/SPO.Tenant?`$select=$($parametersToRetrieve -join ',')"

        $AllowSelectSGsInODBListInTenantValue = @()
        if ($null -ne $response.AllowSelectSGsInODBListInTenant)
        {
            $AllowSelectSGsInODBListInTenantValue = [System.String[]]$response.AllowSelectSGsInODBListInTenant
        }

        $DenySelectSGsInODBListInTenantValue = @()
        if ($null -ne $response.DenySelectSGsInODBListInTenant)
        {
            $DenySelectSGsInODBListInTenantValue = [System.String[]]$response.DenySelectSGsInODBListInTenant
        }

        $DenySelectSecurityGroupsInSPSitesListValue = @()
        if ($null -ne $response.DenySelectSecurityGroupsInSPSitesList)
        {
            $DenySelectSecurityGroupsInSPSitesListValue = [System.String[]]$response.DenySelectSecurityGroupsInSPSitesList
        }

        $AllowSelectSecurityGroupsInSPSitesListValue = @()
        if ($null -ne $response.AllowSelectSecurityGroupsInSPSitesList)
        {
            $AllowSelectSecurityGroupsInSPSitesListValue = [System.String[]]$response.AllowSelectSecurityGroupsInSPSitesList
        }

        $results = @{
            IsSingleInstance                                               = 'Yes'
            ExemptNativeUsersFromTenantLevelRestricedAccessControl         = $response.ExemptNativeUsersFromTenantLevelRestricedAccessControl
            AllowSelectSGsInODBListInTenant                                = $AllowSelectSGsInODBListInTenantValue
            DenySelectSGsInODBListInTenant                                 = $DenySelectSGsInODBListInTenantValue
            DenySelectSecurityGroupsInSPSitesList                          = $DenySelectSecurityGroupsInSPSitesListValue
            AllowSelectSecurityGroupsInSPSitesList                         = $AllowSelectSecurityGroupsInSPSitesListValue
            EnableAzureADB2BIntegration                                    = $SPOTenantSettings.EnableAzureADB2BIntegration
            HideSyncButtonOnODB                                            = $response.HideSyncButtonOnODB
            MobileFriendlyUrlEnabledInTenant                               = $response.MobileFriendlyUrlEnabledInTenant
            MinCompatibilityLevel                                          = $MinCompat
            MaxCompatibilityLevel                                          = $MaxCompat
            AllOrganizationSecurityGroupId                                 = $SPOTenantSettings.AllOrganizationSecurityGroupId
            AllowAnonymousMeetingParticipantsToAccessWhiteboards           = $SPOTenantSettings.AllowAnonymousMeetingParticipantsToAccessWhiteboards.ToString()
            AllowAppsBypassOfUnmanagedDevicePolicy                         = $SPOTenantSettings.AllowAppsBypassOfUnmanagedDevicePolicy
            AllowCommentsTextOnEmailEnabled                                = $SPOTenantSettings.AllowCommentsTextOnEmailEnabled
            AllowDownloadingNonWebViewableFiles                            = $SPOTenantSettings.AllowDownloadingNonWebViewableFiles
            AllowEditing                                                   = $SPOTenantSettings.AllowEditing
            AllowFileArchive                                               = $SPOTenantSettings.AllowFileArchive
            AllowFileArchiveOnNewSitesByDefault                            = $SPOTenantSettings.AllowFileArchiveOnNewSitesByDefault
            AppBypassInformationBarriers                                   = $SPOTenantSettings.AppBypassInformationBarriers
            AllowWebPropertyBagUpdateWhenDenyAddAndCustomizePagesIsEnabled = $SPOTenantSettings.AllowWebPropertyBagUpdateWhenDenyAddAndCustomizePagesIsEnabled
            ApplyAppEnforcedRestrictionsToAdHocRecipients                  = $SPOTenantSettings.ApplyAppEnforcedRestrictionsToAdHocRecipients
            ArchiveRedirectUrl                                             = $SPOTenantSettings.ArchiveRedirectUrl
            AuthContextResilienceMode                                      = $SPOTenantSettings.AuthContextResilienceMode.ToString()
            BlockDownloadFileTypeIds                                       = Get-M365DSCArrayFromProperty -PropertyValue $SPOTenantSettings.BlockDownloadFileTypeIds -ElementType ([System.String])
            BlockDownloadFileTypePolicy                                    = $SPOTenantSettings.BlockDownloadFileTypePolicy
            BlockSendLabelMismatchEmail                                    = $SPOTenantSettings.BlockSendLabelMismatchEmail
            CommentsOnSitePagesDisabled                                    = $SPOTenantSettings.CommentsOnSitePagesDisabled
            ConditionalAccessPolicyErrorHelpLink                           = $SPOTenantSettings.ConditionalAccessPolicyErrorHelpLink
            ContentTypeSyncSiteTemplatesList                               = Get-M365DSCArrayFromProperty -PropertyValue $SPOTenantSettings.ContentTypeSyncSiteTemplatesList -ElementType ([System.String])
            CoreRequestFilesLinkExpirationInDays                           = $SPOTenantSettings.CoreRequestFilesLinkExpirationInDays
            CoreRequestFilesLinkEnabled                                    = $SPOTenantSettings.CoreRequestFilesLinkEnabled
            CoreBlockGuestsAsSiteAdmin                                     = $SPOTenantSettings.CoreBlockGuestsAsSiteAdmin.ToString()
            ContentSecurityPolicyEnforcement                               = $SPOTenantSettings.ContentSecurityPolicyEnforcement
            CustomizedExternalSharingServiceUrl                            = $SPOTenantSettings.CustomizedExternalSharingServiceUrl
            DefaultOneDriveInformationBarrierMode                          = $SPOTenantSettings.DefaultOneDriveInformationBarrierMode
            DisableCustomAppAuthentication                                 = $SPOTenantSettings.DisableCustomAppAuthentication
            DisableDocumentLibraryDefaultLabeling                          = $SPOTenantSettings.DisableDocumentLibraryDefaultLabeling
            DisableSpacesActivation                                        = $SPOTenantSettings.DisableSpacesActivation
            DisableVivaConnectionsAnalytics                                = $SPOTenantSettings.DisableVivaConnectionsAnalytics
            DisabledAdaptiveCardExtensionIds                               = Get-M365DSCArrayFromProperty -PropertyValue $SPOTenantSettings.DisabledAdaptiveCardExtensionIds -ElementType ([System.String])
            DisabledModernListTemplateIds                                  = [System.String[]]$SPOTenantSettings.DisabledModernListTemplateIds
            DisabledWebPartIds                                             = [System.String[]]$SPOTenantSettings.DisabledWebPartIds
            DisablePersonalListCreation                                    = $SPOTenantSettings.DisablePersonalListCreation
            DisplayNamesOfFileViewersInSpo                                 = $SPOTenantSettings.DisplayNamesOfFileViewersInSpo
            EnableDiscoverableByOrganizationForVideos                      = $SPOTenantSettings.EnableDiscoverableByOrganizationForVideos
            EnableAIPIntegration                                           = $SPOTenantSettings.EnableAIPIntegration
            EnableMediaReactions                                           = $SPOTenantSettings.EnableMediaReactions
            EnableNotificationsSubscriptions                               = $SPOTenantSettings.EnableNotificationsSubscriptions
            EnableSensitivityLabelForPDF                                   = $SPOTenantSettings.EnableSensitivityLabelForPDF
            EnforceRequestDigest                                           = $SPOTenantSettings.EnforceRequestDigest
            # TODO: Add GroupId lookup
            ExcludedBlockDownloadGroupIds                                  = Get-M365DSCArrayFromProperty -PropertyValue $SPOTenantSettings.ExcludedBlockDownloadGroupIds -ElementType ([System.String])
            FilePickerExternalImageSearchEnabled                           = $SPOTenantSettings.FilePickerExternalImageSearchEnabled
            ExpireVersionsAfterDays                                        = $SPOTenantSettings.ExpireVersionsAfterDays
            HideDefaultThemes                                              = $SPOTenantSettings.HideDefaultThemes
            HideSyncButtonOnDocLib                                         = $SPOTenantSettings.HideSyncButtonOnDocLib
            HideSyncButtonOnTeamSite                                       = $SPOTenantSettings.HideSyncButtonOnTeamSite
            IBImplicitGroupBased                                           = $SPOTenantSettings.IBImplicitGroupBased
            IncludeAtAGlanceInShareEmails                                  = $SPOTenantSettings.IncludeAtAGlanceInShareEmails
            IsCollabMeetingNotesFluidEnabled                               = $SPOTenantSettings.IsCollabMeetingNotesFluidEnabled
            IsDataAccessInCardDesignerEnabled                              = $SPOTenantSettings.IsDataAccessInCardDesignerEnabled
            IsEnableAppAuthPopUpEnabled                                    = $SPOTenantSettings.IsEnableAppAuthPopUpEnabled
            EnableAutoExpirationVersionTrim                                = $SPOTenantSettings.EnableAutoExpirationVersionTrim
            IsFluidEnabled                                                 = $SPOTenantSettings.IsFluidEnabled
            IsLoopEnabled                                                  = $SPOTenantSettings.IsLoopEnabled
            IsSharePointAddInsDisabled                                     = $SPOTenantSettings.IsSharePointAddInsDisabled
            IsWBFluidEnabled                                               = $SPOTenantSettings.IsWBFluidEnabled
            KnowledgeAgentEnabled                                          = $SPOTenantSettings.KnowledgeAgentEnabled
            KnowledgeAgentSelectedSitesList                                = Get-M365DSCArrayFromProperty -PropertyValue $SPOTenantSettings.KnowledgeAgentSelectedSitesList -ElementType ([System.String])
            LegacyBrowserAuthProtocolsEnabled                              = $SPOTenantSettings.LegacyBrowserAuthProtocolsEnabled
            LegacyAuthProtocolsEnabled                                     = $SPOTenantSettings.LegacyAuthProtocolsEnabled
            MajorVersionLimit                                              = $SPOTenantSettings.MajorVersionLimit
            MassDeleteNotificationDisabled                                 = $SPOTenantSettings.MassDeleteNotificationDisabled
            MarkNewFilesSensitiveByDefault                                 = $SPOTenantSettings.MarkNewFilesSensitiveByDefault
            MediaTranscription                                             = $SPOTenantSettings.MediaTranscriptionEnabled
            MediaTranscriptionAutomaticFeatures                            = $SPOTenantSettings.MediaTranscriptionAutomaticFeatures
            NoAccessRedirectUrl                                            = $SPOTenantSettings.NoAccessRedirectUrl
            NotificationsInSharePointEnabled                               = $SPOTenantSettings.NotificationsInSharePointEnabled
            OfficeClientADALDisabled                                       = $SPOTenantSettings.OfficeClientADALDisabled
            OneDriveBlockGuestsAsSiteAdmin                                 = $SPOTenantSettings.OneDriveBlockGuestsAsSiteAdmin
            OneDriveRequestFilesLinkEnabled                                = $SPOTenantSettings.OneDriveRequestFilesLinkEnabled
            OneDriveRequestFilesLinkExpirationInDays                       = $SPOTenantSettings.OneDriveRequestFilesLinkExpirationInDays
            OwnerAnonymousNotification                                     = $SPOTenantSettings.OwnerAnonymousNotification
            #PermissiveBrowserFileHandlingOverride                          = $SPOTenantSettings.PermissiveBrowserFileHandlingOverride
            PublicCdnAllowedFileTypes                                      = $SPOTenantSettings.PublicCdnAllowedFileTypes
            PublicCdnEnabled                                               = $SPOTenantSettings.PublicCdnEnabled
            ReduceTempTokenLifetimeEnabled                                 = $SPOTenantSettings.ReduceTempTokenLifetimeEnabled
            ReduceTempTokenLifetimeValue                                   = $SPOTenantSettings.ReduceTempTokenLifetimeValue
            RecycleBinRetentionPeriod                                      = $SPOTenantSettings.RecycleBinRetentionPeriod
            RestrictedAccessControlforSitesErrorHelpLink                   = $SPOTenantSettings.RestrictedAccessControlforSitesErrorHelpLink
            RequireAcceptingAccountMatchInvitedAccount                     = $SPOTenantSettings.RequireAcceptingAccountMatchInvitedAccount
            SearchResolveExactEmailOrUPN                                   = $SPOTenantSettings.SearchResolveExactEmailOrUPN
            ShowOpenInDesktopOptionForSyncedFiles                          = $SPOTenantSettings.ShowOpenInDesktopOptionForSyncedFiles
            ShowPeoplePickerGroupSuggestionsForIB                          = $SPOTenantSettings.ShowPeoplePickerGroupSuggestionsForIB
            SignInAccelerationDomain                                       = $SPOTenantSettings.SignInAccelerationDomain
            SiteOwnerManageLegacyServicePrincipalEnabled                   = $SPOTenantSettings.SiteOwnerManageLegacyServicePrincipalEnabled
            SocialBarOnSitePagesDisabled                                   = $SPOTenantSettings.SocialBarOnSitePagesDisabled
            SpecialCharactersStateInFileFolderNames                        = $SPOTenantSettings.SpecialCharactersStateInFileFolderNames
            StreamLaunchConfig                                             = $SPOTenantSettings.StreamLaunchConfig
            TlsTokenBindingPolicyValue                                     = $SPOTenantSettings.TlsTokenBindingPolicyValue.ToString()
            UseFindPeopleInPeoplePicker                                    = $SPOTenantSettings.UseFindPeopleInPeoplePicker
            UsePersistentCookiesForExplorerView                            = $SPOTenantSettings.UsePersistentCookiesForExplorerView
            ViewersCanCommentOnMediaDisabled                               = $SPOTenantSettings.ViewersCanCommentOnMediaDisabled
            Workflow2010Disabled                                           = $SPOTenantSettings.Workflow2010Disabled
            IsSharePointNewsfeedEnabled                                    = $SPOTenantGraphSettings.IsSharePointNewsfeedEnabled
            IsSiteCreationEnabled                                          = $SPOTenantGraphSettings.IsSiteCreationEnabled
            IsSiteCreationUiEnabled                                        = $SPOTenantGraphSettings.IsSiteCreationUiEnabled
            IsSitePagesCreationEnabled                                     = $SPOTenantGraphSettings.IsSitePagesCreationEnabled
            TenantDefaultTimezone                                          = $SPOTenantGraphSettings.TenantDefaultTimeZone
            Credential                                                     = $Credential
            ApplicationId                                                  = $ApplicationId
            TenantId                                                       = $TenantId
            ApplicationSecret                                              = $ApplicationSecret
            CertificateThumbprint                                          = $CertificateThumbprint
            CertificatePassword                                            = $CertificatePassword
            CertificatePath                                                = $CertificatePath
            ManagedIdentity                                                = $ManagedIdentity.IsPresent
            Ensure                                                         = 'Present'
            AccessTokens                                                   = $AccessTokens
        }

        if ($SPOTenantSettings.OneDriveRequestFilesLinkExpirationInDays -eq -1)
        {
            $results.Remove('OneDriveRequestFilesLinkExpirationInDays') | Out-Null
        }
        if ($SPOTenantSettings.CoreRequestFilesLinkExpirationInDays -eq -1)
        {
            $results.Remove('CoreRequestFilesLinkExpirationInDays') | Out-Null
        }

        return $results
    }
    catch
    {
        New-M365DSCLogEntry -Message 'Error retrieving data:' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential

        throw
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.Boolean]
        $EnableAzureADB2BIntegration,

        [Parameter()]
        [System.UInt32]
        $MinCompatibilityLevel,

        [Parameter()]
        [System.UInt32]
        $MaxCompatibilityLevel,

        [Parameter()]
        [System.Boolean]
        $SearchResolveExactEmailOrUPN,

        [Parameter()]
        [System.Boolean]
        $OfficeClientADALDisabled,

        [Parameter()]
        [System.Boolean]
        $OneDriveRequestFilesLinkEnabled,

        [Parameter()]
        [ValidateRange(0, 730)]
        [System.Int32]
        $OneDriveRequestFilesLinkExpirationInDays,

        [Parameter()]
        [System.Boolean]
        $LegacyAuthProtocolsEnabled,

        [Parameter()]
        [System.String]
        $SignInAccelerationDomain,

        [Parameter()]
        [System.Boolean]
        $UsePersistentCookiesForExplorerView,

        [Parameter()]
        [System.Boolean]
        $PublicCdnEnabled,

        [Parameter()]
        [System.String]
        $PublicCdnAllowedFileTypes,

        [Parameter()]
        [System.Boolean]
        $UseFindPeopleInPeoplePicker,

        [Parameter()]
        [System.Boolean]
        $NotificationsInSharePointEnabled,

        [Parameter()]
        [System.Boolean]
        $OwnerAnonymousNotification,

        [Parameter()]
        [System.Boolean]
        $AllowCommentsTextOnEmailEnabled,

        [Parameter()]
        [System.Boolean]
        $AllowWebPropertyBagUpdateWhenDenyAddAndCustomizePagesIsEnabled,

        [Parameter()]
        [System.Boolean]
        $ApplyAppEnforcedRestrictionsToAdHocRecipients,

        [Parameter()]
        [System.String]
        $ArchiveRedirectUrl,

        [Parameter()]
        [System.Boolean]
        $BlockSendLabelMismatchEmail,

        [Parameter()]
        [System.Boolean]
        $CoreRequestFilesLinkEnabled,

        [Parameter()]
        [ValidateRange(0, 730)]
        [System.Int32]
        $CoreRequestFilesLinkExpirationInDays,

        [Parameter()]
        [System.Boolean]
        $FilePickerExternalImageSearchEnabled,

        [Parameter()]
        [System.Boolean]
        $HideDefaultThemes,

        [Parameter()]
        [System.Boolean]
        $HideSyncButtonOnODB,

        [Parameter()]
        [System.Boolean]
        $HideSyncButtonOnTeamSite,

        [Parameter()]
        [System.Boolean]
        $LegacyBrowserAuthProtocolsEnabled,

        [Parameter()]
        [System.Boolean]
        $EnableDiscoverableByOrganizationForVideos,

        [Parameter()]
        [System.String]
        $RestrictedAccessControlforSitesErrorHelpLink,

        [Parameter()]
        [System.Boolean]
        $Workflow2010Disabled,

        [Parameter()]
        [System.Boolean]
        $HideSyncButtonOnDocLib,

        [Parameter()]
        [System.Int32]
        $StreamLaunchConfig,

        [Parameter()]
        [System.Boolean]
        $EnableMediaReactions,

        [Parameter()]
        [System.Boolean]
        $ContentSecurityPolicyEnforcement,

        [Parameter()]
        [System.Boolean]
        $DisableSpacesActivation,

        [Parameter()]
        [System.Boolean]
        $AllowAppsBypassOfUnmanagedDevicePolicy,

        [Parameter()]
        [System.String[]]
        $DisabledAdaptiveCardExtensionIds,

        [Parameter()]
        [System.Boolean]
        $EnableNotificationsSubscriptions,

        [Parameter()]
        [System.Boolean]
        $EnforceRequestDigest,

        [Parameter()]
        [ValidateSet('Audit', 'None', 'PassiveEnforcement', 'StrictEnforcement')]
        [System.String]
        $TlsTokenBindingPolicyValue,

        [Parameter()]
        [ValidateSet('DefaultAAD', 'Disabled', 'Enabled')]
        [System.String]
        $AuthContextResilienceMode,

        [Parameter()]
        [System.String]
        $AllOrganizationSecurityGroupId,

        [Parameter()]
        [System.Boolean]
        $AllowFileArchive,

        [Parameter()]
        [System.Boolean]
        $AllowFileArchiveOnNewSitesByDefault,

        [Parameter()]
        [System.String[]]
        $ContentTypeSyncSiteTemplatesList,

        [Parameter()]
        [System.Boolean]
        $DisableDocumentLibraryDefaultLabeling,

        [Parameter()]
        [System.Boolean]
        $IsEnableAppAuthPopUpEnabled,

        [Parameter()]
        [System.Int32]
        $ExpireVersionsAfterDays,

        [Parameter()]
        [System.Int32]
        $MajorVersionLimit,

        [Parameter()]
        [System.Boolean]
        $EnableAutoExpirationVersionTrim,

        [Parameter()]
        [System.Boolean]
        $DisableVivaConnectionsAnalytics,

        [Parameter()]
        [ValidateSet('Unspecified', 'On', 'Off')]
        [System.String]
        $CoreBlockGuestsAsSiteAdmin,

        [Parameter()]
        [System.Boolean]
        $IsWBFluidEnabled,

        [Parameter()]
        [System.Boolean]
        $IsCollabMeetingNotesFluidEnabled,

        [Parameter()]
        [ValidateSet('Unspecified', 'On', 'Off')]
        [System.String]
        $AllowAnonymousMeetingParticipantsToAccessWhiteboards,

        [Parameter()]
        [System.Boolean]
        $IBImplicitGroupBased,

        [Parameter()]
        [System.Boolean]
        $ShowOpenInDesktopOptionForSyncedFiles,

        [Parameter()]
        [System.Boolean]
        $ShowPeoplePickerGroupSuggestionsForIB,

        [Parameter()]
        [System.Boolean]
        $ReduceTempTokenLifetimeEnabled,

        [Parameter()]
        [System.Int32]
        $ReduceTempTokenLifetimeValue,

        [Parameter()]
        [System.Boolean]
        $ViewersCanCommentOnMediaDisabled,

        [Parameter()]
        [System.String]
        $ConditionalAccessPolicyErrorHelpLink,

        [Parameter()]
        [System.String]
        $CustomizedExternalSharingServiceUrl,

        [Parameter()]
        [System.Boolean]
        $IncludeAtAGlanceInShareEmails,

        [Parameter()]
        [System.Boolean]
        $MassDeleteNotificationDisabled,

        [Parameter()]
        [System.Boolean]
        $IsDataAccessInCardDesignerEnabled,

        [Parameter()]
        [ValidateSet('AllowExternalSharing', 'BlockExternalSharing')]
        [System.String]
        $MarkNewFilesSensitiveByDefault,

        [Parameter()]
        [ValidateSet('Disabled', 'Enabled')]
        [System.String]
        $MediaTranscription,

        [Parameter()]
        [ValidateSet('Disabled', 'Enabled')]
        [System.String]
        $MediaTranscriptionAutomaticFeatures,

        [Parameter()]
        [System.Guid[]]
        $DisabledWebPartIds,

        [Parameter()]
        [System.Boolean]
        $IsFluidEnabled,

        [Parameter()]
        [System.Boolean]
        $SocialBarOnSitePagesDisabled,

        [Parameter()]
        [System.Boolean]
        $CommentsOnSitePagesDisabled,

        [Parameter()]
        [System.Boolean]
        $EnableAIPIntegration,

        [Parameter()]
        [System.Boolean]
        $EnableSensitivityLabelForPDF,

        [Parameter()]
        [System.Boolean]
        $SiteOwnerManageLegacyServicePrincipalEnabled,

        [Parameter()]
        [System.String]
        $TenantDefaultTimezone,

        [Parameter()]
        [System.Boolean]
        $ExemptNativeUsersFromTenantLevelRestricedAccessControl,

        [Parameter()]
        [System.String[]]
        $AllowSelectSGsInODBListInTenant,

        [Parameter()]
        [System.String[]]
        $DenySelectSGsInODBListInTenant,

        [Parameter()]
        [System.String[]]
        $DenySelectSecurityGroupsInSPSitesList,

        [Parameter()]
        [System.String[]]
        $AllowSelectSecurityGroupsInSPSitesList,

        [Parameter()]
        [System.Boolean]
        $MobileFriendlyUrlEnabledInTenant,

        [Parameter()]
        [System.Boolean]
        $AllowDownloadingNonWebViewableFiles,

        [Parameter()]
        [System.Boolean]
        $AllowEditing,

        [Parameter()]
        [System.Boolean]
        $AppBypassInformationBarriers,

        [Parameter()]
        [ValidateSet('TeamsMeetingRecording')]
        [System.String[]]
        $BlockDownloadFileTypeIds,

        [Parameter()]
        [System.Boolean]
        $BlockDownloadFileTypePolicy,

        [Parameter()]
        [ValidateSet('Open', 'Explicit', 'Implicit', 'OwnerModerated', 'Mixed')]
        [System.String]
        $DefaultOneDriveInformationBarrierMode,

        [Parameter()]
        [System.Boolean]
        $DisableCustomAppAuthentication,

        [Parameter()]
        [System.String[]]
        $DisabledModernListTemplateIds,

        [Parameter()]
        [System.Boolean]
        $DisablePersonalListCreation,

        [Parameter()]
        [System.Boolean]
        $DisplayNamesOfFileViewersInSpo,

        [Parameter()]
        [System.String[]]
        $ExcludedBlockDownloadGroupIds,

        [Parameter()]
        [System.Boolean]
        $IsLoopEnabled,

        [Parameter()]
        [System.Boolean]
        $IsSharePointAddInsDisabled,

        [Parameter()]
        [System.Boolean]
        $IsSharePointNewsfeedEnabled,

        [Parameter()]
        [System.Boolean]
        $IsSiteCreationEnabled,

        [Parameter()]
        [System.Boolean]
        $IsSiteCreationUiEnabled,

        [Parameter()]
        [System.Boolean]
        $IsSitePagesCreationEnabled,

        [Parameter()]
        [System.Boolean]
        $KnowledgeAgentEnabled,

        [Parameter()]
        [System.Boolean]
        $KnowledgeAgentSelectedSitesList,

        [Parameter()]
        [System.String]
        $NoAccessRedirectUrl,

        [Parameter()]
        [ValidateSet('On', 'Off', 'Unspecified')]
        [System.String]
        $OneDriveBlockGuestsAsSiteAdmin,

        [Parameter()]
        [ValidateRange(14, 93)]
        [System.Int32]
        $RecycleBinRetentionPeriod,

        [Parameter()]
        [System.Boolean]
        $RequireAcceptingAccountMatchInvitedAccount,

        [Parameter()]
        [ValidateSet('NoPreference', 'Allowed', 'Disallowed')]
        [System.String]
        $SpecialCharactersStateInFileFolderNames,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    if ($PSEdition -ne 'Core')
    {
        Invoke-PowerShellCoreResource -Path $PSCommandPath -FunctionName $MyInvocation.MyCommand.Name -Parameters $PSBoundParameters
        return
    }

    if ($PSBoundParameters.ContainsKey('IsFluidEnabled') -and $PSBoundParameters.ContainsKey('IsLoopEnabled') -and $IsFluidEnabled -ne $IsLoopEnabled)
    {
        Write-Warning -Message "The 'IsFluidEnabled' property is present together with the 'IsLoopEnabled' property but they have different values. Both parameters refer to the same functionality and should be set to the same value if both are specified. Please update your configuration to ensure only one of the parameters is specified in order to avoid unexpected results."
    }

    Write-Verbose -Message 'Updating configuration for the SPO Tenant Settings'

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $CurrentParameters = Remove-M365DSCAuthenticationParameter -BoundParameters $PSBoundParameters

    $spoRestParameters = @(
        'ExemptNativeUsersFromTenantLevelRestricedAccessControl',
        'AllowSelectSGsInODBListInTenant',
        'DenySelectSGsInODBListInTenant',
        'DenySelectSecurityGroupsInSPSitesList',
        'AllowSelectSecurityGroupsInSPSitesList',
        'HideSyncButtonOnODB',
        'MobileFriendlyUrlEnabledInTenant'
    )
    $spoGraphParameters = @(
        'IsSharePointNewsfeedEnabled',
        'IsSiteCreationEnabled',
        'IsSiteCreationUiEnabled',
        'IsSitePagesCreationEnabled',
        'TenantDefaultTimezone'
    )
    $CurrentParameters.Remove('IsSingleInstance') | Out-Null
    $spoRestParametersSplat = @{}
    foreach ($param in $spoRestParameters)
    {
        if ($currentParameters.ContainsKey($param))
        {
            $spoRestParametersSplat.Add($param, $CurrentParameters[$param])
            $CurrentParameters.Remove($param) | Out-Null
        }
    }
    $spoGraphParametersSplat = @{}
    foreach ($param in $spoGraphParameters)
    {
        if ($CurrentParameters.ContainsKey($param))
        {
            $paramWithLowerCase = $param.Substring(0, 1).ToLower() + $param.Substring(1)
            $spoGraphParametersSplat.Add($paramWithLowerCase, $CurrentParameters[$param])
            $CurrentParameters.Remove($param) | Out-Null
        }
    }

    if ($PublicCdnEnabled -eq $false)
    {
        Write-Verbose -Message 'The use of the public CDN is not enabled, for that the PublicCdnAllowedFileTypes parameter can not be configured and will be removed'
        $CurrentParameters.Remove('PublicCdnAllowedFileTypes') | Out-Null
    }

    if ($spoGraphParametersSplat.Keys.Count -gt 0)
    {
        Reset-MSCloudLoginConnectionProfileContext -Workload 'MicrosoftGraph'
        $null = New-M365DSCConnection -Workload 'MicrosoftGraph' `
            -InboundParameters $PSBoundParameters
        $null = Update-MgAdminSharepointSetting -BodyParameter $spoGraphParametersSplat -ErrorAction Stop
    }

    $null = New-M365DSCConnection -Workload 'PNP' -InboundParameters $PSBoundParameters
    $null = Set-PnPTenant @CurrentParameters -Force

    # Updating via REST
    try
    {
        Write-Verbose -Message "Updating properties via REST PATCH call: $($spoRestParametersSplat | ConvertTo-Json -Depth 5)"
        Invoke-PnPSPRestMethod -Method PATCH `
            -Url "$((Get-MSCloudLoginConnectionProfile -Workload PnP).AdminUrl)/_api/SPO.Tenant" `
            -Content $spoRestParametersSplat
    }
    catch
    {
        if ($_.Exception.Message.Contains('The requested operation is part of an experimental feature that is not supported in the current environment.'))
        {
            Write-Verbose -Message 'Updating via REST: The associated feature is not available in the given tenant.'
        }
        else
        {
            throw $_
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.Boolean]
        $EnableAzureADB2BIntegration,

        [Parameter()]
        [System.UInt32]
        $MinCompatibilityLevel,

        [Parameter()]
        [System.UInt32]
        $MaxCompatibilityLevel,

        [Parameter()]
        [System.Boolean]
        $SearchResolveExactEmailOrUPN,

        [Parameter()]
        [System.Boolean]
        $OfficeClientADALDisabled,

        [Parameter()]
        [System.Boolean]
        $OneDriveRequestFilesLinkEnabled,

        [Parameter()]
        [ValidateRange(0, 730)]
        [System.Int32]
        $OneDriveRequestFilesLinkExpirationInDays,

        [Parameter()]
        [System.Boolean]
        $LegacyAuthProtocolsEnabled,

        [Parameter()]
        [System.String]
        $SignInAccelerationDomain,

        [Parameter()]
        [System.Boolean]
        $UsePersistentCookiesForExplorerView,

        [Parameter()]
        [System.Boolean]
        $PublicCdnEnabled,

        [Parameter()]
        [System.String]
        $PublicCdnAllowedFileTypes,

        [Parameter()]
        [System.Boolean]
        $UseFindPeopleInPeoplePicker,

        [Parameter()]
        [System.Boolean]
        $NotificationsInSharePointEnabled,

        [Parameter()]
        [System.Boolean]
        $OwnerAnonymousNotification,

        [Parameter()]
        [System.Boolean]
        $AllowCommentsTextOnEmailEnabled,

        [Parameter()]
        [System.Boolean]
        $AllowWebPropertyBagUpdateWhenDenyAddAndCustomizePagesIsEnabled,

        [Parameter()]
        [System.Boolean]
        $ApplyAppEnforcedRestrictionsToAdHocRecipients,

        [Parameter()]
        [System.String]
        $ArchiveRedirectUrl,

        [Parameter()]
        [System.Boolean]
        $BlockSendLabelMismatchEmail,

        [Parameter()]
        [System.Boolean]
        $CoreRequestFilesLinkEnabled,

        [Parameter()]
        [ValidateRange(0, 730)]
        [System.Int32]
        $CoreRequestFilesLinkExpirationInDays,

        [Parameter()]
        [System.Boolean]
        $FilePickerExternalImageSearchEnabled,

        [Parameter()]
        [System.Boolean]
        $HideDefaultThemes,

        [Parameter()]
        [System.Boolean]
        $HideSyncButtonOnODB,

        [Parameter()]
        [System.Boolean]
        $HideSyncButtonOnTeamSite,

        [Parameter()]
        [System.Boolean]
        $LegacyBrowserAuthProtocolsEnabled,

        [Parameter()]
        [System.Boolean]
        $EnableDiscoverableByOrganizationForVideos,

        [Parameter()]
        [System.String]
        $RestrictedAccessControlforSitesErrorHelpLink,

        [Parameter()]
        [System.Boolean]
        $Workflow2010Disabled,

        [Parameter()]
        [System.Boolean]
        $HideSyncButtonOnDocLib,

        [Parameter()]
        [System.Int32]
        $StreamLaunchConfig,

        [Parameter()]
        [System.Boolean]
        $EnableMediaReactions,

        [Parameter()]
        [System.Boolean]
        $ContentSecurityPolicyEnforcement,

        [Parameter()]
        [System.Boolean]
        $DisableSpacesActivation,

        [Parameter()]
        [System.Boolean]
        $AllowAppsBypassOfUnmanagedDevicePolicy,

        [Parameter()]
        [System.String[]]
        $DisabledAdaptiveCardExtensionIds,

        [Parameter()]
        [System.Boolean]
        $EnableNotificationsSubscriptions,

        [Parameter()]
        [System.Boolean]
        $EnforceRequestDigest,

        [Parameter()]
        [ValidateSet('Audit', 'None', 'PassiveEnforcement', 'StrictEnforcement')]
        [System.String]
        $TlsTokenBindingPolicyValue,

        [Parameter()]
        [ValidateSet('DefaultAAD', 'Disabled', 'Enabled')]
        [System.String]
        $AuthContextResilienceMode,

        [Parameter()]
        [System.String]
        $AllOrganizationSecurityGroupId,

        [Parameter()]
        [System.Boolean]
        $AllowFileArchive,

        [Parameter()]
        [System.Boolean]
        $AllowFileArchiveOnNewSitesByDefault,

        [Parameter()]
        [System.String[]]
        $ContentTypeSyncSiteTemplatesList,

        [Parameter()]
        [System.Boolean]
        $DisableDocumentLibraryDefaultLabeling,

        [Parameter()]
        [System.Boolean]
        $IsEnableAppAuthPopUpEnabled,

        [Parameter()]
        [System.Int32]
        $ExpireVersionsAfterDays,

        [Parameter()]
        [System.Int32]
        $MajorVersionLimit,

        [Parameter()]
        [System.Boolean]
        $EnableAutoExpirationVersionTrim,

        [Parameter()]
        [System.Boolean]
        $DisableVivaConnectionsAnalytics,

        [Parameter()]
        [ValidateSet('Unspecified', 'On', 'Off')]
        [System.String]
        $CoreBlockGuestsAsSiteAdmin,

        [Parameter()]
        [System.Boolean]
        $IsWBFluidEnabled,

        [Parameter()]
        [System.Boolean]
        $IsCollabMeetingNotesFluidEnabled,

        [Parameter()]
        [ValidateSet('Unspecified', 'On', 'Off')]
        [System.String]
        $AllowAnonymousMeetingParticipantsToAccessWhiteboards,

        [Parameter()]
        [System.Boolean]
        $IBImplicitGroupBased,

        [Parameter()]
        [System.Boolean]
        $ShowOpenInDesktopOptionForSyncedFiles,

        [Parameter()]
        [System.Boolean]
        $ShowPeoplePickerGroupSuggestionsForIB,

        [Parameter()]
        [System.Boolean]
        $ReduceTempTokenLifetimeEnabled,

        [Parameter()]
        [System.Int32]
        $ReduceTempTokenLifetimeValue,

        [Parameter()]
        [System.Boolean]
        $ViewersCanCommentOnMediaDisabled,

        [Parameter()]
        [System.String]
        $ConditionalAccessPolicyErrorHelpLink,

        [Parameter()]
        [System.String]
        $CustomizedExternalSharingServiceUrl,

        [Parameter()]
        [System.Boolean]
        $IncludeAtAGlanceInShareEmails,

        [Parameter()]
        [System.Boolean]
        $MassDeleteNotificationDisabled,

        [Parameter()]
        [System.Boolean]
        $IsDataAccessInCardDesignerEnabled,

        [Parameter()]
        [ValidateSet('AllowExternalSharing', 'BlockExternalSharing')]
        [System.String]
        $MarkNewFilesSensitiveByDefault,

        [Parameter()]
        [ValidateSet('Disabled', 'Enabled')]
        [System.String]
        $MediaTranscription,

        [Parameter()]
        [ValidateSet('Disabled', 'Enabled')]
        [System.String]
        $MediaTranscriptionAutomaticFeatures,

        [Parameter()]
        [System.Guid[]]
        $DisabledWebPartIds,

        [Parameter()]
        [System.Boolean]
        $IsFluidEnabled,

        [Parameter()]
        [System.Boolean]
        $SocialBarOnSitePagesDisabled,

        [Parameter()]
        [System.Boolean]
        $CommentsOnSitePagesDisabled,

        [Parameter()]
        [System.Boolean]
        $EnableAIPIntegration,

        [Parameter()]
        [System.Boolean]
        $EnableSensitivityLabelForPDF,

        [Parameter()]
        [System.Boolean]
        $SiteOwnerManageLegacyServicePrincipalEnabled,

        [Parameter()]
        [System.String]
        $TenantDefaultTimezone,

        [Parameter()]
        [System.Boolean]
        $ExemptNativeUsersFromTenantLevelRestricedAccessControl,

        [Parameter()]
        [System.String[]]
        $AllowSelectSGsInODBListInTenant,

        [Parameter()]
        [System.String[]]
        $DenySelectSGsInODBListInTenant,

        [Parameter()]
        [System.String[]]
        $DenySelectSecurityGroupsInSPSitesList,

        [Parameter()]
        [System.String[]]
        $AllowSelectSecurityGroupsInSPSitesList,

        [Parameter()]
        [System.Boolean]
        $MobileFriendlyUrlEnabledInTenant,

        [Parameter()]
        [System.Boolean]
        $AllowDownloadingNonWebViewableFiles,

        [Parameter()]
        [System.Boolean]
        $AllowEditing,

        [Parameter()]
        [System.Boolean]
        $AppBypassInformationBarriers,

        [Parameter()]
        [ValidateSet('TeamsMeetingRecording')]
        [System.String[]]
        $BlockDownloadFileTypeIds,

        [Parameter()]
        [System.Boolean]
        $BlockDownloadFileTypePolicy,

        [Parameter()]
        [ValidateSet('Open', 'Explicit', 'Implicit', 'OwnerModerated', 'Mixed')]
        [System.String]
        $DefaultOneDriveInformationBarrierMode,

        [Parameter()]
        [System.Boolean]
        $DisableCustomAppAuthentication,

        [Parameter()]
        [System.String[]]
        $DisabledModernListTemplateIds,

        [Parameter()]
        [System.Boolean]
        $DisablePersonalListCreation,

        [Parameter()]
        [System.Boolean]
        $DisplayNamesOfFileViewersInSpo,

        [Parameter()]
        [System.String[]]
        $ExcludedBlockDownloadGroupIds,

        [Parameter()]
        [System.Boolean]
        $IsLoopEnabled,

        [Parameter()]
        [System.Boolean]
        $IsSharePointAddInsDisabled,

        [Parameter()]
        [System.Boolean]
        $IsSharePointNewsfeedEnabled,

        [Parameter()]
        [System.Boolean]
        $IsSiteCreationEnabled,

        [Parameter()]
        [System.Boolean]
        $IsSiteCreationUiEnabled,

        [Parameter()]
        [System.Boolean]
        $IsSitePagesCreationEnabled,

        [Parameter()]
        [System.Boolean]
        $KnowledgeAgentEnabled,

        [Parameter()]
        [System.Boolean]
        $KnowledgeAgentSelectedSitesList,

        [Parameter()]
        [System.String]
        $NoAccessRedirectUrl,

        [Parameter()]
        [ValidateSet('On', 'Off', 'Unspecified')]
        [System.String]
        $OneDriveBlockGuestsAsSiteAdmin,

        [Parameter()]
        [ValidateRange(14, 93)]
        [System.Int32]
        $RecycleBinRetentionPeriod,

        [Parameter()]
        [System.Boolean]
        $RequireAcceptingAccountMatchInvitedAccount,

        [Parameter()]
        [ValidateSet('NoPreference', 'Allowed', 'Disallowed')]
        [System.String]
        $SpecialCharactersStateInFileFolderNames,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    if ($PSEdition -ne 'Core')
    {
        Invoke-PowerShellCoreResource -Path $PSCommandPath -FunctionName $MyInvocation.MyCommand.Name -Parameters $PSBoundParameters
        return
    }

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $compareParameters = Get-CompareParameters
    $result = Test-M365DSCTargetResource -DesiredValues $PSBoundParameters `
        -ResourceName $($MyInvocation.MyCommand.Source).Replace('MSFT_', '') `
        @compareParameters
    return $result
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    if ($PSEdition -ne 'Core')
    {
        Invoke-PowerShellCoreResource -Path $PSCommandPath -FunctionName $MyInvocation.MyCommand.Name -Parameters $PSBoundParameters
        return
    }

    try
    {
        $ConnectionModeGraph = New-M365DSCConnection -Workload 'MicrosoftGraph' `
            -InboundParameters $PSBoundParameters

        $ConnectionMode = New-M365DSCConnection -Workload 'PNP' `
            -InboundParameters $PSBoundParameters

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
        $CommandName = $MyInvocation.MyCommand
        $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
            -CommandName $CommandName `
            -Parameters $PSBoundParameters
        Add-M365DSCTelemetryEvent -Data $data
        #endregion

        if ($null -ne $Global:M365DSCExportResourceInstancesCount)
        {
            $Global:M365DSCExportResourceInstancesCount++
        }

        $Script:ExportMode = $true
        $dscContent = [System.Text.StringBuilder]::new()

        $Params = @{
            IsSingleInstance      = 'Yes'
            ApplicationId         = $ApplicationId
            TenantId              = $TenantId
            ApplicationSecret     = $ApplicationSecret
            CertificateThumbprint = $CertificateThumbprint
            CertificatePath       = $CertificatePath
            CertificatePassword   = $CertificatePassword
            ManagedIdentity       = $ManagedIdentity.IsPresent
            Credential            = $Credential
            AccessTokens          = $AccessTokens
        }

        $Results = Get-TargetResource @Params
        if ($null -eq $Results.MaxCompatibilityLevel)
        {
            $Results.Remove('MaxCompatibilityLevel') | Out-Null
        }
        if ($null -eq $Results.MinCompatibilityLevel)
        {
            $Results.Remove('MinCompatibilityLevel') | Out-Null
        }
        $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $ResourceName `
            -ConnectionMode $ConnectionMode `
            -ModulePath $PSScriptRoot `
            -Results $Results `
            -Credential $Credential
        [void]$dscContent.Append($currentDSCBlock)
        Save-M365DSCPartialExport -Content $currentDSCBlock `
            -FileName $Global:PartialExportFileName
        Write-M365DSCHost -Message $Global:M365DSCEmojiGreenCheckMark -CommitWrite
        return $dscContent.ToString()
    }
    catch
    {
        New-M365DSCLogEntry -Message 'Error during Export:' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential

        throw
    }
}

function Get-CompareParameters
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param()

    return @{
        ExcludedProperties = @()
    }
}

Export-ModuleMember -Function @('*-TargetResource', 'Get-CompareParameters')
