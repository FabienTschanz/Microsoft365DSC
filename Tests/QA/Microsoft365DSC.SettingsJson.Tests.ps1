BeforeDiscovery {
    $resourcesPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/Microsoft365DSC/DscResources'
    $settingsFiles = Get-ChildItem -Path $resourcesPath -Filter '*.json' -Recurse | ForEach-Object {
        @{
            ResourceName = $_.Directory.Name
            FullName     = $_.FullName
        }
    }

    $generatedFromAllowlist = @(
        'AADAuthenticationRequirement'
        'AADCustomAuthenticationExtension'
        'AADFederationConfiguration'
        'AADFilteringPolicyRule'
        'AADGroupEligibilitySchedule'
        'AADGroupEligibilityScheduleSettings'
        'AADIdentityProtectionPolicySettings'
        'AADNamedLocationPolicy'
        'AADOnPremisesPublishingProfilesSettings'
        'AADPIMGroupSetting'
        'AADRoleManagementPolicyRule'
        'AADRoleSetting'
        'AzureBillingAccountsRoleAssignment'
        'AzureRoleEligibilityScheduleSettings'
        'AzureVerifiedIdFaceCheck'
        'DefenderRoleDefinition'
        'EXOAuthenticationPolicyAssignment'
        'EXOSmtpDaneInbound'
        'IntuneAppConfigurationDevicePolicy'
        'IntuneCorporateDeviceIdentifier'
        'IntuneDeviceComplianceScriptLinux'
        'IntuneDeviceComplianceScriptWindows10'
        'IntuneDeviceConfigurationSCEPCertificatePolicyWindows10'
        'IntuneDeviceControlPolicySetting'
        'IntuneDeviceEnrollmentPlatformRestriction'
        'IntuneEpmCertificatePolicySetting'
        'IntuneFirewallPolicySetting'
        'IntuneManagedInstallerPolicyWindows10'
        'IntuneMobileAppsBuiltInStoreApp'
        'IntuneMobileAppsBundleMacOS'
        'IntuneMobileAppsManagedGooglePlayApp'
        'IntuneMobileAppsMicrosoftEdge'
        'IntuneMobileAppsStoreApp'
        'IntuneMobileAppsWebLink'
        'IntuneWifiConfigurationPolicyAndroidEnterpriseWorkProfile'
        'IntuneWifiConfigurationPolicyAndroidOpenSourceProject'
        'IntuneWifiConfigurationPolicyIOS'
        'IntuneWifiConfigurationPolicyMacOS'
        'IntuneWindowsBackupForOrganizationConfiguration'
        'IntuneWindowsDataProcessingSettings'
        'IntuneWindowsUpdateForBusinessDriverUpdateProfileWindows10'
        'IntuneWindowsUpdateForBusinessHotpatchProfileWindows10'
        'M365DSCGraphAPIRuleEvaluation'
        'M365DSCRuleEvaluation'
        'O365CopilotSettingsPeopleEnhancedPersonalization'
        'O365OrgCustomizationSetting'
        'O365OrgSettings'
        'O365SearchAndIntelligenceConfigurations'
        'PPDLPPolicyConnectorConfigurations'
        'PPPowerAppPolicyUrlPatterns'
        'PPTenantIsolationSettings'
        'SHSpaceGroup'
        'SPORetentionLabelsSettings'
        'TeamsOnlineVoiceUser'
        'VivaEngagementRoleMember'
    )

    $resolvedSettingsFiles = @($settingsFiles | Where-Object {
            ($_.ResourceName -replace '^MSFT_', '') -notin $generatedFromAllowlist
        })
    $allowlistedResources = @($generatedFromAllowlist | ForEach-Object {
            @{
                ResourceName = $_
                FullName     = Join-Path -Path $resourcesPath -ChildPath "MSFT_$_/settings.json"
            }
        })
}

Describe -Name 'Successfully import Settings.json files' {
    It "File for '<ResourceName>' should be read successfully" -TestCases $settingsFiles {
        $json = Get-Content -Path $FullName -Raw
        { ConvertFrom-Json -InputObject $json } | Should -Not -Throw
    }
}

