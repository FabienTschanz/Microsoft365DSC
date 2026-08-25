BeforeAll {
    Import-Module "$PSScriptRoot/../../../Modules/Microsoft365DSC/Modules/M365DSCDllLoader.psm1" -Force -Global
    Initialize-M365DSCDllLoader
    Import-Module "$PSScriptRoot/../../../Modules/Microsoft365DSC/Modules/M365DSCIntuneUtil.psm1" -Force -Global

    function global:Get-MgBetaDeviceManagementDeviceConfiguration
    {
        [CmdletBinding()]
        param ($All, $Filter, $ExpandProperty)
    }

    function global:Get-MgBetaDeviceManagementDeviceCompliancePolicy
    {
        [CmdletBinding()]
        param ($All, $Filter, $ExpandProperty)
    }

    function global:Get-MgBetaDeviceManagementDeviceEnrollmentConfiguration
    {
        [CmdletBinding()]
        param ($All, $Filter, $ExpandProperty)
    }

    $Script:Cache = [Microsoft365DSC.Intune.ExportCollectionCache]
}

Describe 'M365DSCExportCollectionCache' {
    AfterEach {
        [Microsoft365DSC.Intune.ExportCollectionCache]::Reset()
    }

    Context 'ExportCollectionCache' {
        It 'reports a miss for every call while disabled' {
            $items = $null
            $Script:Cache::TryGet('deviceConfigurations', [ref] $items) | Should -BeFalse
            $Script:Cache::ShouldPopulate('deviceConfigurations') | Should -BeFalse
            $Script:Cache::TrySet('deviceConfigurations', [object[]] @(@{ id = '1' })) | Should -BeFalse
        }

        It 'round-trips a collection once enabled' {
            $Script:Cache::Enable()
            $Script:Cache::ShouldPopulate('deviceConfigurations') | Should -BeTrue
            $Script:Cache::TrySet('deviceConfigurations', [object[]] @(@{ id = '1' })) | Should -BeTrue
            $Script:Cache::ShouldPopulate('deviceConfigurations') | Should -BeFalse
            $items = $null
            $Script:Cache::TryGet('deviceConfigurations', [ref] $items) | Should -BeTrue
            @($items).Count | Should -Be 1
        }

        It 'treats an empty collection as populated' {
            $Script:Cache::Enable()
            $Script:Cache::TrySet('deviceConfigurations', [object[]] @()) | Should -BeTrue
            $Script:Cache::ShouldPopulate('deviceConfigurations') | Should -BeFalse
            $items = $null
            $Script:Cache::TryGet('deviceConfigurations', [ref] $items) | Should -BeTrue
            @($items).Count | Should -Be 0
        }

        It 'filters by @odata.type ignoring the # prefix and case' {
            $Script:Cache::Enable()
            $null = $Script:Cache::TrySet('deviceConfigurations', [object[]] @(
                    @{ id = '1'; '@odata.type' = '#microsoft.graph.windowsKioskConfiguration' },
                    @{ id = '2'; '@odata.type' = '#microsoft.graph.windowsWifiConfiguration' },
                    @{ id = '3'; '@odata.type' = '#microsoft.graph.windowsWifiEnterpriseEAPConfiguration' }
                ))
            $kiosk = $Script:Cache::GetByODataType('deviceConfigurations', [string[]] @('Microsoft.Graph.WindowsKioskConfiguration'), [string[]] @())
            @($kiosk).id | Should -Be '1'
            $wifi = $Script:Cache::GetByODataType('deviceConfigurations', [string[]] @('microsoft.graph.windowsWifiConfiguration'), [string[]] @('microsoft.graph.windowsWifiEnterpriseEAPConfiguration'))
            @($wifi).id | Should -Be '2'
            $all = $Script:Cache::GetByODataType('deviceConfigurations', [string[]] @(), [string[]] @())
            @($all).Count | Should -Be 3
            $Script:Cache::GetByODataType('deviceCompliancePolicies', [string[]] @(), [string[]] @()) | Should -BeNullOrEmpty
        }

        It 'filters PSCustomObject items' {
            $items = [object[]] @([PSCustomObject] @{ id = '1'; '@odata.type' = '#microsoft.graph.iosCompliancePolicy' }, [PSCustomObject] @{ id = '2'; '@odata.type' = '#microsoft.graph.macOSCompliancePolicy' })
            $result = $Script:Cache::FilterByODataType($items, [string[]] @('microsoft.graph.macOSCompliancePolicy'), [string[]] @())
            @($result).id | Should -Be '2'
        }

        It 'keeps the first collection stored for a key' {
            $Script:Cache::Enable()
            $Script:Cache::TrySet('deviceConfigurations', [object[]] @(@{ id = '1' })) | Should -BeTrue
            $Script:Cache::TrySet('deviceConfigurations', [object[]] @(@{ id = '2' })) | Should -BeTrue
            $items = $null
            $null = $Script:Cache::TryGet('deviceConfigurations', [ref] $items)
            @($items).id | Should -Be '1'
        }

        It 'drops a collection after its last consumer is released' {
            $Script:Cache::Enable()
            $null = $Script:Cache::TrySet('deviceConfigurations', [object[]] @(@{ id = '1' }))
            $Script:Cache::RegisterConsumers('deviceConfigurations', 2)
            $Script:Cache::Release('deviceConfigurations') | Should -Be 1
            $Script:Cache::Keys | Should -Contain 'deviceConfigurations'
            $Script:Cache::Release('deviceConfigurations') | Should -Be 0
            $Script:Cache::Keys | Should -Not -Contain 'deviceConfigurations'
            $Script:Cache::Release('unknown') | Should -Be 0
        }

        It 'clears and disables on Reset' {
            $Script:Cache::Enable()
            $null = $Script:Cache::TrySet('deviceConfigurations', [object[]] @(@{ id = '1' }))
            $Script:Cache::Reset()
            $Script:Cache::IsEnabled | Should -BeFalse
            $Script:Cache::Keys.Count | Should -Be 0
        }
    }

    Context 'Get-M365DSCExportCachedCollection' {
        BeforeEach {
            Mock -ModuleName M365DSCIntuneUtil -CommandName Get-MgBetaDeviceManagementDeviceConfiguration -MockWith {
                return @(
                    @{ id = '1'; '@odata.type' = '#microsoft.graph.windowsKioskConfiguration' },
                    @{ id = '2'; '@odata.type' = '#microsoft.graph.windowsWifiConfiguration' },
                    @{ id = '3'; '@odata.type' = '#microsoft.graph.windowsWifiEnterpriseEAPConfiguration' }
                )
            }
            Mock -ModuleName M365DSCIntuneUtil -CommandName Get-MgBetaDeviceManagementDeviceEnrollmentConfiguration -MockWith {
                return @(
                    @{ id = '1'; '@odata.type' = '#microsoft.graph.deviceEnrollmentLimitConfiguration' },
                    @{ id = '2'; '@odata.type' = '#microsoft.graph.windows10EnrollmentCompletionPageConfiguration' }
                )
            }
        }

        It 'performs the isof request with assignments expanded while the cache is disabled' {
            $result = Get-M365DSCExportCachedCollection -Collection 'deviceConfigurations' -ODataType 'microsoft.graph.windowsKioskConfiguration'
            Should -Invoke -ModuleName M365DSCIntuneUtil -CommandName Get-MgBetaDeviceManagementDeviceConfiguration -Times 1 -Exactly -ParameterFilter {
                $Filter -eq "isof('microsoft.graph.windowsKioskConfiguration')" -and $ExpandProperty -contains 'assignments' -and $All
            }
            $result.Count | Should -Be 3
        }

        It 'builds the exclusion and multi-type filters' {
            $null = Get-M365DSCExportCachedCollection -Collection 'deviceConfigurations' -ODataType 'microsoft.graph.windowsWifiConfiguration' -ExcludeODataType 'microsoft.graph.windowsWifiEnterpriseEAPConfiguration'
            Should -Invoke -ModuleName M365DSCIntuneUtil -CommandName Get-MgBetaDeviceManagementDeviceConfiguration -Times 1 -Exactly -ParameterFilter {
                $Filter -eq "isof('microsoft.graph.windowsWifiConfiguration') and not isof('microsoft.graph.windowsWifiEnterpriseEAPConfiguration')"
            }
            $null = Get-M365DSCExportCachedCollection -Collection 'deviceConfigurations' -ODataType @('microsoft.graph.iosVpnConfiguration', 'microsoft.graph.iosikEv2VpnConfiguration')
            Should -Invoke -ModuleName M365DSCIntuneUtil -CommandName Get-MgBetaDeviceManagementDeviceConfiguration -Times 1 -Exactly -ParameterFilter {
                $Filter -eq "(isof('microsoft.graph.iosVpnConfiguration') or isof('microsoft.graph.iosikEv2VpnConfiguration'))"
            }
        }

        It 'merges a user filter and bypasses the cache' {
            [Microsoft365DSC.Intune.ExportCollectionCache]::Enable()
            $null = Get-M365DSCExportCachedCollection -Collection 'deviceConfigurations' -ODataType 'microsoft.graph.windowsKioskConfiguration' -Filter "displayName eq 'x'"
            Should -Invoke -ModuleName M365DSCIntuneUtil -CommandName Get-MgBetaDeviceManagementDeviceConfiguration -Times 1 -Exactly -ParameterFilter {
                $Filter -eq "(isof('microsoft.graph.windowsKioskConfiguration')) and (displayName eq 'x')"
            }
            [Microsoft365DSC.Intune.ExportCollectionCache]::ShouldPopulate('deviceConfigurations') | Should -BeTrue
        }

        It 'filters enrollment configurations client-side' {
            $result = Get-M365DSCExportCachedCollection -Collection 'deviceEnrollmentConfigurations' -ODataType 'microsoft.graph.deviceEnrollmentLimitConfiguration'
            Should -Invoke -ModuleName M365DSCIntuneUtil -CommandName Get-MgBetaDeviceManagementDeviceEnrollmentConfiguration -Times 1 -Exactly -ParameterFilter {
                $null -eq $Filter -and $ExpandProperty -contains 'assignments'
            }
            @($result).id | Should -Be '1'
        }

        It 'downloads once and serves later types from the cache' {
            [Microsoft365DSC.Intune.ExportCollectionCache]::Enable()
            $kiosk = Get-M365DSCExportCachedCollection -Collection 'deviceConfigurations' -ODataType 'microsoft.graph.windowsKioskConfiguration'
            $wifi = Get-M365DSCExportCachedCollection -Collection 'deviceConfigurations' -ODataType 'microsoft.graph.windowsWifiConfiguration' -ExcludeODataType 'microsoft.graph.windowsWifiEnterpriseEAPConfiguration'
            Should -Invoke -ModuleName M365DSCIntuneUtil -CommandName Get-MgBetaDeviceManagementDeviceConfiguration -Times 1 -Exactly -ParameterFilter {
                $null -eq $Filter -and $ExpandProperty -contains 'assignments'
            }
            @($kiosk).id | Should -Be '1'
            @($wifi).id | Should -Be '2'
        }

        It 'returns an empty array when nothing matches' {
            Mock -ModuleName M365DSCIntuneUtil -CommandName Get-MgBetaDeviceManagementDeviceConfiguration -MockWith { }
            $result = Get-M365DSCExportCachedCollection -Collection 'deviceConfigurations' -ODataType 'microsoft.graph.windowsKioskConfiguration'
            $result.Length | Should -Be 0
        }
    }

    Context 'Get-M365DSCIntuneExpandedAssignments' {
        It 'returns $null for missing input or missing assignments' {
            Get-M365DSCIntuneExpandedAssignments -Instance $null | Should -BeNullOrEmpty
            Get-M365DSCIntuneExpandedAssignments -Instance @{ id = '1' } | Should -BeNullOrEmpty
            Get-M365DSCIntuneExpandedAssignments -Instance ([PSCustomObject] @{ id = '1' }) | Should -BeNullOrEmpty
        }

        It 'returns $null when the expansion was truncated' {
            Get-M365DSCIntuneExpandedAssignments -Instance @{ assignments = @(@{ id = 'a' }); 'assignments@odata.nextLink' = 'x' } | Should -BeNullOrEmpty
        }

        It 'returns an empty array for an empty expansion' {
            $result = Get-M365DSCIntuneExpandedAssignments -Instance @{ assignments = @() }
            $null -eq $result | Should -BeFalse
            $result.Length | Should -Be 0
        }

        It 'returns the expanded assignments from hashtables and objects' {
            $fromHashtable = Get-M365DSCIntuneExpandedAssignments -Instance @{ assignments = @(@{ id = 'a' }, @{ id = 'b' }) }
            $fromHashtable.Count | Should -Be 2
            $fromObject = Get-M365DSCIntuneExpandedAssignments -Instance ([PSCustomObject] @{ Assignments = @(@{ id = 'a' }) })
            $fromObject.Count | Should -Be 1
        }
    }

    Context 'Export collection consumers' {
        It 'registers and releases consumers per collection' {
            [Microsoft365DSC.Intune.ExportCollectionCache]::Enable()
            Register-M365DSCExportCollectionConsumers -ResourceNames @('IntuneDeviceConfigurationKioskPolicyWindows10', 'IntuneDeviceEnrollmentLimitRestriction', 'AADUser')
            [Microsoft365DSC.Intune.ExportCollectionCache]::GetConsumerCount('deviceConfigurations') | Should -Be 1
            [Microsoft365DSC.Intune.ExportCollectionCache]::GetConsumerCount('deviceEnrollmentConfigurations') | Should -Be 1
            [Microsoft365DSC.Intune.ExportCollectionCache]::GetConsumerCount('deviceCompliancePolicies') | Should -Be 0
            Complete-M365DSCExportCollectionConsumer -ResourceName 'AADUser'
            [Microsoft365DSC.Intune.ExportCollectionCache]::GetConsumerCount('deviceConfigurations') | Should -Be 1
            Complete-M365DSCExportCollectionConsumer -ResourceName 'IntuneDeviceConfigurationKioskPolicyWindows10'
            [Microsoft365DSC.Intune.ExportCollectionCache]::Keys | Should -Not -Contain 'deviceConfigurations'
        }

        It 'initializes an enabled empty cache' {
            Initialize-M365DSCExportCollectionCache
            [Microsoft365DSC.Intune.ExportCollectionCache]::IsEnabled | Should -BeTrue
            Reset-M365DSCExportCollectionCache
            [Microsoft365DSC.Intune.ExportCollectionCache]::IsEnabled | Should -BeFalse
        }
    }
}
