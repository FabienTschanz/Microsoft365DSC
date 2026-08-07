<#
    Offline unit tests for the emitters: class module, unit test, examples and
    settings, all generated from a hand-built resource model fixture and validated with the
    PowerShell parser. No network or Graph modules required.
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\M365DSCResourceGenerator.psd1') -Force

InModuleScope -ModuleName 'M365DSCResourceGenerator' {

    BeforeAll {
        function Get-ParseError
        {
            param ([System.String] $Content)

            $parseErrors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref] $null, [ref] $parseErrors)

            # Artefacts of parsing outside the repository layout: the relative 'using module'
            # cannot resolve, which also makes DSC complain about the base type. The QA suite
            # (Tests\QA\Microsoft365DSC.ClassResources.Tests.ps1) parses in place and catches
            # real occurrences of these.
            return @($parseErrors | Where-Object {
                    $_.ErrorId -notin @('TypeNotFound', 'DscResourceMissingTestMethod', 'ModuleNotFoundDuringParse')
                })
        }

        $ruleMembers = @(
            New-M365DSCPropertyModel -Name 'Name' -Type 'Edm.String' -Description 'Rule name.'
            New-M365DSCPropertyModel -Name 'Threshold' -Type 'Edm.Int32' -Description 'Rule threshold.'
            New-M365DSCPropertyModel -Name 'State' -EnumValues @('enabled', 'disabled') -Description 'Rule state.'
        )

        $properties = @(
            New-M365DSCPropertyModel -Name 'Id' -Type 'Edm.String' -Description 'The unique identifier.'
            New-M365DSCPropertyModel -Name 'DisplayName' -Type 'Edm.String' -Description 'The display name.'
            New-M365DSCPropertyModel -Name 'IsEnabled' -Type 'Edm.Boolean' -Description 'Whether enabled.'
            New-M365DSCPropertyModel -Name 'StartDate' -Type 'Edm.DateTimeOffset' -Description 'The start date.'
            New-M365DSCPropertyModel -Name 'Level' -EnumValues @('low', 'medium', 'high') -Description 'The level.'
            New-M365DSCPropertyModel -Name 'Tags' -Type 'Edm.String' -IsArray $true -Description 'The tags.'
            New-M365DSCPropertyModel -Name 'Rules' -CimClassName 'MSFT_MicrosoftGraphTestRule' -IsArray $true -Members $ruleMembers -Description 'The rules.'
        )

        $cmdletInfo = @{
            APIVersion          = 'beta'
            GetCmdlet           = 'Get-MgBetaTestPolicy'
            NewCmdlet           = 'New-MgBetaTestPolicy'
            UpdateCmdlet        = 'Update-MgBetaTestPolicy'
            RemoveCmdlet        = 'Remove-MgBetaTestPolicy'
            GetKeyParameters    = @('TestPolicyId')
            NewKeyParameters    = @('BodyParameter')
            UpdateKeyParameters = @('TestPolicyId', 'BodyParameter')
            RemoveKeyParameters = @('TestPolicyId')
            SupportsAll         = $true
            SupportsFilter      = $true
        }

        $script:model = New-M365DSCResourceModel -ResourceName 'AADTestPolicy' -Workload 'MicrosoftGraph' `
            -CmdletInfo $cmdletInfo -Properties $properties

        $script:classContent = New-M365DSCClassModuleFile -ResourceModel $script:model
        $script:testContent = New-M365DSCUnitTestFile -ResourceModel $script:model
    }

    Describe 'New-M365DSCClassModuleFile' {
        It 'produces parseable PowerShell' {
            $parseErrors = Get-ParseError -Content $script:classContent
            $messages = ($parseErrors | ForEach-Object { "line $($_.Extent.StartLineNumber): $($_.Message)" }) -join '; '
            $parseErrors.Count | Should -Be 0 -Because $messages
        }

        It 'opens with the base-class using statement' {
            $firstStatement = @($script:classContent -split "`r?`n" |
                    Where-Object { $_.Trim() -ne '' -and -not $_.Trim().StartsWith('#') } |
                    Select-Object -First 1)[0]
            $firstStatement.Trim() | Should -Be 'using module ..\_Base\M365DSCResourceBase.psm1'
        }

        It 'declares exactly one [DscResource()] class' {
            ([regex]::Matches($script:classContent, '(?m)^\s*\[DscResource\(\)\]')).Count | Should -Be 1
            $script:classContent | Should -Match 'class AADTestPolicy : M365DSCResourceBase'
        }

        It 'declares the embedded CIM class without a DscResource attribute' {
            $script:classContent | Should -Match '(?m)^class MSFT_MicrosoftGraphTestRule'
        }

        It 'declares the four DSC methods plus AsResult' {
            $script:classContent | Should -Match '\[AADTestPolicy\] Get\(\)'
            $script:classContent | Should -Match '\[void\] Set\(\)'
            $script:classContent | Should -Match '\[bool\] Test\(\)'
            $script:classContent | Should -Match '\[string\] Export\(\)'
            $script:classContent | Should -Match 'hidden \[AADTestPolicy\] AsResult'
        }

        It 'uses the base-class plumbing instead of script-scope state' {
            $script:classContent | Should -Match '\$this\.Connect\(''MicrosoftGraph''\)'
            $script:classContent | Should -Match '\$this\.AddTelemetry\('
            $script:classContent | Should -Match '\$this\.ExportedInstance'
            $script:classContent | Should -Not -Match '\$Script:exportedInstance'
            $script:classContent | Should -Not -Match 'function Get-TargetResource'
        }

        It 'wraps value types in Nullable and keys the primary key' {
            $script:classContent | Should -Match '\[System\.Nullable\[System\.Boolean\]\] \$IsEnabled'
            $script:classContent | Should -Match '(?s)\[DscProperty\(Key\)\]\s*\[System\.ComponentModel\.Description\(''The unique identifier\.''\)\]\s*\[System\.String\] \$Id'
        }

        It 'generates a per-resource hashtable helper for the complex type' {
            $script:classContent | Should -Match 'function Get-AADTestPolicyTestRuleAsHashtable'
            $script:classContent | Should -Match '\$complexRules \+= Get-AADTestPolicyTestRuleAsHashtable'
        }

        It 'converts enums and dates before the result hashtable' {
            $script:classContent | Should -Match '\$enumLevel = \$getValue\.Level\.ToString\(\)'
            $script:classContent | Should -Match '\$dateStartDate = \$getValue\.StartDate\.ToUniversalTime\(\)\.ToString\(''o''\)'
        }

        It 'exports with -All and NoEscape for the complex property' {
            $script:classContent | Should -Match 'Get-MgBetaTestPolicy -All'
            $script:classContent | Should -Match "-NoEscape @\('Rules'\)"
        }
    }

    Describe 'New-M365DSCUnitTestFile' {
        It 'produces parseable PowerShell' {
            $parseErrors = Get-ParseError -Content $script:testContent
            $messages = ($parseErrors | ForEach-Object { "line $($_.Extent.StartLineNumber): $($_.Message)" }) -join '; '
            $parseErrors.Count | Should -Be 0 -Because $messages
        }

        It 'contains no unreplaced tokens' {
            $script:testContent | Should -Not -Match '<[A-Za-z][A-Za-z0-9]*>'
        }

        It 'uses the class-based invocation pattern' {
            $script:testContent | Should -Match "New-M365DSCResourceInstance -ResourceName 'AADTestPolicy'"
            $script:testContent | Should -Match "Invoke-M365DSCResourceMethod -ResourceName 'AADTestPolicy' -MethodName 'Export'"
            $script:testContent | Should -Match "Mock -CommandName New-M365DSCConnection -ModuleName '_Shared'"
        }

        It 'asserts scalar property values from the Get result' {
            $script:testContent | Should -Match "\`$result\.DisplayName \| Should -Be 'FakeStringValue'"
            $script:testContent | Should -Match '\$result\.IsEnabled \| Should -Be \$true'
            $script:testContent | Should -Match "\`$result\.Level \| Should -Be 'low'"
            $script:testContent | Should -Match "\`$result\.Tags \| Should -Be @\('FakeStringArrayValue1', 'FakeStringArrayValue2'\)"
        }

        It 'drives the drift context with genuinely different values' {
            $script:testContent | Should -Match 'FakeStringValueDrift'
            $script:testContent | Should -Match "'medium'"
        }

        It 'branches the Get mock on All and the key parameter' {
            $script:testContent | Should -Match '(?s)if \(\$All\).+if \(\$TestPolicyId\)'
        }
    }

    Describe 'New-M365DSCExampleFile' {
        BeforeAll {
            $script:exampleFolder = Join-Path -Path $TestDrive -ChildPath 'Examples'
            New-M365DSCExampleFile -ResourceModel $script:model -DestinationFolder $script:exampleFolder
        }

        It 'creates three distinct example files' {
            $createContent = Get-Content -Path (Join-Path $script:exampleFolder '1-Create.ps1') -Raw
            $updateContent = Get-Content -Path (Join-Path $script:exampleFolder '2-Update.ps1') -Raw
            $removeContent = Get-Content -Path (Join-Path $script:exampleFolder '3-Remove.ps1') -Raw

            $createContent | Should -Not -Be $updateContent
            $createContent | Should -Match "Ensure\s+= `"Present`";"
            $updateContent | Should -Match 'FakeStringValueDrift'
            $removeContent | Should -Match "Ensure\s+= `"Absent`";"
            $removeContent | Should -Not -Match 'IsEnabled'
        }

        It 'produces parseable configurations with CIM instance blocks' {
            foreach ($exampleFile in Get-ChildItem -Path $script:exampleFolder -Filter '*.ps1')
            {
                $parseErrors = $null
                $null = [System.Management.Automation.Language.Parser]::ParseFile($exampleFile.FullName, [ref] $null, [ref] $parseErrors)
                # ResourceNotDefined is expected: the resource is not built/installed yet.
                $realErrors = @($parseErrors | Where-Object { $_.ErrorId -ne 'ResourceNotDefined' })
                $realErrors.Count | Should -Be 0 -Because "$($exampleFile.Name) must parse"
            }

            (Get-Content -Path (Join-Path $script:exampleFolder '1-Create.ps1') -Raw) |
                Should -Match 'MSFT_MicrosoftGraphTestRule\{'
        }
    }

    Describe 'New-M365DSCSettingsFile' {
        It 'emits valid JSON with the roles and commands sections' {
            $json = New-M365DSCSettingsFile -ResourceModel $script:model -WarningAction SilentlyContinue
            $settings = $json | ConvertFrom-Json

            $settings.resourceName | Should -Be 'AADTestPolicy'
            $settings.roles | Should -Not -BeNullOrEmpty
            $settings.mode | Should -Be 'Configuration'
            $settings.supportedEnvironments | Should -Contain 'Global'
        }
    }
}
