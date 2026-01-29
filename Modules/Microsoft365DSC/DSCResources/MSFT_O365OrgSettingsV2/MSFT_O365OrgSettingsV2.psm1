Confirm-M365DSCModuleDependency -ModuleName 'MSFT_O365OrgSettings'

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.Boolean]
        $CortanaEnabled,

        [Parameter()]
        [System.Boolean]
        $AppsAndServicesIsOfficeStoreEnabled,

        [Parameter()]
        [System.Boolean]
        $AppsAndServicesIsAppAndServicesTrialEnabled,

        [Parameter()]
        [System.Boolean]
        $DynamicsCustomerVoiceIsRestrictedSurveyAccessEnabled,

        [Parameter()]
        [System.Boolean]
        $DynamicsCustomerVoiceIsRecordIdentityByDefaultEnabled,

        [Parameter()]
        [System.Boolean]
        $DynamicsCustomerVoiceIsInOrgFormsPhishingScanEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsExternalSendFormEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsExternalShareCollaborationEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsExternalShareResultEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsExternalShareTemplateEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsRecordIdentityByDefaultEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsBingImageSearchEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsInOrgFormsPhishingScanEnabled,

        [Parameter()]
        [System.Boolean]
        $M365WebEnableUsersToOpenFilesFrom3PStorage,

        [Parameter()]
        [System.Boolean]
        $PlannerAllowCalendarSharing,

        [Parameter()]
        [System.Boolean]
        $AllowPlannerCopilot,

        [Parameter()]
        [System.Boolean]
        $ToDoIsPushNotificationEnabled,

        [Parameter()]
        [System.Boolean]
        $ToDoIsExternalJoinEnabled,

        [Parameter()]
        [System.Boolean]
        $ToDoIsExternalShareEnabled,

        [Parameter()]
        [System.Boolean]
        $VivaInsightsWebExperience,

        [Parameter()]
        [System.Boolean]
        $VivaInsightsDigestEmail,

        [Parameter()]
        [System.Boolean]
        $VivaInsightsOutlookAddInAndInlineSuggestions,

        [Parameter()]
        [System.Boolean]
        $VivaInsightsScheduleSendSuggestions,

        [Parameter()]
        [System.Boolean]
        $AdminCenterReportDisplayConcealedNames,

        [Parameter()]
        [System.String]
        [ValidateSet('current', 'monthlyEnterprise', 'semiAnnual')]
        $InstallationOptionsUpdateChannel,

        [Parameter()]
        [System.String[]]
        [ValidateSet('isVisioEnabled', 'isSkypeForBusinessEnabled', 'isProjectEnabled', 'isMicrosoft365AppsEnabled')]
        $InstallationOptionsAppsForWindows,

        [Parameter()]
        [System.String[]]
        [ValidateSet('isSkypeForBusinessEnabled', 'isMicrosoft365AppsEnabled')]
        $InstallationOptionsAppsForMac,

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
        [System.String[]]
        $AccessTokens
    )

    Write-Verbose -Message "Setting configuration of Office 365 Group $DisplayName"

    try
    {

        $null = New-M365DSCConnection -Workload 'O365Portal' `
            -InboundParameters $PSBoundParameters

        $null = New-M365DSCConnection -Workload 'MicrosoftGraph' `
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

        $results = @{
            IsSingleInstance      = 'Yes'
            Credential            = $Credential
            ApplicationId         = $ApplicationId
            TenantId              = $TenantId
            ApplicationSecret     = $ApplicationSecret
            CertificateThumbprint = $CertificateThumbprint
            CertificatePath       = $CertificatePath
            CertificatePassword   = $CertificatePassword
            ManagedIdentity       = $ManagedIdentity.IsPresent
            AccessTokens          = $AccessTokens
        }

        #region Account Linking
        # TODO: Currently not available in the Admin Center. Try again later.
        #endregion

        #region Adoption Score
        $adoptionScoreConfig = (Invoke-M365DSCO365PortalWebRequest -Uri 'reports/productivityScoreCustomerOption').Output | ConvertFrom-Json
        $adoptionComplexObject = [ordered]@{
            ActionFlowOptedIn        = $adoptionScoreConfig.ActionFlowOptedIn
            ProductivityScoreOptedIn = $adoptionScoreConfig.ProductivityScoreOptedIn
            PSGroupsOptedOut         = $adoptionScoreConfig.PSGroupsOptedOut
            PSOptedOutGroups         = $adoptionScoreConfig.PSOptedOutGroupIds
            CohortInsightOptedIn     = $adoptionScoreConfig.CohortInsightOptedIn
            # Is one of the returned values, but is nowhere to be seen when updating
            #CohortInsightConsent     = $adoptionScoreConfig.CohortInsightConsent
        }

        if ($adoptionComplexObject.PSGroupsOptedOut.Count -gt 0)
        {
            $groupDisplayNames = @()
            $resolvedGroups = (Invoke-M365DSCO365PortalWebRequest -Uri 'groups/getgroupsbyids' -Method 'POST' -Body $adoptionComplexObject.PSOptedOutGroups).Groups
            $groupDisplayNames += $resolvedGroups.DisplayName
            $adoptionComplexObject.PSOptedOutGroups = $groupDisplayNames
        }
        $results.Add('AdoptionScore', $adoptionComplexObject)
        #endregion

        #region Azure Speech Services
        $azureSpeechServicesConfig = Invoke-M365DSCO365PortalWebRequest -Uri 'services/apps/azurespeechservices'
        $results.Add('AzureSpeechServices', $azureSpeechServicesConfig)
        #endregion

        #region Bookings
        # Already fully covered by EXOOrganizationConfig
        #endregion

        #region Brand center
        # Nothing to configure here
        #endregion

        #region Calendar
        # Already managed with EXOSharingPolicy --> Policy for Anonymous.
        # Anonymous references to 'External' people, which is what this category targets.
        #endregion

        #region Cortana
        # Cortana is no longer available. Category stays as legacy.
        #endregion

        #region Developer Portal for Teams
        $developerPortalForTeamsConfig = Invoke-M365DSCO365PortalWebRequest -Uri 'services/apps/developerportal'
        $results.Add('DeveloperPortalForTeams', $developerPortalForTeamsConfig)
        #endregion

        #region Directory synchronization
        # Nothing to do here, provides download for Microsoft Entra Connect tool
        #endregion

        #region Dynamics 365 Customer Voice
        $dynamics365CustomerVoiceConfig = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/apps/officeformspro'
        $dynamics365ComplexObject = [ordered]@{
            InOrgFormsPhishingScanEnabled  = $dynamics365CustomerVoiceConfig.InOrgFormsPhishingScanEnabled
            RecordIdentityByDefaultEnabled = $dynamics365CustomerVoiceConfig.RecordIdentityByDefaultEnabled
            RestrictSurveyAccessEnabled    = $dynamics365CustomerVoiceConfig.RestrictSurveyAccessEnabled
        }
        # Configuring CustomDomainEmails is not possible because it requires multiple steps, including DNS verification.
        # Omitting the values for OverSurveyManagementDays and OverSurveyManagementEnabled as they are not visible in the UI.
        $results.Add('Dynamics365CustomerVoice', $dynamics365ComplexObject)
        #endregion

        #region Dynamics CRM
        # Nothing to do here, links to Power Platform Admin Center
        #endregion

        #region Mail
        # Nothing to do here, links to the Exchange Admin Center
        #endregion

        #region Microsoft 365 Groups
        $tenantIdGuid = [Guid]::Empty
        if ([Guid]::TryParse($TenantId, [ref]$tenantIdGuid))
        {
            $tenantIdGuid = $tenantIdGuid.Guid.ToString()
        }
        else
        {
            $tenantDetails = (Invoke-MgGraphRequest -Uri "/v1.0/organization?`$select=Id" -Method GET).value
            $tenantIdGuid = $tenantDetails.id
        }
        $o365GroupsConfig = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/security/o365guestuser'
        try
        {
            $ownerlessGroupConfig = Invoke-M365DSCO365PortalWebRequest -Uri "https://admin.microsoft.com/fd/speedwayB2Service/v1.0/organizations('TID:$($tenantIdGuid)')/policy/ownerlessGroupPolicy"
            $ownerlessGroupComplex = [ordered]@{
                Enabled                = $ownerlessGroupConfig.enabled
                EnabledGroups          = @()
                EmailSubject           = $ownerlessGroupConfig.emailSubject
                EmailBody              = $ownerlessGroupConfig.emailBody
                IsRuleAllowType        = $ownerlessGroupConfig.isRuleAllowType
                MaxNoOfMembersToNotify = $ownerlessGroupConfig.maxNoOfMembersToNotify
                NoOfWeeksToNotify      = $ownerlessGroupConfig.noOfWeeksToNotify
                PolicyUrl              = $ownerlessGroupConfig.policyUrl
                SecurityGroups         = @()
                SenderEmailAddress     = $ownerlessGroupConfig.senderEmailAddress
            }
            if ($ownerlessGroupConfig.enabledGroupIds.Count -gt 0)
            {
                $groupDisplayNames = @()
                $resolvedGroups = (Invoke-M365DSCO365PortalWebRequest -Uri 'groups/getgroupsbyids' -Method 'POST' -Body $ownerlessGroupConfig.enabledGroupIds).Groups
                $groupDisplayNames += $resolvedGroups.DisplayName
                $ownerlessGroupComplex.EnabledGroups = $groupDisplayNames
            }
            if ($ownerlessGroupConfig.securityGroups.Count -gt 0)
            {
                $securityGroupDisplayNames = @()
                $resolvedSecurityGroups = (Invoke-M365DSCO365PortalWebRequest -Uri 'groups/getgroupsbyids' -Method 'POST' -Body $ownerlessGroupConfig.securityGroups).Groups
                $securityGroupDisplayNames += $resolvedSecurityGroups.DisplayName
                $ownerlessGroupComplex.SecurityGroups = $securityGroupDisplayNames
            }
        }
        catch
        {
            Write-Warning -Message "Failed to retrieve ownerless group policy: $_"
            $null
        }
        $o365GroupsComplexObject = [ordered]@{
            GuestConfiguration          = $o365GroupsConfig
            OwnerlessGroupConfiguration = $ownerlessGroupComplex
        }
        $results.Add('Microsoft365Groups', $o365GroupsComplexObject)
        #endregion

        #region Microsoft 365 installation options
        # Not using the web API for this, using Graph API instead
        $installationOptions = Invoke-MgGraphRequest -Uri "/beta/admin/microsoft365Apps/installationOptions"
        $installationOptionsComplexObject = [ordered]@{
            UpdateChannel  = $installationOptions.updateChannel
            AppsForWindows = $installationOptions.appsForWindows
            AppsForMac     = $installationOptions.appsForMac
        }
        $results.Add('Microsoft365InstallationOptions', $installationOptionsComplexObject)
        #endregion

        #region Microsoft 365 Lighthouse
        $lighthouseOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'services/apps/m365lighthouse'
        $lighthouseComplexObject = @{
            AccountEnabled = $lighthouseOptions.AccountEnabled
        }
        $results.Add('Microsoft365Lighthouse', $lighthouseComplexObject)
        #endregion

        #region Microsoft 365 on the web
        $m365OnTheWebOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/apps/officeonline'
        $results.Add('Microsoft365OnTheWeb', $m365OnTheWebOptions)
        #endregion

        #region Microsoft Azure Information Protection
        # Links to the AIP portal, but the deprecated version
        #endregion

        #region Microsoft communication to users
        $communicationToUsersOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/apps/EndUserCommunications'
        $results.Add('MicrosoftCommunicationToUsers', $communicationToUsersOptions)
        #endregion

        #region Microsoft Edge site lists
        # Will not be covered here - This will be configured in a dedicated resource
        #endregion

        #region Microsoft Forms
        $formsOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/apps/officeforms'
        $formsComplexObject = [ordered]@{
            BingImageSearchEnabled            = $formsOptions.BingImageSearchEnabled
            ExternalSendFormEnabled           = $formsOptions.ExternalSendFormEnabled
            ExternalShareCollaborationEnabled = $formsOptions.ExternalShareCollaborationEnabled
            ExternalShareResultEnabled        = $formsOptions.ExternalShareResultEnabled
            ExternalShareTemplateEnabled      = $formsOptions.ExternalShareTemplateEnabled
            InOrgFormsPhishingScanEnabled     = $formsOptions.InOrgFormsPhishingScanEnabled
            RecordIdentityByDefaultEnabled    = $formsOptions.RecordIdentityByDefaultEnabled
            ResponderEditResponse             = $formsOptions.ResponderEditResponse
        }
        $results.Add('MicrosoftForms', $formsComplexObject)
        #endregion

        #region Microsoft Graph Data Connect
        $graphDataConnectOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/apps/o365dataplan'
        $graphDataConnectComplexObject = [ordered]@{
            ServiceEnabled        = $graphDataConnectOptions.ServiceEnabled
            IsOdspEnabled         = $graphDataConnectOptions.IsOdspEnabled
            IsVivaInsightsEnabled = $graphDataConnectOptions.IsVivaInsightsEnabled
        }
        $results.Add('MicrosoftGraphDataConnect', $graphDataConnectComplexObject)
        #endregion

        #region Microsoft Loop
        $loopOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/apps/looppolicy'
        $loopComplexObject = @{
            LoopPolicy = $loopOptions.LoopPolicy
        }
        $results.Add('MicrosoftLoop', $loopComplexObject)
        #endregion

        #region Microsoft Planner
        $plannerOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/apps/planner'
        $plannerComplexObject = @{
            AllowCalendarSharing = $plannerOptions.allowCalendarSharing
        }
        $results.Add('MicrosoftPlanner', $plannerComplexObject)
        #endregion

        #region Microsoft Teams
        $teamsOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/apps/skypeteams'
        $teamsGuestOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'https://admin.microsoft.com/fd/IC3Config/Skype.Policy/configurations/TeamsClientConfiguration/configuration/Global'
        $teamsComplexObject = [ordered]@{
            AllowGuestUser      = $teamsGuestOptions.AllowGuestUser
            IsSkypeTeamsEnabled = ($teamsOptions.TenantCategorySettings | Where-Object { $_.TenantSkuCategory -eq 'Guest'}).IsSkypeTeamsEnabled.Value
        }
        $results.Add('MicrosoftTeams', $teamsComplexObject)
        #endregion

        #region Microsoft Viva Insights
        $vivaOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'services/apps/vivainsights'
        $vivaComplexObject = [ordered]@{
            IsDashboardOptedOut    = $vivaOptions.IsDashboardOptedOut
            IsEmailOptedOut        = $vivaOptions.IsEmailOptedOut
            IsAddInOptedOut        = $vivaOptions.IsAddInOptedOut
            IsScheduleSendOptedOut = $vivaOptions.IsScheduleSendOptedOut
        }
        $results.Add('MicrosoftVivaInsights', $vivaComplexObject)
        #endregion

        #region Modern authentication
        $modernAuthOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'services/apps/modernAuth'
        $modernAuthComplexObject = [ordered]@{
            AllowBasicAuthSmtp = $modernAuthOptions.AllowBasicAuthSmtp
            DisableModernAuth  = $modernAuthOptions.DisableModernAuth
        }
        $results.Add('ModernAuthentication', $modernAuthComplexObject)
        #endregion

        #region Multi-factor authentication
        # Links to the MFA settings in Entra portal
        #endregion

        #region News
        $industries = (Invoke-M365DSCO365PortalWebRequest -Uri 'searchadminapi/news/industry/Bing').Industries
        $newsOptions = (Invoke-M365DSCO365PortalWebRequest -Uri 'searchadminapi/news/options/Bing').NewsOptions
        $newsComplexObject = [ordered]@{
            ExcludedContent = [array]($newsOptions.ExcludedContent | ForEach-Object { $_.Text })
            Industries  = [array]($newsOptions.Industries | ForEach-Object {
                $industryName = $_
                $industryEntry = $industries | Where-Object Name -EQ $industryName
                if ($null -ne $industryEntry)
                {
                    $industryEntry.DisplayName
                }
            })
            Topics = [array]($newsOptions.Topics | ForEach-Object { $_.Text })
            IsCustomizationEnabled = $newsOptions.IsCustomizationEnabled
            FlagshipOptionsIsEnabled = $newsOptions.FlagshipOptions.IsEnabled
            EdgeNtpOptions = [ordered]@{
                IsOfficeContentEnabled = $newsOptions.EdgeNtpOptions.IsOfficeContentEnabled
                IsShowCompanyAndIndustry = $newsOptions.EdgeNtpOptions.IsShowCompanyAndIndustry
            }
            IndustryUpdates = [ordered]@{
                IsEnabled = $newsOptions.NewsletterOptions.IsEnabled
                UserScale = $newsOptions.NewsletterOptions.UserScale
                Groups    = [array]($newsOptions.NewsletterOptions.Groups | Select-Object -ExpandProperty DisplayName)
                Persons   = [array]($newsOptions.NewsletterOptions.Persons | Select-Object -ExpandProperty UserPrincipalName)
            }
        }
        $results.Add('News', $newsComplexObject)
        #endregion

        #region Pay-as-you-go services
        # Requires Microsoft Syntex and interactive setup
        #endregion

        #region People settings
        $propertyList = @('Division', 'Role', 'UserPrincipalName', 'EmployeeId', 'Alias', 'CostCenter', 'Fax', 'StreetAddress', 'StateOrProvince', 'PostalCode')
        $peoplePropertyOptions = (Invoke-M365DSCO365PortalWebRequest -Uri "https://admin.microsoft.com/fd/peopleadminservice/$tenantIdGuid/profilecard/properties").value
        $peoplePropertyComplexObject = [ordered]@{}
        foreach ($property in $propertyList)
        {
            $propertyOptions = $peoplePropertyOptions | Where-Object directoryPropertyName -EQ $property
            $isVisible = $false
            if ($null -ne $propertyOptions)
            {
                $isVisible = $propertyOptions.visible
            }
            $peoplePropertyComplexObject.Add($property, $isVisible)
        }
        $results.Add('PeopleSettings', $peoplePropertyComplexObject)
        #endregion

        #region Reports
        $reportsOptions = (Invoke-M365DSCO365PortalWebRequest -Uri 'reports/config/GetTenantConfiguration').Output | ConvertFrom-Json
        $reportsComplexObject = [ordered]@{
            PowerBiEnabled = $reportsOptions.PowerBiEnabled
            PrivacyEnabled = $reportsOptions.PrivacyEnabled
        }
        $results.Add('Reports', $reportsComplexObject)
        #endregion

        #region Sales
        # Nothing to do here, contains generic "Learn more" links
        #endregion

        #region Search & intelligence usage analytics
        $searchAnalyticsOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'services/apps/searchintelligenceanalytics'
        $monthlyDigestOptions = Invoke-M365DSCO365PortalWebRequest -Uri "https://admin.microsoft.com/fd/mssearchinsights/api/v1/$tenantIdGuid/featureSetting/fetch"
        $searchAnalyticsComplexObject = [ordered]@{
            MonthlyReport = ($monthlyDigestOptions.featureSettings | Where-Object id -EQ 'MonthlyReport').isEnabled
            UserFiltersOptIn = $searchAnalyticsOptions.userFiltersOptIn
        }
        $results.Add('SearchIntelligenceUsageAnalytics', $searchAnalyticsComplexObject)
        #endregion

        #region Self-service trials and purchases
        # Already covered with the CommerceSelfServicePurchase resource
        #endregion

        #region SharePoint
        # Already covered in the Microsoft 365 Groups section
        #endregion

        #region Sway
        $swayOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/apps/sway'
        $swayComplexObject = [ordered]@{
            ExternalSharingEnabled    = $swayOptions.ExternalSharingEnabled
            FlickrEnabled             = $swayOptions.FlickrEnabled
            PeoplePickerSearchEnabled = $swayOptions.PeoplePickerSearchEnabled
            PickitEnabled             = $swayOptions.PickitEnabled
            WikipediaEnabled          = $swayOptions.WikipediaEnabled
            YouTubeEnabled            = $swayOptions.YouTubeEnabled
        }
        $results.Add('Sway', $swayComplexObject)
        #endregion

        #region User owned apps and services
        $storeAccessOption = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/apps/store'
        $startTrialOption = Invoke-M365DSCO365PortalWebRequest -Uri 'storesettings/iwpurchaseallowed'
        $autoClaimLicenseOption = Invoke-M365DSCO365PortalWebRequest -Uri 'https://admin.microsoft.com/fd/m365licensing/v1/policies/autoclaim'
        $appsAndServicesComplexObject = [ordered]@{
            IsAutoClaimLicensesEnabled = $autoClaimLicenseOption.tenantPolicyValue -eq 'Enabled' # TODO: Change back in Set-TargetResource
            IsOfficeStoreAccessEnabled = $storeAccessOption
            IsStartTrialsOnBehalfOfOrganizationEnabled = $startTrialOption
        }
        $results.Add('UserOwnedAppsAndServices', $appsAndServicesComplexObject)
        #endregion

        #region Viva Learning
        $vivaLearningOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/apps/learning'
        $vivaLearningComplexObject = [ordered]@{
            IsOptionalDiagnosticDataEnabled = $vivaLearningOptions.IsOptionalDiagnosticDataEnabled
            IsRequiredDiagnosticDataEnabled = $vivaLearningOptions.IsRequiredDiagnosticDataEnabled
        }
        $results.Add('VivaLearning', $vivaLearningComplexObject)
        #endregion

        #region What's new in Microsoft 365
        # Nothing to configure here.
        #endregion

        #region Whiteboard
        $whiteboardOptions = Invoke-M365DSCO365PortalWebRequest -Uri 'settings/apps/whiteboard'
        $whiteboardComplexObject = [ordered]@{
            AreConnectedServicesEnabled = $whiteboardOptions.AreConnectedServicesEnabled
            IsClaimEnabled  = $whiteboardOptions.IsClaimEnabled
            IsEnabled       = $whiteboardOptions.IsEnabled
            TelemetryPolicy = $whiteboardOptions.TelemetryPolicy
        }
        $results.Add('Whiteboard', $whiteboardComplexObject)
        #endregion

        return $results
    }
    catch
    {
        New-M365DSCLogEntry -Message 'Error retrieving data:' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential

        return $nullReturn
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.Boolean]
        $CortanaEnabled,

        [Parameter()]
        [System.Boolean]
        $AppsAndServicesIsOfficeStoreEnabled,

        [Parameter()]
        [System.Boolean]
        $AppsAndServicesIsAppAndServicesTrialEnabled,

        [Parameter()]
        [System.Boolean]
        $DynamicsCustomerVoiceIsRestrictedSurveyAccessEnabled,

        [Parameter()]
        [System.Boolean]
        $DynamicsCustomerVoiceIsRecordIdentityByDefaultEnabled,

        [Parameter()]
        [System.Boolean]
        $DynamicsCustomerVoiceIsInOrgFormsPhishingScanEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsExternalSendFormEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsExternalShareCollaborationEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsExternalShareResultEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsExternalShareTemplateEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsRecordIdentityByDefaultEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsBingImageSearchEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsInOrgFormsPhishingScanEnabled,

        [Parameter()]
        [System.Boolean]
        $M365WebEnableUsersToOpenFilesFrom3PStorage,

        [Parameter()]
        [System.Boolean]
        $PlannerAllowCalendarSharing,

        [Parameter()]
        [System.Boolean]
        $AllowPlannerCopilot,

        [Parameter()]
        [System.Boolean]
        $ToDoIsPushNotificationEnabled,

        [Parameter()]
        [System.Boolean]
        $ToDoIsExternalJoinEnabled,

        [Parameter()]
        [System.Boolean]
        $ToDoIsExternalShareEnabled,

        [Parameter()]
        [System.Boolean]
        $VivaInsightsWebExperience,

        [Parameter()]
        [System.Boolean]
        $VivaInsightsDigestEmail,

        [Parameter()]
        [System.Boolean]
        $VivaInsightsOutlookAddInAndInlineSuggestions,

        [Parameter()]
        [System.Boolean]
        $VivaInsightsScheduleSendSuggestions,

        [Parameter()]
        [System.Boolean]
        $AdminCenterReportDisplayConcealedNames,

        [Parameter()]
        [System.String]
        [ValidateSet('current', 'monthlyEnterprise', 'semiAnnual')]
        $InstallationOptionsUpdateChannel,

        [Parameter()]
        [System.String[]]
        [ValidateSet('isVisioEnabled', 'isSkypeForBusinessEnabled', 'isProjectEnabled', 'isMicrosoft365AppsEnabled')]
        $InstallationOptionsAppsForWindows,

        [Parameter()]
        [System.String[]]
        [ValidateSet('isSkypeForBusinessEnabled', 'isMicrosoft365AppsEnabled')]
        $InstallationOptionsAppsForMac,

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

    Write-Verbose -Message "Setting configuration of Office 365 Org Settings"

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

    $null = New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters
    $currentValues = Get-TargetResource @PSBoundParameters

    if ($PSBoundParameters.ContainsKey('M365WebEnableUsersToOpenFilesFrom3PStorage') -and `
        ($M365WebEnableUsersToOpenFilesFrom3PStorage -ne $currentValues.M365WebEnableUsersToOpenFilesFrom3PStorage))
    {
        Write-Verbose -Message "Updating the Microsoft 365 On the Web setting to {$M365WebEnableUsersToOpenFilesFrom3PStorage}"
        $OfficeOnlineId = 'c1f33bc0-bdb4-4248-ba9b-096807ddb43e'
        $M365WebEnableUsersToOpenFilesFrom3PStorageValue = Get-MgServicePrincipal -Filter "appId eq '$OfficeOnlineId'" -Property 'AccountEnabled, Id'
        Update-MgServicePrincipal -ServicePrincipalId $($M365WebEnableUsersToOpenFilesFrom3PStorageValue.Id) `
            -AccountEnabled:$M365WebEnableUsersToOpenFilesFrom3PStorage
    }
    if (($PSBoundParameters.ContainsKey('PlannerAllowCalendarSharing') -and `
        ($PlannerAllowCalendarSharing -ne $currentValues.PlannerAllowCalendarSharing)) -or `
        ($PSBoundParameters.ContainsKey('AllowPlannerCopilot') -and `
        ($AllowPlannerCopilot -ne $currentValues.AllowPlannerCopilot)))
    {
        Write-Verbose -Message "Updating the Planner Allow Calendar Sharing setting to {$PlannerAllowCalendarSharing}"
        Set-M365DSCO365OrgSettingsPlannerConfig -AllowCalendarSharing $PlannerAllowCalendarSharing `
                                                -AllowPlannerCopilot $AllowPlannerCopilot
    }

    if ($PSBoundParameters.ContainsKey('CortanaEnabled') -and `
        ($CortanaEnabled -ne $currentValues.CortanaEnabled))
    {
        $CortanaId = '0a0a29f9-0a25-49c7-94bf-c53c3f8fa69d'
        $CortanaEnabledValue = Get-MgServicePrincipal -Filter "appId eq '$CortanaId'" -Property 'AccountEnabled, Id'

        if ($null -ne $CortanaEnabledValue.Id)
        {
            Write-Verbose -Message "Updating the Cortana setting to {$CortanaEnabled}"
            Update-MgServicePrincipal -ServicePrincipalId $($CortanaEnabledValue.Id) `
                -AccountEnabled:$CortanaEnabled
        }
    }

    # Viva Insights
    if ($PSBoundParameters.ContainsKey('VivaInsightsWebExperience') -and `
        ($currentValues.VivaInsightsWebExperience -ne $VivaInsightsWebExperience))
    {
        Write-Verbose -Message 'Updating Viva Insights settings for Web Experience'
        Set-DefaultTenantMyAnalyticsFeatureConfig -Feature 'Dashboard' -IsEnabled $VivaInsightsWebExperience | Out-Null
    }

    if ($PSBoundParameters.ContainsKey('VivaInsightsDigestEmail') -and `
        ($currentValues.VivaInsightsDigestEmail -ne $VivaInsightsDigestEmail))
    {
        Write-Verbose -Message 'Updating Viva Insights settings for Digest Email'
        Set-DefaultTenantMyAnalyticsFeatureConfig -Feature 'Digest-email' -IsEnabled $VivaInsightsDigestEmail | Out-Null
    }

    if ($PSBoundParameters.ContainsKey('VivaInsightsOutlookAddInAndInlineSuggestions') -and `
        ($currentValues.VivaInsightsOutlookAddInAndInlineSuggestions -ne $VivaInsightsOutlookAddInAndInlineSuggestions))
    {
        Write-Verbose -Message 'Updating Viva Insights settings for Addin and Inline Suggestions'
        Set-DefaultTenantMyAnalyticsFeatureConfig -Feature 'Add-In' -IsEnabled $VivaInsightsOutlookAddInAndInlineSuggestions | Out-Null
    }

    if ($PSBoundParameters.ContainsKey('VivaInsightsScheduleSendSuggestions') -and `
        ($currentValues.VivaInsightsScheduleSendSuggestions -ne $VivaInsightsScheduleSendSuggestions))
    {
        Write-Verbose -Message 'Updating Viva Insights settings for ScheduleSendSuggestions'
        Set-DefaultTenantMyAnalyticsFeatureConfig -Feature 'Scheduled-send' -IsEnabled $VivaInsightsScheduleSendSuggestions | Out-Null
    }

    # Reports Display Names
    $AdminCenterReportDisplayConcealedNamesEnabled = Get-M365DSCOrgSettingsAdminCenterReport
    if ($PSBoundParameters.ContainsKey('AdminCenterReportDisplayConcealedNames') -and `
        ($AdminCenterReportDisplayConcealedNames -ne $AdminCenterReportDisplayConcealedNamesEnabled.displayConcealedNames))
    {
        Write-Verbose -Message "Updating the Admin Center Report Display Concealed Names setting to {$AdminCenterReportDisplayConcealedNames}"
        Update-M365DSCOrgSettingsAdminCenterReport -DisplayConcealedNames $AdminCenterReportDisplayConcealedNames
    }

    # Apps Installation
    if (($PSBoundParameters.ContainsKey('InstallationOptionsAppsForWindows') -or `
                $PSBoundParameters.ContainsKey('InstallationOptionsAppsForMac')) -and `
        ($null -ne (Compare-Object -ReferenceObject $currentValues.InstallationOptionsAppsForWindows -DifferenceObject $InstallationOptionsAppsForWindows) -or `
                $null -ne (Compare-Object -ReferenceObject $currentValues.InstallationOptionsAppsForMac -DifferenceObject $InstallationOptionsAppsForMac)))
    {
        $ConnectionModeTasks = New-M365DSCConnection -Workload 'Tasks' `
            -InboundParameters $PSBoundParameters
        $InstallationOptions = Get-M365DSCOrgSettingsInstallationOptions -AuthenticationOption $ConnectionModeTasks
        $InstallationOptionsToUpdate = @{
            updateChannel  = ''
            appsForWindows = @{
                isMicrosoft365AppsEnabled = $false
                isProjectEnabled          = $false
                isSkypeForBusinessEnabled = $false
                isVisioEnabled            = $false
            }
            appsForMac     = @{
                isMicrosoft365AppsEnabled = $false
                isSkypeForBusinessEnabled = $false
            }
        }

        if ($PSBoundParameters.ContainsKey('InstallationOptionsUpdateChannel') -and `
            ($InstallationOptionsUpdateChannel -ne $InstallationOptions.updateChannel))
        {
            $InstallationOptionsToUpdate.updateChannel = $InstallationOptionsUpdateChannel
        }
        else
        {
            $InstallationOptionsToUpdate.Remove('updateChannel') | Out-Null
        }

        if ($PSBoundParameters.ContainsKey('InstallationOptionsAppsForWindows'))
        {
            foreach ($key in $InstallationOptionsAppsForWindows)
            {
                $InstallationOptionsToUpdate.appsForWindows.$key = $true
            }
        }
        else
        {
            $InstallationOptionsToUpdate.Remove('appsForWindows') | Out-Null
        }

        if ($PSBoundParameters.ContainsKey('InstallationOptionsAppsForMac'))
        {
            foreach ($key in $InstallationOptionsAppsForMac)
            {
                $InstallationOptionsToUpdate.appsForMac.$key = $true
            }
        }
        else
        {
            $InstallationOptionsToUpdate.Remove('appsForMac') | Out-Null
        }

        if ($InstallationOptionsToUpdate.Keys.Count -gt 0)
        {
            Write-Verbose -Message "Updating O365 Installation Options with $(Convert-M365DscHashtableToString -Hashtable $InstallationOptionsToUpdate)"
            Update-M365DSCOrgSettingsInstallationOptions -Options $InstallationOptionsToUpdate `
                -AuthenticationOption $ConnectionModeTasks
        }
    }

    # Forms
    $FormsParametersToUpdate = @{}
    if ($PSBoundParameters.ContainsKey('FormsIsExternalSendFormEnabled') -and `
        ($FormsIsExternalSendFormEnabled -ne $currentValues.FormsIsExternalSendFormEnabled))
    {
        $FormsParametersToUpdate.Add('isExternalSendFormEnabled', $FormsIsExternalSendFormEnabled)
    }
    if ($PSBoundParameters.ContainsKey('FormsIsExternalShareCollaborationEnabled') -and `
        ($FormsIsExternalShareCollaborationEnabled -ne $currentValues.FormsIsExternalShareCollaborationEnabled))
    {
        $FormsParametersToUpdate.Add('isExternalShareCollaborationEnabled', $FormsIsExternalShareCollaborationEnabled)
    }
    if ($PSBoundParameters.ContainsKey('FormsIsExternalShareResultEnabled') -and `
        ($FormsIsExternalShareResultEnabled -ne $currentValues.FormsIsExternalShareResultEnabled))
    {
        $FormsParametersToUpdate.Add('isExternalShareResultEnabled', $FormsIsExternalShareResultEnabled)
    }
    if ($PSBoundParameters.ContainsKey('FormsIsExternalShareTemplateEnabled') -and `
        ($FormsIsExternalShareTemplateEnabled -ne $currentValues.FormsIsExternalShareTemplateEnabled))
    {
        $FormsParametersToUpdate.Add('isExternalShareTemplateEnabled', $FormsIsExternalShareTemplateEnabled)
    }
    if ($PSBoundParameters.ContainsKey('FormsIsRecordIdentityByDefaultEnabled') -and `
        ($FormsIsRecordIdentityByDefaultEnabled -ne $currentValues.FormsIsRecordIdentityByDefaultEnabled))
    {
        $FormsParametersToUpdate.Add('isRecordIdentityByDefaultEnabled', $FormsIsRecordIdentityByDefaultEnabled)
    }
    if ($PSBoundParameters.ContainsKey('FormsIsBingImageSearchEnabled') -and `
        ($FormsIsBingImageSearchEnabled -ne $currentValues.FormsIsBingImageSearchEnabled))
    {
        $FormsParametersToUpdate.Add('isBingImageSearchEnabled', $FormsIsBingImageSearchEnabled)
    }
    if ($PSBoundParameters.ContainsKey('FormsIsInOrgFormsPhishingScanEnabled') -and `
        ($FormsIsInOrgFormsPhishingScanEnabled -ne $currentValues.FormsIsInOrgFormsPhishingScanEnabled))
    {
        $FormsParametersToUpdate.Add('isInOrgFormsPhishingScanEnabled', $FormsIsInOrgFormsPhishingScanEnabled)
    }
    if ($FormsParametersToUpdate.Keys.Count -gt 0)
    {
        Write-Verbose -Message "Updating the Microsoft Forms settings with values:$(Convert-M365DscHashtableToString -Hashtable $FormsParametersToUpdate)"
        Update-M365DSCOrgSettingsForms -Options $FormsParametersToUpdate
    }

    # Dynamics Customer Voice Settings
    $DynamicsCustomerVoiceParametersToUpdate = @{}
    if ($PSBoundParameters.ContainsKey('DynamicsCustomerVoiceIsRestrictedSurveyAccessEnabled') -and `
        ($DynamicsCustomerVoiceIsRestrictedSurveyAccessEnabled -ne $currentValues.DynamicsCustomerVoiceIsRestrictedSurveyAccessEnabled))
    {
        $DynamicsCustomerVoiceParametersToUpdate.Add('isRestrictedSurveyAccessEnabled', $DynamicsCustomerVoiceIsRestrictedSurveyAccessEnabled)
    }
    if ($PSBoundParameters.ContainsKey('DynamicsCustomerVoiceIsRecordIdentityByDefaultEnabled') -and `
        ($DynamicsCustomerVoiceIsRecordIdentityByDefaultEnabled -ne $currentValues.DynamicsCustomerVoiceIsRecordIdentityByDefaultEnabled))
    {
        $DynamicsCustomerVoiceParametersToUpdate.Add('isRecordIdentityByDefaultEnabled', $DynamicsCustomerVoiceIsRecordIdentityByDefaultEnabled)
    }
    if ($PSBoundParameters.ContainsKey('DynamicsCustomerVoiceIsInOrgFormsPhishingScanEnabled') -and `
        ($DynamicsCustomerVoiceIsInOrgFormsPhishingScanEnabled -ne $currentValues.DynamicsCustomerVoiceIsInOrgFormsPhishingScanEnabled))
    {
        $DynamicsCustomerVoiceParametersToUpdate.Add('isInOrgFormsPhishingScanEnabled', $DynamicsCustomerVoiceIsInOrgFormsPhishingScanEnabled)
    }
    if ($DynamicsCustomerVoiceParametersToUpdate.Keys.Count -gt 0)
    {
        Write-Verbose -Message "Updating the Dynamics 365 Customer Voice settings with values:$(Convert-M365DscHashtableToString -Hashtable $DynamicsCustomerVoiceParametersToUpdate)"
        Update-M365DSCOrgSettingsDynamicsCustomerVoice -Options $DynamicsCustomerVoiceParametersToUpdate
    }

    # Apps And Services
    $AppsAndServicesParametersToUpdate = @{}
    if ($PSBoundParameters.ContainsKey('AppsAndServicesIsOfficeStoreEnabled') -and `
        ($AppsAndServicesIsOfficeStoreEnabled -ne $currentValues.AppsAndServicesIsOfficeStoreEnabled))
    {
        $AppsAndServicesParametersToUpdate.Add('isOfficeStoreEnabled', $AppsAndServicesIsOfficeStoreEnabled)
    }
    if ($PSBoundParameters.ContainsKey('AppsAndServicesIsAppAndServicesTrialEnabled') -and `
        ($AppsAndServicesIsAppAndServicesTrialEnabled -ne $currentValues.AppsAndServicesIsAppAndServicesTrialEnabled))
    {
        $AppsAndServicesParametersToUpdate.Add('isAppAndServicesTrialEnabled', $AppsAndServicesIsAppAndServicesTrialEnabled)
    }
    if ($AppsAndServicesParametersToUpdate.Keys.Count -gt 0)
    {
        Write-Verbose -Message "Updating the Apps & Settings settings with values:$(Convert-M365DscHashtableToString -Hashtable $AppsAndServicesParametersToUpdate)"
        Update-M365DSCOrgSettingsAppsAndServices -Options $AppsAndServicesParametersToUpdate
    }

    # To Do
    $ToDoParametersToUpdate = @{}
    if ($PSBoundParameters.ContainsKey('ToDoIsPushNotificationEnabled') -and `
        ($ToDoIsPushNotificationEnabled -ne $currentValues.ToDoIsPushNotificationEnabled))
    {
        $ToDoParametersToUpdate.Add('isPushNotificationEnabled', $ToDoIsPushNotificationEnabled)
    }
    if ($PSBoundParameters.ContainsKey('ToDoIsExternalJoinEnabled') -and `
        ($ToDoIsExternalJoinEnabled -ne $currentValues.ToDoIsExternalJoinEnabled))
    {
        $ToDoParametersToUpdate.Add('isExternalJoinEnabled', $ToDoIsExternalJoinEnabled)
    }
    if ($PSBoundParameters.ContainsKey('ToDoIsExternalShareEnabled') -and `
        ($ToDoIsExternalShareEnabled -ne $currentValues.ToDoIsExternalShareEnabled))
    {
        $ToDoParametersToUpdate.Add('isExternalShareEnabled', $ToDoIsExternalShareEnabled)
    }
    if ($ToDoParametersToUpdate.Keys.Count -gt 0)
    {
        Write-Verbose -Message "Updating the To Do settings with values:$(Convert-M365DscHashtableToString -Hashtable $ToDoParametersToUpdate)"
        Update-M365DSCOrgSettingsToDo -Options $ToDoParametersToUpdate
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
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.Boolean]
        $CortanaEnabled,

        [Parameter()]
        [System.Boolean]
        $AppsAndServicesIsOfficeStoreEnabled,

        [Parameter()]
        [System.Boolean]
        $AppsAndServicesIsAppAndServicesTrialEnabled,

        [Parameter()]
        [System.Boolean]
        $DynamicsCustomerVoiceIsRestrictedSurveyAccessEnabled,

        [Parameter()]
        [System.Boolean]
        $DynamicsCustomerVoiceIsRecordIdentityByDefaultEnabled,

        [Parameter()]
        [System.Boolean]
        $DynamicsCustomerVoiceIsInOrgFormsPhishingScanEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsExternalSendFormEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsExternalShareCollaborationEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsExternalShareResultEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsExternalShareTemplateEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsRecordIdentityByDefaultEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsBingImageSearchEnabled,

        [Parameter()]
        [System.Boolean]
        $FormsIsInOrgFormsPhishingScanEnabled,

        [Parameter()]
        [System.Boolean]
        $M365WebEnableUsersToOpenFilesFrom3PStorage,

        [Parameter()]
        [System.Boolean]
        $PlannerAllowCalendarSharing,

        [Parameter()]
        [System.Boolean]
        $AllowPlannerCopilot,

        [Parameter()]
        [System.Boolean]
        $ToDoIsPushNotificationEnabled,

        [Parameter()]
        [System.Boolean]
        $ToDoIsExternalJoinEnabled,

        [Parameter()]
        [System.Boolean]
        $ToDoIsExternalShareEnabled,

        [Parameter()]
        [System.Boolean]
        $VivaInsightsWebExperience,

        [Parameter()]
        [System.Boolean]
        $VivaInsightsDigestEmail,

        [Parameter()]
        [System.Boolean]
        $VivaInsightsOutlookAddInAndInlineSuggestions,

        [Parameter()]
        [System.Boolean]
        $VivaInsightsScheduleSendSuggestions,

        [Parameter()]
        [System.Boolean]
        $AdminCenterReportDisplayConcealedNames,

        [Parameter()]
        [System.String]
        [ValidateSet('current', 'monthlyEnterprise', 'semiAnnual')]
        $InstallationOptionsUpdateChannel,

        [Parameter()]
        [System.String[]]
        [ValidateSet('isVisioEnabled', 'isSkypeForBusinessEnabled', 'isProjectEnabled', 'isMicrosoft365AppsEnabled')]
        $InstallationOptionsAppsForWindows,

        [Parameter()]
        [System.String[]]
        [ValidateSet('isSkypeForBusinessEnabled', 'isMicrosoft365AppsEnabled')]
        $InstallationOptionsAppsForMac,

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

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $result = Test-M365DSCTargetResource -DesiredValues $PSBoundParameters `
                                         -ResourceName $($MyInvocation.MyCommand.Source).Replace('MSFT_', '')
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

    $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
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

    try
    {
        if ($null -ne $Global:M365DSCExportResourceInstancesCount)
        {
            $Global:M365DSCExportResourceInstancesCount++
        }

        $Params = @{
            IsSingleInstance      = 'Yes'
            Credential            = $Credential
            ApplicationId         = $ApplicationId
            TenantId              = $TenantId
            AccessTokens          = $AccessTokens
        }

        $Results = Get-TargetResource @Params

        if ($null -ne $Results.AdoptionScore)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.AdoptionScore `
                -CIMInstanceName 'O365AdoptionScore'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.AdoptionScore = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('AdoptionScore') | Out-Null
            }
        }
        if ($null -ne $Results.AzureSpeechServices)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.AzureSpeechServices `
                -CIMInstanceName 'O365AzureSpeechServices'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.AzureSpeechServices = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('AzureSpeechServices') | Out-Null
            }
        }
        if ($null -ne $Results.DeveloperPortalForTeams)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.DeveloperPortalForTeams `
                -CIMInstanceName 'O365DeveloperPortalForTeams'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.DeveloperPortalForTeams = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('DeveloperPortalForTeams') | Out-Null
            }
        }
        if ($null -ne $Results.Dynamics365CustomerVoice)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.Dynamics365CustomerVoice `
                -CIMInstanceName 'Dynamics365CustomerVoice'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.Dynamics365CustomerVoice = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('Dynamics365CustomerVoice') | Out-Null
            }
        }
        if ($null -ne $Results.Microsoft365Groups)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.Microsoft365Groups `
                -CIMInstanceName 'Microsoft365Groups'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.Microsoft365Groups = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('Microsoft365Groups') | Out-Null
            }
        }
        if ($null -ne $Results.Microsoft365Groups)
        {
            $complexMapping = @(
                @{
                    Name = "GuestConfiguration"
                    CimInstanceName = "O365GuestUser"
                    IsRequired = $false
                }
                @{
                    Name = "OwnerlessGroupConfiguration"
                    CimInstanceName = "OwnerlessGroupPolicy"
                    IsRequired = $false
                }
            )
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.Microsoft365Groups `
                -CIMInstanceName 'Microsoft365Groups' `
                -ComplexTypeMapping $complexMapping
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.Microsoft365Groups = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('Microsoft365Groups') | Out-Null
            }
        }
        if ($null -ne $Results.Microsoft365InstallationOptions)
        {
            $complexMapping = @(
                @{
                    Name = "AppsForWindows"
                    CimInstanceName = "AppInstallOptionsForWindows"
                    IsRequired = $false
                }
                @{
                    Name = "AppsForMac"
                    CimInstanceName = "AppInstallOptionsForMac"
                    IsRequired = $false
                }
            )
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.Microsoft365InstallationOptions `
                -CIMInstanceName 'O365InstallationOptions' `
                -ComplexTypeMapping $complexMapping
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.Microsoft365InstallationOptions = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('Microsoft365InstallationOptions') | Out-Null
            }
        }
        if ($null -ne $Results.Microsoft365Lighthouse)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.Microsoft365Lighthouse `
                -CIMInstanceName 'Microsoft365Lighthouse'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.Microsoft365Lighthouse = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('Microsoft365Lighthouse') | Out-Null
            }
        }
        if ($null -ne $Results.Microsoft365OnTheWeb)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.Microsoft365OnTheWeb `
                -CIMInstanceName 'Microsoft365OnTheWeb'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.Microsoft365OnTheWeb = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('Microsoft365OnTheWeb') | Out-Null
            }
        }
        if ($null -ne $Results.MicrosoftCommunicationToUsers)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.MicrosoftCommunicationToUsers `
                -CIMInstanceName 'Microsoft365EndUserCommunications'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.MicrosoftCommunicationToUsers = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('MicrosoftCommunicationToUsers') | Out-Null
            }
        }
        if ($null -ne $Results.MicrosoftForms)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.MicrosoftForms `
                -CIMInstanceName 'MicrosoftForms'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.MicrosoftForms = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('MicrosoftForms') | Out-Null
            }
        }
        if ($null -ne $Results.MicrosoftGraphDataConnect)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.MicrosoftGraphDataConnect `
                -CIMInstanceName 'MicrosoftGraphDataConnect'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.MicrosoftGraphDataConnect = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('MicrosoftGraphDataConnect') | Out-Null
            }
        }
        if ($null -ne $Results.MicrosoftLoop)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.MicrosoftLoop `
                -CIMInstanceName 'Microsoft365Loop'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.MicrosoftLoop = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('MicrosoftLoop') | Out-Null
            }
        }
        if ($null -ne $Results.MicrosoftPlanner)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.MicrosoftPlanner `
                -CIMInstanceName 'Microsoft365Planner'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.MicrosoftPlanner = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('MicrosoftPlanner') | Out-Null
            }
        }
        if ($null -ne $Results.MicrosoftTeams)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.MicrosoftTeams `
                -CIMInstanceName 'Microsoft365Teams'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.MicrosoftTeams = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('MicrosoftTeams') | Out-Null
            }
        }
        if ($null -ne $Results.MicrosoftVivaInsights)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.MicrosoftVivaInsights `
                -CIMInstanceName 'MicrosoftViva'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.MicrosoftVivaInsights = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('MicrosoftVivaInsights') | Out-Null
            }
        }
        if ($null -ne $Results.ModernAuthentication)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.ModernAuthentication `
                -CIMInstanceName 'Microsoft365ModernAuth'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.ModernAuthentication = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('ModernAuthentication') | Out-Null
            }
        }
        if ($null -ne $Results.News)
        {
            $complexMapping = @(
                @{
                    Name = "BingHomepage"
                    CimInstanceName = "Microsoft365BingHomepage"
                    IsRequired = $false
                }
                @{
                    Name = "EdgeNtpOptions"
                    CimInstanceName = "Microsoft365EdgeNewTabPage"
                    IsRequired = $false
                }
                @{
                    Name = "IndustryUpdates"
                    CimInstanceName = "Microsoft365IndustryUpdates"
                    IsRequired = $false
                }
            )
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.News `
                -CIMInstanceName 'Microsoft365News' `
                -ComplexTypeMapping $complexMapping
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.News = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('News') | Out-Null
            }
        }
        if ($null -ne $Results.PayAsYouGo)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.PayAsYouGo `
                -CIMInstanceName 'Microsoft365PayAsYouGo'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.PayAsYouGo = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('PayAsYouGo') | Out-Null
            }
        }
        if ($null -ne $Results.PeopleSettings)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.PeopleSettings `
                -CIMInstanceName 'Microsoft365People'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.PeopleSettings = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('PeopleSettings') | Out-Null
            }
        }
        if ($null -ne $Results.Reports)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.Reports `
                -CIMInstanceName 'Microsoft365Reports'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.Reports = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('Reports') | Out-Null
            }
        }
        if ($null -ne $Results.SearchIntelligenceUsageAnalytics)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.SearchIntelligenceUsageAnalytics `
                -CIMInstanceName 'Microsoft365UsageAnalytics'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.SearchIntelligenceUsageAnalytics = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('SearchIntelligenceUsageAnalytics') | Out-Null
            }
        }
        if ($null -ne $Results.Sway)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.Sway `
                -CIMInstanceName 'Microsoft365Sway'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.Sway = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('Sway') | Out-Null
            }
        }
        if ($null -ne $Results.UserOwnedAppsAndServices)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.UserOwnedAppsAndServices `
                -CIMInstanceName 'Microsoft365AppsAndServices'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.UserOwnedAppsAndServices = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('UserOwnedAppsAndServices') | Out-Null
            }
        }
        if ($null -ne $Results.VivaLearning)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.VivaLearning `
                -CIMInstanceName 'Microsoft365VivaLearning'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.VivaLearning = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('VivaLearning') | Out-Null
            }
        }
        if ($null -ne $Results.Whiteboard)
        {
            $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                -ComplexObject $Results.Whiteboard `
                -CIMInstanceName 'Microsoft365Whiteboard'
            if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
            {
                $Results.Whiteboard = $complexTypeStringResult
            }
            else
            {
                $Results.Remove('Whiteboard') | Out-Null
            }
        }

        $dscContent = ''
        $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $ResourceName `
            -ConnectionMode $ConnectionMode `
            -ModulePath $PSScriptRoot `
            -Results $Results `
            -Credential $Credential `
            -NoEscape @("AdoptionScore","AzureSpeechServices","DeveloperPortalForTeams","Dynamics365CustomerVoice",
            "Microsoft365Groups","Microsoft365InstallationOptions","Microsoft365Lighthouse","Microsoft365OnTheWeb",
            "MicrosoftCommunicationToUsers","MicrosoftForms","MicrosoftGraphDataConnect","MicrosoftLoop","MicrosoftPlanner",
            "MicrosoftTeams","MicrosoftVivaInsights","ModernAuthentication","News","PayAsYouGo","PeopleSettings","Reports",
            "SearchIntelligenceUsageAnalytics","Sway","UserOwnedAppsAndServices","VivaLearning","Whiteboard")
        $dscContent += $currentDSCBlock

        Save-M365DSCPartialExport -Content $currentDSCBlock `
            -FileName $Global:PartialExportFileName
        Write-M365DSCHost -Message $Global:M365DSCEmojiGreenCheckMark -CommitWrite

        return $dscContent
    }
    catch
    {
        Write-M365DSCHost -Message $Global:M365DSCEmojiRedX -CommitWrite

        New-M365DSCLogEntry -Message 'Error during Export:' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential

        return ''
    }
}
function Set-M365DSCO365OrgSettingsPlannerConfig
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.Boolean]
        $AllowCalendarSharing,

        [Parameter()]
        [System.Boolean]
        $AllowPlannerCopilot
    )

    $flags = @{}

    if ($null -ne $AllowCalendarSharing)
    {
        $flags.Add('allowCalendarSharing', $AllowCalendarSharing)
    }
    if ($null -ne $AllowPlannerCopilot)
    {
        $flags.Add('allowPlannerCopilot', $AllowPlannerCopilot)
    }

    if ($flags.Keys.Count -gt 0)
    {
        $requestBody = $flags | ConvertTo-Json
        Write-Verbose -Message "Updating Planner settings with values:`r`n$($requestBody)"
        $Uri = (Get-MSCloudLoginConnectionProfile -Workload Tasks).HostUrl + '/taskAPI/tenantAdminSettings/Settings'
        $results = Invoke-RestMethod -ContentType 'application/json;odata.metadata=full' `
            -Headers @{'Accept' = 'application/json'; 'Authorization' = (Get-MSCloudLoginConnectionProfile -Workload Tasks).AccessToken; 'Accept-Charset' = 'UTF-8'; 'OData-Version' = '4.0;NetFx'; 'OData-MaxVersion' = '4.0;NetFx' } `
            -Method PATCH `
            -Body $requestBody `
            -Uri $Uri
    }
}