Describe -Name 'Successfully validate all used permissions in Settings.json files ' {
    BeforeAll {
        $permissionsFile = Join-Path -Path $PSScriptRoot -ChildPath '../../Tests/QA/Graph.PermissionList.txt'
        $roles = (Get-Content $permissionsFile -Raw).Split(',')
    }

    It "Permissions used in settings.json file for '<ResourceName>' should exist" -TestCases $settingsFiles {
        $json = Get-Content -Path $FullName -Raw
        $settings = ConvertFrom-Json -InputObject $json
        foreach ($permission in $settings.permissions.graph.application.read)
        {
            # Only validate non-GUID (hidden) permissions.
            # There is an issue where the GUI shows Tasks.Read.All but the OAuth value is actually Tasks.Read
            if (-not [System.Guid]::TryParse($permission.Name, [ref][System.Guid]::Empty) -and
                $permission.Name -ne 'Tasks.Read.All')
            {
                $permission.Name | Should -BeIn $roles -ErrorAction Continue
            }
        }
        foreach ($permission in $settings.permissions.graph.application.write)
        {
            # Only validate non-GUID (hidden) permissions.
            if (-not [System.Guid]::TryParse($permission.Name, [ref][System.Guid]::Empty))
            {
                $permission.Name | Should -BeIn $roles -ErrorAction Continue
            }
        }
    }

    It "Should use the least permissions for '<ResourceName>'" -TestCase $settingsFiles {
        $json = Get-Content -Path $FullName -Raw
        $settings = ConvertFrom-Json -InputObject $json

        $allowedPermissions = @()

        if ($settings.ResourceName -like 'Teams*')
        {
            $allowedPermissions = @(
                'Organization.Read.All',
                'User.Read.All',
                'Group.ReadWrite.All',
                'AppCatalog.ReadWrite.All',
                'TeamSettings.ReadWrite.All',
                'Channel.Delete.All',
                'ChannelSettings.ReadWrite.All',
                'ChannelMember.ReadWrite.All',
                'Team.ReadBasic.All'
            )
        }

        if ($settings.ResourceName -like 'VivaEngagement*')
        {
            $allowedPermissions = @(
                'User.ReadBasic.All'
            )
        }

        if ($settings.ResourceName -like 'AADAuthenticationMethod*' -or $settings.ResourceName -eq 'AADAuthenticationStrengthPolicy')
        {
            $allowedPermissions = @(
                'Policy.ReadWrite.AuthenticationMethod'
            )
        }

        if ($settings.ResourceName -eq 'O365OrgSettings')
        {
            $allowedPermissions = @(
                'Application.ReadWrite.All'
            )
        }

        if ($settings.ResourceName -eq 'IntuneDeviceConfigurationCustomPolicyWindows10')
        {
            $allowedPermissions = @(
                'DeviceManagementConfiguration.ReadWrite.All'
            )
        }

        foreach ($permission in $settings.permissions.graph.application.read)
        {
            # There is an issue where the GUI shows Tasks.Read.All but the OAuth value is actually Tasks.Read
            if (-not [System.Guid]::TryParse($permission.Name, [ref][System.Guid]::Empty) -and
                $permission.Name -ne 'Tasks.Read.All' -and -not ($permission.Name -in $allowedPermissions))
            {
                $permission.Name | Should -BeLike '*.Read.*' -ErrorAction Continue
            }
        }
    }
}

