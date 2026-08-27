<#
    Offline tests for the phase 2 comparison. Snapshots are built in memory, so no test reads
    the committed api-surface.json, the network or a tenant.
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\Utilities\ApiSurface\M365DSCApiSurface.psd1') -Force

InModuleScope -ModuleName 'M365DSCApiSurface' {

    BeforeAll {
        function New-TestProperty
        {
            param
            (
                [System.String] $Type = 'Edm.String',
                [System.Object[]] $Enum = @(),
                [System.Boolean] $IsArray = $false,
                [System.Boolean] $IsComplex = $false,
                [System.Boolean] $IsReadOnly = $false,
                [System.Boolean] $IsFlags = $false,
                [System.Boolean] $IsNavigation = $false
            )

            $entry = [ordered]@{ type = $Type }
            if ($Enum.Count -gt 0) { $entry['enum'] = $Enum; $entry['isFlags'] = $IsFlags }
            if ($IsComplex) { $entry['isComplex'] = $true }
            $entry['isArray'] = $IsArray
            $entry['isNavigation'] = $IsNavigation
            $entry['isReadOnly'] = $IsReadOnly
            $entry['isImmutable'] = $false

            return $entry
        }

        function New-TestSnapshot
        {
            param
            (
                [System.Collections.IDictionary] $GraphType = @{},
                [System.Collections.IDictionary] $Cmdlet = @{},
                [System.Collections.IDictionary] $Override = @{},
                [System.Collections.IDictionary] $Dependency = @{},
                [System.String[]] $SkippedWorkload = @(),
                [System.String[]] $SkippedModule = @()
            )

            return [ordered]@{
                formatVersion   = 1
                capturedAt      = '2026-08-27T00:00:00Z'
                capturedBy      = 'local'
                completeness    = [ordered]@{
                    tenantConnected  = $false
                    skippedWorkloads = $SkippedWorkload
                    skippedModules   = $SkippedModule
                }
                dependencies    = $Dependency
                graphTypes      = $GraphType
                cmdlets         = $Cmdlet
                cmdletOverrides = $Override
                shim            = [ordered]@{}
            }
        }

        function New-TestOrigin
        {
            param
            (
                [System.String] $Resource = 'TestPolicy',
                [System.String] $EntityType = 'testPolicy',
                [System.String] $ODataSubtype = '',
                [System.String] $ApiVersion = 'beta',
                [System.Boolean] $Navigation = $false,
                [System.Object[]] $Command = @()
            )

            return [PSCustomObject]@{
                Resource                    = $Resource
                Workload                    = 'MicrosoftGraph'
                ApiVersion                  = $ApiVersion
                EntityType                  = $EntityType
                ODataSubtype                = $ODataSubtype
                CmdletNoun                  = 'MgBetaTestPolicy'
                CmdletVerb                  = 'New'
                IncludeNavigationProperties = $Navigation
                Commands                    = $Command
            }
        }

        function New-TestKeyword
        {
            param
            (
                [System.String] $Resource = 'TestPolicy',
                [System.Collections.IDictionary] $Property = @{}
            )

            $properties = [ordered]@{}
            foreach ($name in $Property.Keys)
            {
                $definition = $Property[$name]
                $properties[$name] = [PSCustomObject]@{
                    typeConstraint = $definition.typeConstraint
                    values         = @($definition.values)
                    isKey          = [System.Boolean] $definition.isKey
                    name           = $name
                    mandatory      = $false
                }
            }

            return @{ $Resource = [PSCustomObject]@{ resourceName = $Resource; properties = [PSCustomObject] $properties } }
        }

        function Invoke-TestCompare
        {
            param
            (
                [System.Object] $Baseline,
                [System.Object] $Current,
                [System.Object[]] $Origin = @(),
                [System.Collections.IDictionary] $SchemaKeyword = @{},
                [System.Object] $Exclusion,
                [System.Collections.IDictionary] $ExcludedProperty = @{}
            )

            if ($null -eq $Baseline) { $Baseline = $Current }

            return Compare-M365DSCApiSurface -Baseline $Baseline `
                -Current $Current `
                -Origin $Origin `
                -SchemaKeyword $SchemaKeyword `
                -Exclusion $Exclusion `
                -ExcludedProperty $ExcludedProperty `
                -RunDate '2026-08-27'
        }

        $script:policyType = [ordered]@{
            'beta:testPolicy' = [ordered]@{
                kind       = 'EntityType'
                baseType   = 'entity'
                isAbstract = $false
                properties = [ordered]@{
                    displayName = New-TestProperty
                    state       = New-TestProperty -Type 'testState' -Enum @('disabled', 'enabled')
                }
            }
        }
    }

    Describe 'Compare-M365DSCApiSurface, vendor findings' {
        It 'reports nothing when a snapshot is compared to itself' {
            $snapshot = New-TestSnapshot -GraphType $script:policyType
            (Invoke-TestCompare -Current $snapshot).Findings | Should -HaveCount 0
        }

        It 'reports an added enum member' {
            $before = New-TestSnapshot -GraphType $script:policyType
            $after = New-TestSnapshot -GraphType ([ordered]@{
                    'beta:testPolicy' = [ordered]@{
                        kind       = 'EntityType'
                        baseType   = 'entity'
                        isAbstract = $false
                        properties = [ordered]@{
                            displayName = New-TestProperty
                            state       = New-TestProperty -Type 'testState' -Enum @('disabled', 'enabled', 'reportOnly')
                        }
                    }
                })

            $finding = @((Invoke-TestCompare -Baseline $before -Current $after).Findings | Where-Object { $_.code -eq 'VND-ENUM-MEMBER-ADDED' })
            $finding | Should -HaveCount 1
            $finding[0].to.added | Should -Be @('reportOnly')
            $finding[0].severity | Should -Be 'warning'
        }

        It 'reports an added type property' {
            $before = New-TestSnapshot -GraphType $script:policyType
            $after = New-TestSnapshot -GraphType ([ordered]@{
                    'beta:testPolicy' = [ordered]@{
                        kind       = 'EntityType'
                        baseType   = 'entity'
                        isAbstract = $false
                        properties = [ordered]@{
                            displayName = New-TestProperty
                            state       = New-TestProperty -Type 'testState' -Enum @('disabled', 'enabled')
                            newFlag     = New-TestProperty -Type 'Edm.Boolean'
                        }
                    }
                })

            $finding = @((Invoke-TestCompare -Baseline $before -Current $after).Findings | Where-Object { $_.code -eq 'VND-TYPE-PROP-ADDED' })
            $finding | Should -HaveCount 1
            $finding[0].id | Should -Be 'VND-TYPE-PROP-ADDED:beta:testPolicy:newFlag'
        }

        It 'reports a cmdlet that disappeared and names its callers' {
            $cmdlet = [ordered]@{
                'Get-MgBetaTestPolicy' = [ordered]@{
                    workload = 'MicrosoftGraph'; module = 'Microsoft.Graph.Beta.Test'; moduleVersion = '2.35.1'
                    apiVersion = 'beta'; variants = @(); parameters = [ordered]@{}
                }
            }
            $before = New-TestSnapshot -Cmdlet $cmdlet
            $after = New-TestSnapshot

            $origin = @(New-TestOrigin -Command @([PSCustomObject]@{ Module = 'Microsoft.Graph.Beta.Test'; Name = 'Get-MgBetaTestPolicy' }))
            $finding = @((Invoke-TestCompare -Baseline $before -Current $after -Origin $origin).Findings | Where-Object { $_.code -eq 'VND-CMDLET-REMOVED' })

            $finding | Should -HaveCount 1
            $finding[0].severity | Should -Be 'breaking'
            $finding[0].evidence.calledBy | Should -Be @('TestPolicy')
        }

        It 'reports a route that moved within its own API version' {
            $before = New-TestSnapshot -Cmdlet ([ordered]@{
                    'Get-MgBetaTestPolicy' = [ordered]@{
                        workload = 'MicrosoftGraph'; module = 'M'; moduleVersion = '1.0'; apiVersion = 'beta'
                        variants = @([ordered]@{ method = 'GET'; uri = '/old'; apiVersion = 'beta' }); parameters = [ordered]@{}
                    }
                })
            $after = New-TestSnapshot -Cmdlet ([ordered]@{
                    'Get-MgBetaTestPolicy' = [ordered]@{
                        workload = 'MicrosoftGraph'; module = 'M'; moduleVersion = '1.0'; apiVersion = 'beta'
                        variants = @([ordered]@{ method = 'GET'; uri = '/new'; apiVersion = 'beta' }); parameters = [ordered]@{}
                    }
                })

            @((Invoke-TestCompare -Baseline $before -Current $after).Findings | Where-Object { $_.code -eq 'VND-CMDLET-REROUTED' }) | Should -HaveCount 1
        }

        It 'reports nothing when the moved route matches a shim override' {
            $before = New-TestSnapshot -Cmdlet ([ordered]@{
                    'Get-MgBetaTestPolicy' = [ordered]@{
                        workload = 'MicrosoftGraph'; module = 'M'; moduleVersion = '1.0'; apiVersion = 'beta'
                        variants = @([ordered]@{ method = 'POST'; uri = '/thing'; apiVersion = 'beta' }); parameters = [ordered]@{}
                    }
                })
            $after = New-TestSnapshot -Cmdlet ([ordered]@{
                    'Get-MgBetaTestPolicy' = [ordered]@{
                        workload = 'MicrosoftGraph'; module = 'M'; moduleVersion = '1.0'; apiVersion = 'beta'
                        variants = @([ordered]@{ method = 'GET'; uri = '/thing'; apiVersion = 'beta' }); parameters = [ordered]@{}
                    }
                }) -Override ([ordered]@{
                    'Get-MgBetaTestPolicy' = [ordered]@{
                        reason = 'The beta endpoint answers GET.'
                        variants = @([ordered]@{ method = 'POST'; uri = '/thing'; apiVersion = 'beta' })
                    }
                })

            @((Invoke-TestCompare -Baseline $before -Current $after).Findings | Where-Object { $_.code -eq 'VND-CMDLET-REROUTED' }) | Should -HaveCount 0
        }

        It 'reports nothing when a v1.0 route appears beside the beta route' {
            $before = New-TestSnapshot -Cmdlet ([ordered]@{
                    'Get-MgBetaTestPolicy' = [ordered]@{
                        workload = 'MicrosoftGraph'; module = 'M'; moduleVersion = '1.0'; apiVersion = 'beta'
                        variants = @([ordered]@{ method = 'GET'; uri = '/thing'; apiVersion = 'beta' }); parameters = [ordered]@{}
                    }
                })
            $after = New-TestSnapshot -Cmdlet ([ordered]@{
                    'Get-MgBetaTestPolicy' = [ordered]@{
                        workload = 'MicrosoftGraph'; module = 'M'; moduleVersion = '1.0'; apiVersion = 'beta'
                        variants = @(
                            [ordered]@{ method = 'GET'; uri = '/thing'; apiVersion = 'beta' }
                            [ordered]@{ method = 'GET'; uri = '/thing'; apiVersion = 'v1.0' }
                        ); parameters = [ordered]@{}
                    }
                })

            (Invoke-TestCompare -Baseline $before -Current $after).Findings | Should -HaveCount 0
        }

        It 'reports an added parameter and a changed parameter type' {
            $before = New-TestSnapshot -Cmdlet ([ordered]@{
                    'Set-CsTestThing' = [ordered]@{
                        workload = 'MicrosoftTeams'; module = 'MicrosoftTeams'; moduleVersion = '7.6.0'; apiVersion = $null
                        variants = @(); parameters = [ordered]@{ Identity = 'System.String' }
                    }
                })
            $after = New-TestSnapshot -Cmdlet ([ordered]@{
                    'Set-CsTestThing' = [ordered]@{
                        workload = 'MicrosoftTeams'; module = 'MicrosoftTeams'; moduleVersion = '7.9.0'; apiVersion = $null
                        variants = @(); parameters = [ordered]@{ Identity = 'System.Guid'; Tags = 'System.String[]' }
                    }
                })

            $findings = (Invoke-TestCompare -Baseline $before -Current $after).Findings
            @($findings | Where-Object { $_.code -eq 'VND-PARAM-ADDED' }) | Should -HaveCount 1
            $typeChanged = @($findings | Where-Object { $_.code -eq 'VND-PARAM-TYPECHANGED' })
            $typeChanged | Should -HaveCount 1
            $typeChanged[0].severity | Should -Be 'breaking'
        }

        It 'reports nothing for a module the run could not look at' {
            $before = New-TestSnapshot -Cmdlet ([ordered]@{
                    'Get-Mailbox' = [ordered]@{
                        workload = 'ExchangeOnline'; module = 'ExchangeOnlineManagement'; moduleVersion = '3.9.2'
                        apiVersion = $null; variants = @(); parameters = [ordered]@{}
                    }
                })
            $after = New-TestSnapshot -SkippedWorkload @('ExchangeOnline') -SkippedModule @('ExchangeOnlineManagement')

            (Invoke-TestCompare -Baseline $before -Current $after).Findings | Should -HaveCount 0
        }

        It 'groups a newer dependency version by the size of the jump' {
            $snapshot = New-TestSnapshot -Dependency ([ordered]@{
                    'Az.Resources'   = [ordered]@{ pinned = '9.0.1'; manifests = @('Manifest'); latestPublished = '10.1.0' }
                    'MicrosoftTeams' = [ordered]@{ pinned = '7.6.0'; manifests = @('Manifest'); latestPublished = '7.9.0' }
                    'PnP.PowerShell' = [ordered]@{ pinned = '3.3.0'; manifests = @('Manifest'); latestPublished = '3.3.1' }
                    'Pinned.Current' = [ordered]@{ pinned = '1.0.0'; manifests = @('Manifest'); latestPublished = '1.0.0' }
                })

            $findings = @((Invoke-TestCompare -Current $snapshot).Findings | Where-Object { $_.code -eq 'VND-NEWER-VERSION' })
            $findings | Should -HaveCount 3
            ($findings | Where-Object { $_.id -eq 'VND-NEWER-VERSION:Az.Resources' }).to.jump | Should -Be 'Major'
            ($findings | Where-Object { $_.id -eq 'VND-NEWER-VERSION:MicrosoftTeams' }).to.jump | Should -Be 'Minor'
            ($findings | Where-Object { $_.id -eq 'VND-NEWER-VERSION:PnP.PowerShell' }).to.jump | Should -Be 'Patch'
        }
    }

    Describe 'Compare-M365DSCApiSurface, resource findings' {
        It 'reports a property the resource declares and the vendor does not have' {
            $snapshot = New-TestSnapshot -GraphType $script:policyType
            $keyword = New-TestKeyword -Property @{
                DisplayName = @{ typeConstraint = 'String' }
                Invented    = @{ typeConstraint = 'String' }
            }

            $finding = @((Invoke-TestCompare -Current $snapshot -Origin @(New-TestOrigin) -SchemaKeyword $keyword).Findings |
                    Where-Object { $_.code -eq 'RES-PROP-ORPHANED' })

            $finding | Should -HaveCount 1
            $finding[0].property | Should -Be 'Invented'
            $finding[0].severity | Should -Be 'breaking'
        }

        It 'reports nothing for a property undeclared in both snapshots' {
            $snapshot = New-TestSnapshot -GraphType $script:policyType
            $keyword = New-TestKeyword -Property @{ DisplayName = @{ typeConstraint = 'String' } }

            $result = Invoke-TestCompare -Current $snapshot -Origin @(New-TestOrigin) -SchemaKeyword $keyword
            @($result.Findings | Where-Object { $_.code -eq 'RES-PROP-MISSING' }) | Should -HaveCount 0
            $result.Backlog | Should -Be 1
        }

        It 'reports a property that appeared since the baseline' {
            $before = New-TestSnapshot -GraphType $script:policyType
            $after = New-TestSnapshot -GraphType ([ordered]@{
                    'beta:testPolicy' = [ordered]@{
                        kind = 'EntityType'; baseType = 'entity'; isAbstract = $false
                        properties = [ordered]@{
                            displayName = New-TestProperty
                            state       = New-TestProperty -Type 'testState' -Enum @('disabled', 'enabled')
                            newFlag     = New-TestProperty -Type 'Edm.Boolean'
                        }
                    }
                })
            $keyword = New-TestKeyword -Property @{
                DisplayName = @{ typeConstraint = 'String' }
                State       = @{ typeConstraint = 'String'; values = @('disabled', 'enabled') }
            }

            $finding = @((Invoke-TestCompare -Baseline $before -Current $after -Origin @(New-TestOrigin) -SchemaKeyword $keyword).Findings |
                    Where-Object { $_.code -eq 'RES-PROP-MISSING' })

            $finding | Should -HaveCount 1
            $finding[0].property | Should -Be 'NewFlag'
            $finding[0].autoFixable | Should -BeTrue
        }

        It 'marks a new complex property as not auto-fixable' {
            $before = New-TestSnapshot -GraphType $script:policyType
            $after = New-TestSnapshot -GraphType ([ordered]@{
                    'beta:testPolicy'    = [ordered]@{
                        kind = 'EntityType'; baseType = 'entity'; isAbstract = $false
                        properties = [ordered]@{
                            displayName = New-TestProperty
                            state       = New-TestProperty -Type 'testState' -Enum @('disabled', 'enabled')
                            conditions  = New-TestProperty -Type 'testConditionSet' -IsComplex $true
                        }
                    }
                    'beta:testConditionSet' = [ordered]@{
                        kind = 'ComplexType'; baseType = $null; isAbstract = $false
                        properties = [ordered]@{ includeUsers = New-TestProperty -IsArray $true }
                    }
                })
            $keyword = New-TestKeyword -Property @{
                DisplayName = @{ typeConstraint = 'String' }
                State       = @{ typeConstraint = 'String'; values = @('disabled', 'enabled') }
            }

            $finding = @((Invoke-TestCompare -Baseline $before -Current $after -Origin @(New-TestOrigin) -SchemaKeyword $keyword).Findings |
                    Where-Object { $_.code -eq 'RES-PROP-MISSING' -and $_.property -eq 'Conditions' })

            $finding | Should -HaveCount 1
            $finding[0].autoFixable | Should -BeFalse
        }

        It 'reports a new read-only property as read-only rather than missing' {
            $before = New-TestSnapshot -GraphType $script:policyType
            $after = New-TestSnapshot -GraphType ([ordered]@{
                    'beta:testPolicy' = [ordered]@{
                        kind = 'EntityType'; baseType = 'entity'; isAbstract = $false
                        properties = [ordered]@{
                            displayName = New-TestProperty
                            state       = New-TestProperty -Type 'testState' -Enum @('disabled', 'enabled')
                            createdOn   = New-TestProperty -Type 'Edm.DateTimeOffset' -IsReadOnly $true
                        }
                    }
                })
            $keyword = New-TestKeyword -Property @{
                DisplayName = @{ typeConstraint = 'String' }
                State       = @{ typeConstraint = 'String'; values = @('disabled', 'enabled') }
            }

            $findings = (Invoke-TestCompare -Baseline $before -Current $after -Origin @(New-TestOrigin) -SchemaKeyword $keyword).Findings
            @($findings | Where-Object { $_.code -eq 'RES-PROP-READONLY' }) | Should -HaveCount 1
            @($findings | Where-Object { $_.code -eq 'RES-PROP-MISSING' }) | Should -HaveCount 0
        }

        It 'resolves a property the resource flattened out of a complex type' {
            $snapshot = New-TestSnapshot -GraphType ([ordered]@{
                    'beta:testPolicy'    = [ordered]@{
                        kind = 'EntityType'; baseType = 'entity'; isAbstract = $false
                        properties = [ordered]@{ conditions = New-TestProperty -Type 'testConditionSet' -IsComplex $true }
                    }
                    'beta:testConditionSet' = [ordered]@{
                        kind = 'ComplexType'; baseType = $null; isAbstract = $false
                        properties = [ordered]@{ includeUsers = New-TestProperty -IsArray $true }
                    }
                })
            $keyword = New-TestKeyword -Property @{ IncludeUsers = @{ typeConstraint = 'StringArray' } }

            @((Invoke-TestCompare -Current $snapshot -Origin @(New-TestOrigin) -SchemaKeyword $keyword).Findings |
                    Where-Object { $_.code -eq 'RES-PROP-ORPHANED' }) | Should -HaveCount 0
        }

        It 'reports a typeConstraint that disagrees with the vendor type' {
            $snapshot = New-TestSnapshot -GraphType ([ordered]@{
                    'beta:testPolicy' = [ordered]@{
                        kind = 'EntityType'; baseType = 'entity'; isAbstract = $false
                        properties = [ordered]@{ retryCount = New-TestProperty -Type 'Edm.Int32' }
                    }
                })
            $keyword = New-TestKeyword -Property @{ RetryCount = @{ typeConstraint = 'String' } }

            $finding = @((Invoke-TestCompare -Current $snapshot -Origin @(New-TestOrigin) -SchemaKeyword $keyword).Findings |
                    Where-Object { $_.code -eq 'RES-TYPE-MISMATCH' })

            $finding | Should -HaveCount 1
            $finding[0].severity | Should -Be 'breaking'
        }

        It 'accepts an array constraint on a flags enum' {
            $snapshot = New-TestSnapshot -GraphType ([ordered]@{
                    'beta:testPolicy' = [ordered]@{
                        kind = 'EntityType'; baseType = 'entity'; isAbstract = $false
                        properties = [ordered]@{ scope = New-TestProperty -Type 'testScope' -Enum @('a', 'b') -IsFlags $true }
                    }
                })
            $keyword = New-TestKeyword -Property @{ Scope = @{ typeConstraint = 'StringArray'; values = @('a', 'b') } }

            @((Invoke-TestCompare -Current $snapshot -Origin @(New-TestOrigin) -SchemaKeyword $keyword).Findings |
                    Where-Object { $_.code -eq 'RES-TYPE-MISMATCH' }) | Should -HaveCount 0
        }

        It 'reports a ValidateSet that is a strict subset of the vendor enum' {
            $snapshot = New-TestSnapshot -GraphType $script:policyType
            $keyword = New-TestKeyword -Property @{
                DisplayName = @{ typeConstraint = 'String' }
                State       = @{ typeConstraint = 'String'; values = @('enabled') }
            }

            $finding = @((Invoke-TestCompare -Current $snapshot -Origin @(New-TestOrigin) -SchemaKeyword $keyword).Findings |
                    Where-Object { $_.code -eq 'RES-ENUM-STALE' })

            $finding | Should -HaveCount 1
            $finding[0].to.added | Should -Be @('disabled')
            $finding[0].autoFixable | Should -BeTrue
        }

        It 'reports nothing for a resource on a non-comparable entity type' {
            $snapshot = New-TestSnapshot -GraphType ([ordered]@{
                    'beta:deviceManagementConfigurationPolicy' = [ordered]@{
                        kind = 'EntityType'; baseType = 'entity'; isAbstract = $false
                        properties = [ordered]@{ name = New-TestProperty }
                    }
                })
            $origin = @(New-TestOrigin -Resource 'IntuneCatalog' -EntityType 'deviceManagementConfigurationPolicy')
            $keyword = New-TestKeyword -Resource 'IntuneCatalog' -Property @{ Invented = @{ typeConstraint = 'String' } }
            $exclusion = [PSCustomObject]@{
                nonComparableEntityTypes = @([PSCustomObject]@{ entityType = 'deviceManagementConfigurationPolicy'; reason = 'settings catalog' })
            }

            $result = Invoke-TestCompare -Current $snapshot -Origin $origin -SchemaKeyword $keyword -Exclusion $exclusion
            $result.Findings | Should -HaveCount 0
            $result.Summary.compared | Should -Be 0
            $result.Summary.skipped | Should -Be 1
            $result.Coverage[0].reason | Should -BeLike '*is served by another surface*'
        }

        It 'reports nothing for a resource with no resolved entityType' {
            $snapshot = New-TestSnapshot -GraphType $script:policyType
            $origin = @(New-TestOrigin -Resource 'RestOnly' -EntityType '')

            $result = Invoke-TestCompare -Current $snapshot -Origin $origin
            $result.Findings | Should -HaveCount 0
            $result.Coverage[0].reason | Should -Be 'no resolved entityType'
        }

        It 'suppresses a finding on an excluded property' {
            $snapshot = New-TestSnapshot -GraphType $script:policyType
            $keyword = New-TestKeyword -Property @{
                DisplayName = @{ typeConstraint = 'String' }
                Invented    = @{ typeConstraint = 'String' }
            }
            $excluded = @{ TestPolicy = @([PSCustomObject]@{ name = 'Invented'; reason = 'NotConfigurable' }) }

            (Invoke-TestCompare -Current $snapshot -Origin @(New-TestOrigin) -SchemaKeyword $keyword -ExcludedProperty $excluded).Findings |
                Should -HaveCount 0
        }

        It 'keeps a Deferred exclusion visible at info' {
            $snapshot = New-TestSnapshot -GraphType $script:policyType
            $keyword = New-TestKeyword -Property @{
                DisplayName = @{ typeConstraint = 'String' }
                Invented    = @{ typeConstraint = 'String' }
            }
            $excluded = @{ TestPolicy = @([PSCustomObject]@{ name = 'Invented'; reason = 'Deferred' }) }

            $findings = (Invoke-TestCompare -Current $snapshot -Origin @(New-TestOrigin) -SchemaKeyword $keyword -ExcludedProperty $excluded).Findings
            $findings | Should -HaveCount 1
            $findings[0].severity | Should -Be 'info'
        }
    }

    Describe 'Finding identity' {
        It 'produces the same ids twice over identical input' {
            $snapshot = New-TestSnapshot -GraphType $script:policyType
            $keyword = New-TestKeyword -Property @{ DisplayName = @{ typeConstraint = 'String' }; Invented = @{ typeConstraint = 'String' } }

            $first = (Invoke-TestCompare -Current $snapshot -Origin @(New-TestOrigin) -SchemaKeyword $keyword).Findings.id
            $second = (Invoke-TestCompare -Current $snapshot -Origin @(New-TestOrigin) -SchemaKeyword $keyword).Findings.id

            Compare-Object -ReferenceObject $first -DifferenceObject $second | Should -BeNullOrEmpty
        }

        It 'orders findings by id' {
            $snapshot = New-TestSnapshot -Dependency ([ordered]@{
                    'Zeta.Module'  = [ordered]@{ pinned = '1.0.0'; manifests = @('Manifest'); latestPublished = '2.0.0' }
                    'Alpha.Module' = [ordered]@{ pinned = '1.0.0'; manifests = @('Manifest'); latestPublished = '2.0.0' }
                })

            $ids = (Invoke-TestCompare -Current $snapshot).Findings.id
            $ids | Should -Be @('VND-NEWER-VERSION:Alpha.Module', 'VND-NEWER-VERSION:Zeta.Module')
        }

        It 'carries firstSeen forward for a finding that was already reported' {
            $snapshot = New-TestSnapshot -Dependency ([ordered]@{
                    'Az.Resources' = [ordered]@{ pinned = '9.0.1'; manifests = @('Manifest'); latestPublished = '10.1.0' }
                })
            $previous = @([PSCustomObject]@{ id = 'VND-NEWER-VERSION:Az.Resources'; firstSeen = '2026-01-01' })

            $findings = (Compare-M365DSCApiSurface -Baseline $snapshot -Current $snapshot -PreviousFinding $previous -RunDate '2026-08-27').Findings
            $findings[0].firstSeen | Should -Be '2026-01-01'
        }

        It 'stamps the run date on a finding seen for the first time' {
            $snapshot = New-TestSnapshot -Dependency ([ordered]@{
                    'Az.Resources' = [ordered]@{ pinned = '9.0.1'; manifests = @('Manifest'); latestPublished = '10.1.0' }
                })

            (Invoke-TestCompare -Current $snapshot).Findings[0].firstSeen | Should -Be '2026-08-27'
        }

        It 'throws on a finding code that is not in the table' {
            { Resolve-FindingSeverity -Code 'VND-INVENTED' } | Should -Throw
        }
    }

    Describe 'Resolve-PropertyName' {
        BeforeAll {
            $script:vendor = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
            $script:vendor['displayName'] = [ordered]@{ Name = 'displayName'; Path = 'displayName' }
            $script:vendor['@odata.type'] = [ordered]@{ Name = '@odata.type'; Path = '@odata.type' }
            $script:vendor['mdmAuthority'] = [ordered]@{ Name = 'mdmAuthority'; Path = 'mdmAuthority' }
            $script:vendor['isEnabled'] = [ordered]@{ Name = 'isEnabled'; Path = 'signInFrequency.isEnabled' }
        }

        It 'matches <Name> by the <Rule> rule' -TestCases @(
            @{ Name = 'DisplayName'; Rule = 'Camel' }
            @{ Name = 'ODataType'; Rule = 'ODataType' }
            @{ Name = 'MDMAuthority'; Rule = 'Acronym' }
            @{ Name = 'SignInFrequencyIsEnabled'; Rule = 'FlattenedPath' }
        ) {
            $result = Resolve-PropertyName -Name $Name -VendorProperty $script:vendor
            $result.Matched | Should -BeTrue
            $result.Rule | Should -Be $Rule
        }

        It 'reports no match for a name the vendor does not have' {
            (Resolve-PropertyName -Name 'Invented' -VendorProperty $script:vendor).Matched | Should -BeFalse
        }
    }

    Describe 'Expand-VendorPropertySet' {
        It 'admits the members of a referenced complex type' {
            $types = [ordered]@{
                'beta:a' = [ordered]@{ properties = [ordered]@{ nested = New-TestProperty -Type 'b' -IsComplex $true } }
                'beta:b' = [ordered]@{ properties = [ordered]@{ leaf = New-TestProperty } }
            }

            $result = Expand-VendorPropertySet -GraphType $types -ApiVersion 'beta' -TypeName 'a'
            $result.Properties.Contains('leaf') | Should -BeTrue
            $result.Properties['leaf'].Path | Should -Be 'nested.leaf'
            $result.TopLevelCount | Should -Be 1
        }

        It 'leaves a navigation property out unless the resource asks for it' {
            $types = [ordered]@{
                'beta:a' = [ordered]@{ properties = [ordered]@{ owners = New-TestProperty -Type 'b' -IsComplex $true -IsNavigation $true } }
            }

            (Expand-VendorPropertySet -GraphType $types -ApiVersion 'beta' -TypeName 'a').Properties.Contains('owners') | Should -BeFalse
            (Expand-VendorPropertySet -GraphType $types -ApiVersion 'beta' -TypeName 'a' -IncludeNavigationProperties $true).Properties.Contains('owners') | Should -BeTrue
        }

        It 'stops at a self-referencing complex type' {
            $types = [ordered]@{
                'beta:a' = [ordered]@{ properties = [ordered]@{ self = New-TestProperty -Type 'a' -IsComplex $true } }
            }

            { Expand-VendorPropertySet -GraphType $types -ApiVersion 'beta' -TypeName 'a' } | Should -Not -Throw
        }

        It 'reports that the walk was truncated' {
            $types = [ordered]@{
                'beta:a' = [ordered]@{ properties = [ordered]@{ n = New-TestProperty -Type 'b' -IsComplex $true } }
                'beta:b' = [ordered]@{ properties = [ordered]@{ n = New-TestProperty -Type 'c' -IsComplex $true } }
                'beta:c' = [ordered]@{ properties = [ordered]@{ leaf = New-TestProperty } }
            }

            (Expand-VendorPropertySet -GraphType $types -ApiVersion 'beta' -TypeName 'a' -MaxDepth 1).Truncated | Should -BeTrue
        }
    }

    Describe 'Report rendering' {
        BeforeAll {
            $script:snapshot = New-TestSnapshot -GraphType $script:policyType -Dependency ([ordered]@{
                    'Az.Resources' = [ordered]@{ pinned = '9.0.1'; manifests = @('Manifest'); latestPublished = '10.1.0' }
                })
            $script:keyword = New-TestKeyword -Property @{
                DisplayName = @{ typeConstraint = 'String' }
                State       = @{ typeConstraint = 'String'; values = @('enabled') }
                Invented    = @{ typeConstraint = 'String' }
            }
            $script:result = Invoke-TestCompare -Current $script:snapshot -Origin @(New-TestOrigin) -SchemaKeyword $script:keyword
        }

        It 'renders the same Markdown twice' {
            (Format-DriftMarkdown -Result $script:result) | Should -BeExactly (Format-DriftMarkdown -Result $script:result)
        }

        It 'renders the same Issue body twice' {
            (Format-DriftIssueBody -Result $script:result) | Should -BeExactly (Format-DriftIssueBody -Result $script:result)
        }

        It 'states a count on every section even when it is empty' {
            $body = Format-DriftIssueBody -Result $script:result
            $body | Should -Match '## Read-only, suggested for no implementation  \(0\)'
        }

        It 'groups the dependency section by jump size' {
            (Format-DriftMarkdown -Result $script:result) | Should -Match 'Major \(1\)'
        }

        It 'round trips the ticked ids out of an Issue body' {
            $ids = @($script:result.Findings | Where-Object { $_.autoFixable } | ForEach-Object { $_.id })
            $ids.Count | Should -BeGreaterThan 0

            $body = Format-DriftIssueBody -Result $script:result -Ticked $ids
            Get-DriftIssueTicked -Body $body | Should -Be $ids
        }

        It 'leaves an unticked body parsing to nothing' {
            Get-DriftIssueTicked -Body (Format-DriftIssueBody -Result $script:result) | Should -HaveCount 0
        }

        It 'carries no timestamp into the Issue body' {
            Format-DriftIssueBody -Result $script:result | Should -Not -Match '\d{4}-\d{2}-\d{2}T'
        }
    }
}