function Update-M365DSCOrgSettingsInstallationOptions
{
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Options,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AuthenticationOption
    )

    try
    {
        $url = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + 'beta/admin/microsoft365Apps/installationOptions'
        Invoke-MgGraphRequest -Method PATCH -Uri $url -Body $Options | Out-Null
    }
    catch
    {
        if ($_.Exception.ToString().Contains('Forbidden (Forbidden)'))
        {
            if ($AuthenticationOption -eq 'Credentials')
            {
                $errorMessage = "You don't have the proper permissions to update the Office 365 Apps Installation Options." `
                    + ' When using Credentials to authenticate, you need to grant permissions to the Microsoft Graph PowerShell SDK by running' `
                    + ' Connect-MgGraph -Scopes OrgSettings-Microsoft365Install.ReadWrite.All'
                Write-Error -Message $errorMessage
            }
        }
    }
}

function Update-M365DSCOrgSettingsForms
{
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Options
    )

    try
    {
        Write-Verbose -Message 'Updating Forms Settings'
        $url = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + 'beta/admin/forms/settings'
        Invoke-MgGraphRequest -Method PATCH -Uri $url -Body $Options | Out-Null
    }
    catch
    {
        New-M365DSCLogEntry -Message 'Error updating O365OrgSettings Forms Settings' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential
    }
}