Describe -Name 'Every resource records what it was generated from' {
    BeforeAll {
        $graphWorkloads = @('MicrosoftGraph', 'Intune')
        $cmdletWorkloads = @('ExchangeOnline', 'SecurityComplianceCenter', 'MicrosoftTeams', 'PnP', 'PowerPlatforms')
        $restWorkloads = @('Azure', 'AzureDevOPS', 'PowerPlatformREST', 'AdminAPI', 'DefenderForEndpoint', 'EngageHub', 'Fabric', 'Licensing', 'Tasks')
        $knownWorkloads = $graphWorkloads + $cmdletWorkloads + $restWorkloads
        $exclusionReasons = @('ReadOnly', 'NotConfigurable', 'Deprecated', 'OwnedByOtherResource', 'Deferred')

        function Test-GeneratedFromResolved
        {
            param ($GeneratedFrom)

            if ($null -eq $GeneratedFrom -or [System.String]::IsNullOrEmpty($GeneratedFrom.workload))
            {
                return $false
            }
            if ($GeneratedFrom.workload -in $graphWorkloads)
            {
                return -not [System.String]::IsNullOrEmpty($GeneratedFrom.entityType) -and
                    $GeneratedFrom.apiVersion -in @('v1.0', 'beta') -and
                    -not [System.String]::IsNullOrEmpty($GeneratedFrom.cmdletNoun)
            }
            if ($GeneratedFrom.workload -in $cmdletWorkloads)
            {
                return -not [System.String]::IsNullOrEmpty($GeneratedFrom.cmdletNoun)
            }
            return $true
        }
    }

    It "'<ResourceName>' has a resolved generatedFrom block" -TestCases $resolvedSettingsFiles {
        $settings = Get-Content -Path $FullName -Raw | ConvertFrom-Json
        $settings.PSObject.Properties.Name | Should -Contain 'generatedFrom' -Because "$ResourceName must record its origin (run Utilities/Update-ResourceOrigin.ps1)"

        $origin = $settings.generatedFrom
        $origin.workload | Should -Not -BeNullOrEmpty -Because "$ResourceName must name its workload"
        if ($origin.workload -in $graphWorkloads)
        {
            $origin.entityType | Should -Not -BeNullOrEmpty -Because "$ResourceName is a Graph resource and must resolve to a CSDL entity type"
            $origin.apiVersion | Should -BeIn @('v1.0', 'beta') -Because "$ResourceName is a Graph resource and must pin its API version"
            $origin.cmdletNoun | Should -Not -BeNullOrEmpty -Because "$ResourceName is a Graph resource and must name its cmdlet noun"
        }
        elseif ($origin.workload -in $cmdletWorkloads)
        {
            $origin.cmdletNoun | Should -Not -BeNullOrEmpty -Because "$ResourceName is a $($origin.workload) resource and must name its cmdlet noun"
        }
        (Test-GeneratedFromResolved -GeneratedFrom $origin) | Should -BeTrue -Because "$ResourceName is not on the unresolved allowlist"
    }

    It "'<ResourceName>' carries a well-formed origin block" -TestCases $settingsFiles {
        $settings = Get-Content -Path $FullName -Raw | ConvertFrom-Json
        $settings.PSObject.Properties.Name | Should -Contain 'generatedFrom' -Because "$ResourceName must carry a generatedFrom block, resolved or not (run Utilities/Update-ResourceOrigin.ps1)"

        $origin = $settings.generatedFrom
        @($origin.PSObject.Properties.Name) | Should -Be @('workload', 'apiVersion', 'entityType', 'odataSubtype', 'cmdletNoun', 'cmdletVerb', 'includeNavigationProperties', 'generatorVersion') -Because "$ResourceName must follow the generatedFrom contract"
        if (-not [System.String]::IsNullOrEmpty($origin.workload))
        {
            $origin.workload | Should -BeIn $knownWorkloads -Because "$ResourceName must record a workload from the closed set"
        }
        $origin.includeNavigationProperties | Should -BeOfType [System.Boolean] -Because "$ResourceName must record includeNavigationProperties as a boolean"
        $settings.PSObject.Properties.Name | Should -Contain 'excludedProperties' -Because "$ResourceName must carry an excludedProperties array next to generatedFrom"
        foreach ($exclusion in @($settings.excludedProperties))
        {
            $exclusion.name | Should -Not -BeNullOrEmpty -Because "$ResourceName excludedProperties entries must name a property"
            $exclusion.reason | Should -BeIn $exclusionReasons -Because "$ResourceName excludedProperties reasons form a closed set"
        }
    }

    It "allowlisted '<ResourceName>' is still unresolved (remove it from the allowlist otherwise)" -TestCases $allowlistedResources {
        $FullName | Should -Exist -Because "$ResourceName is on the allowlist but no longer exists"
        $settings = Get-Content -Path $FullName -Raw | ConvertFrom-Json
        (Test-GeneratedFromResolved -GeneratedFrom $settings.generatedFrom) | Should -BeFalse -Because "$ResourceName resolved; drop it from the allowlist so the ratchet keeps tightening"
    }
}
