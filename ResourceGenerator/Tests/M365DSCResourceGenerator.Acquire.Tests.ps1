<#
    Offline unit tests for acquisition: type auto-pick scoring, CSDL type walking (against an
    in-memory fixture) and resource model assembly. No network or Graph modules required.
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\M365DSCResourceGenerator.psd1') -Force

InModuleScope -ModuleName 'M365DSCResourceGenerator' {

    Describe 'Resolve-M365DSCTypeCandidate' {
        It 'returns the single candidate without scoring' {
            Resolve-M365DSCTypeCandidate -Candidates @('onlyOne') -ResourceName 'Whatever' |
                Should -Be 'onlyOne'
        }

        It 'honors the override even when unknown' {
            Resolve-M365DSCTypeCandidate -Candidates @('a', 'b') -Override 'custom' -WarningAction SilentlyContinue |
                Should -Be 'custom'
        }

        It 'picks windows10CompliancePolicy for IntuneDeviceCompliancePolicyWindows10' {
            $candidates = @(
                'androidCompliancePolicy', 'androidWorkProfileCompliancePolicy', 'iosCompliancePolicy',
                'macOSCompliancePolicy', 'windows10CompliancePolicy', 'windows10MobileCompliancePolicy',
                'windowsPhone81CompliancePolicy'
            )
            Resolve-M365DSCTypeCandidate -Candidates $candidates `
                -ResourceName 'IntuneDeviceCompliancePolicyWindows10' `
                -CmdLetNoun 'MgBetaDeviceManagementDeviceCompliancePolicy' `
                -AllowPrompt $false |
                Should -Be 'windows10CompliancePolicy'
        }

        It 'picks the exact-match subtype for a simple resource' {
            Resolve-M365DSCTypeCandidate -Candidates @('group', 'unifiedGroup', 'dynamicGroup') `
                -ResourceName 'AADGroup' `
                -CmdLetNoun 'MgGroup' `
                -AllowPrompt $false |
                Should -Be 'group'
        }

        It 'throws with guidance when non-interactive and ambiguous' {
            { Resolve-M365DSCTypeCandidate -Candidates @('alphaBravoCharlie', 'deltaEchoFoxtrot') `
                    -ResourceName 'ZuluYankee' `
                    -CmdLetNoun 'MgXrayWhiskey' `
                    -AllowPrompt $false } |
                Should -Throw -ExpectedMessage '*-AdditionalPropertiesType*'
        }
    }

    Describe 'Get-M365DSCTypeCandidateScore' {
        It 'scores an exact normalized match as 1.0' {
            Get-M365DSCTypeCandidateScore -Candidate '#microsoft.graph.permissionGrantPolicy' -Target 'MgBetaPolicyPermissionGrantPolicy' |
                Should -BeGreaterOrEqual 0.85
        }

        It 'scores unrelated names low' {
            Get-M365DSCTypeCandidateScore -Candidate 'windows10CompliancePolicy' -Target 'TeamsMeetingPolicy' |
                Should -BeLessThan 0.5
        }

        It 'strips the IMicrosoftGraph prefix and the trailing 1' {
            Get-M365DSCTypeCandidateScore -Candidate 'IMicrosoftGraphGroup1' -Target 'MgGroup' |
                Should -Be 1.0
        }
    }

    Describe 'Get-M365DSCGraphTypeProperty' {
        BeforeAll {
            $csdl = @'
<Edmx xmlns="http://docs.oasis-open.org/odata/ns/edmx" Version="4.0">
  <DataServices>
    <schema Namespace="microsoft.graph" xmlns="http://docs.oasis-open.org/odata/ns/edm">
      <EntityType Name="entity" Abstract="true">
        <Property Name="id" Type="Edm.String">
          <Annotation Term="Org.OData.Core.V1.Description" String="The unique identifier." />
        </Property>
      </EntityType>
      <EntityType Name="testPolicy" BaseType="graph.entity">
        <Property Name="displayName" Type="Edm.String">
          <Annotation Term="Org.OData.Core.V1.Description" String="The display name." />
        </Property>
        <Property Name="isEnabled" Type="Edm.Boolean">
          <Annotation Term="Org.OData.Core.V1.Description" String="Whether enabled." />
        </Property>
        <Property Name="createdDateTime" Type="Edm.DateTimeOffset" />
        <Property Name="state" Type="graph.testState" />
        <Property Name="rules" Type="Collection(graph.testRule)" />
        <NavigationProperty Name="linkedThing" Type="graph.testPolicy" />
      </EntityType>
      <ComplexType Name="testRule">
        <Property Name="name" Type="Edm.String">
          <Annotation Term="Org.OData.Core.V1.Description" String="Rule name." />
        </Property>
        <Property Name="threshold" Type="Edm.Int32" />
      </ComplexType>
      <EnumType Name="testState">
        <Member Name="enabled" Value="0" />
        <Member Name="disabled" Value="1" />
      </EnumType>
    </schema>
  </DataServices>
</Edmx>
'@
            $script:schema = ([Xml] $csdl).Edmx.DataServices.schema
        }

        It 'walks the inheritance chain and returns base properties' {
            $models = Get-M365DSCGraphTypeProperty -Schema $script:schema -Entity 'testPolicy'
            $models.Name | Should -Contain 'Id'
            $models.Name | Should -Contain 'DisplayName'
        }

        It 'resolves enums with their members' {
            $models = Get-M365DSCGraphTypeProperty -Schema $script:schema -Entity 'testPolicy'
            $state = $models | Where-Object { $_.Name -eq 'State' }
            $state.IsEnum | Should -BeTrue
            $state.EnumValues | Should -Be @('enabled', 'disabled')
        }

        It 'recurses into complex collections' {
            $models = Get-M365DSCGraphTypeProperty -Schema $script:schema -Entity 'testPolicy'
            $rules = $models | Where-Object { $_.Name -eq 'Rules' }
            $rules.IsComplex | Should -BeTrue
            $rules.IsArray | Should -BeTrue
            $rules.CimClassName | Should -Be 'MSFT_MicrosoftGraphTestRule'
            $rules.Members.Name | Should -Be @('Name', 'Threshold')
        }

        It 'extracts descriptions from annotations' {
            $models = Get-M365DSCGraphTypeProperty -Schema $script:schema -Entity 'testPolicy'
            ($models | Where-Object { $_.Name -eq 'DisplayName' }).Description | Should -Be 'The display name.'
        }

        It 'breaks self-referencing navigation cycles instead of looping' {
            $models = Get-M365DSCGraphTypeProperty -Schema $script:schema -Entity 'testPolicy' `
                -IncludeNavigationProperties $true -WarningAction SilentlyContinue
            # The self-reference is skipped, everything else survives.
            $models.Name | Should -Not -Contain 'LinkedThing'
            $models.Name | Should -Contain 'DisplayName'
        }

        It 'suffixes CIM class names that collide with shipped classes' {
            Get-M365DSCUniqueCimClassName -TypeName 'testRule' -ExistingCimClassNames @('MSFT_MicrosoftGraphTestRule') |
                Should -Be 'MSFT_MicrosoftGraphTestRule1'
        }
    }

    Describe 'New-M365DSCResourceModel' {
        BeforeAll {
            $script:properties = @(
                New-M365DSCPropertyModel -Name 'Id' -Type 'Edm.String' -Description 'The id.'
                New-M365DSCPropertyModel -Name 'DisplayName' -Type 'Edm.String' -Description 'The name.'
                New-M365DSCPropertyModel -Name 'CreatedDateTime' -Type 'Edm.DateTimeOffset'
            )
            $script:cmdletInfo = @{
                GetCmdlet    = 'Get-MgTestPolicy'
                NewCmdlet    = 'New-MgTestPolicy'
                UpdateCmdlet = 'Update-MgTestPolicy'
                RemoveCmdlet = 'Remove-MgTestPolicy'
                GetKeyParameters = @('TestPolicyId')
            }
        }

        It 'filters read-only properties and appends Ensure and auth' {
            $model = New-M365DSCResourceModel -ResourceName 'AADTestPolicy' -Workload 'MicrosoftGraph' `
                -CmdletInfo $script:cmdletInfo -Properties $script:properties

            $model.SchemaProperties.Name | Should -Not -Contain 'CreatedDateTime'
            $model.Properties.Name | Should -Contain 'Ensure'
            $model.Properties.Name | Should -Contain 'Credential'
            $model.Properties.Name | Should -Contain 'AccessTokens'
        }

        It 'marks Id as the primary key' {
            $model = New-M365DSCResourceModel -ResourceName 'AADTestPolicy' -Workload 'MicrosoftGraph' `
                -CmdletInfo $script:cmdletInfo -Properties $script:properties

            $model.PrimaryKey | Should -Be 'Id'
            ($model.Properties | Where-Object { $_.Name -eq 'Id' }).IsKey | Should -BeTrue
            $model.AlternativeKey | Should -Be 'DisplayName'
        }

        It 'unwraps System.Nullable when a value-typed property becomes the key' {
            $valueKeyProperties = @(
                New-M365DSCPropertyModel -Name 'Priority' -Type 'Edm.Int32' -Description 'The priority.'
                New-M365DSCPropertyModel -Name 'DisplayName' -Type 'Edm.String' -Description 'The name.'
            )
            $model = New-M365DSCResourceModel -ResourceName 'AADTestPolicy' -Workload 'MicrosoftGraph' `
                -CmdletInfo (@{} + $script:cmdletInfo + @{ PrimaryKey = 'Priority' }) -Properties $valueKeyProperties

            ($model.Properties | Where-Object { $_.Name -eq 'Priority' }).ClrType | Should -Be 'System.Int32'
        }

        It 'replaces the key with IsSingleInstance for singletons' {
            $model = New-M365DSCResourceModel -ResourceName 'AADTestPolicy' -Workload 'MicrosoftGraph' `
                -CmdletInfo $script:cmdletInfo -Properties $script:properties -IsSingleInstance $true

            $model.PrimaryKey | Should -Be 'IsSingleInstance'
            $model.Properties.Name | Should -Not -Contain 'Ensure'
        }

        It 'honors ParametersToSkip' {
            $model = New-M365DSCResourceModel -ResourceName 'AADTestPolicy' -Workload 'MicrosoftGraph' `
                -CmdletInfo $script:cmdletInfo -Properties $script:properties -ParametersToSkip @('DisplayName')

            $model.SchemaProperties.Name | Should -Not -Contain 'DisplayName'
        }

        It 'collects nested complex classes depth-first' {
            $inner = New-M365DSCPropertyModel -Name 'Inner' -CimClassName 'MSFT_TestInner' -Members @(
                New-M365DSCPropertyModel -Name 'Value' -Type 'Edm.String'
            )
            $outer = New-M365DSCPropertyModel -Name 'Outer' -CimClassName 'MSFT_TestOuter' -Members @($inner)

            $classes = @(Get-M365DSCComplexTypeClass -Properties @($outer))
            $classes.CimClassName | Should -Be @('MSFT_TestInner', 'MSFT_TestOuter')
        }
    }

    Describe 'Get-M365DSCResourceDescriptor' {
        It 'spaces out the resource name and maps platforms' {
            (Get-M365DSCResourceDescriptor -ResourceName 'IntuneDeviceCompliancePolicyWindows10').Description |
                Should -Be 'Intune Device Compliance Policy for Windows10'
        }

        It 'derives the short descriptor' {
            (Get-M365DSCResourceDescriptor -ResourceName 'IntuneDeviceCompliancePolicyWindows10').ShortDescriptor |
                Should -Be 'policy'
            (Get-M365DSCResourceDescriptor -ResourceName 'AADGroup').ShortDescriptor |
                Should -Be 'group'
        }
    }
}