function Update-M365DSCOrgSettingsDynamicsCustomerVoice
{
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Options
    )

    try
    {
        $url = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + 'beta/admin/dynamics/customerVoice'
        Invoke-MgGraphRequest -Method PATCH -Uri $url -Body $Options | Out-Null
    }
    catch
    {
        New-M365DSCLogEntry -Message 'Error updating O365OrgSettings Dynamics Customer Voice Settings' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential
    }
}

function Update-M365DSCOrgSettingsAppsAndServices
{
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Options
    )

    try
    {
        $url = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + 'beta/admin/appsAndServices/settings'
        Invoke-MgGraphRequest -Method PATCH -Uri $url -Body $Options | Out-Null
    }
    catch
    {
        New-M365DSCLogEntry -Message 'Error updating O365OrgSettings Apps and Services Settings' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential
    }
}

function Update-M365DSCOrgSettingsToDo
{
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Options
    )

    try
    {
        $url = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + 'beta/admin/todo/settings'
        Invoke-MgGraphRequest -Method PATCH -Uri $url -Body $Options | Out-Null
    }
    catch
    {
        Write-Verbose -Message "Error: $($_.Exception.Message)"
        New-M365DSCLogEntry -Message 'Error updating O365OrgSettings To Do Settings' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential
    }
}

function Update-M365DSCOrgSettingsAdminCenterReport
{
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $DisplayConcealedNames
    )

    $url = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + 'beta/admin/reportSettings'
    $body = @{
        '@odata.context'      = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + 'beta/$metadata#admin/reportSettings/$entity'
        displayConcealedNames = $DisplayConcealedNames
    }
    Invoke-MgGraphRequest -Method PATCH -Uri $url -Body $body | Out-Null
}

Export-ModuleMember -Function *-TargetResource
