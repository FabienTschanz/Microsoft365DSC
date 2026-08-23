<#
.SYNOPSIS
    Measures how the generated class layout affects module load and DSC discovery times.

.DESCRIPTION
    Rebuilds the module at a range of -BucketCount values inside a throwaway copy of the
    repository and, for each of them, times:

        Import-Module        on PowerShell 7 and on Windows PowerShell 5.1
        Get-DscResourceV2    on PowerShell 7, against a staged copy on PSModulePath
        Parser::ParseFile    over the generated Classes/*.psm1, as the parse-only floor

    Every timing runs in a fresh process, because PowerShell caches created class types for the
    lifetime of the session and a second import in the same process is close to free - which would
    make every configuration look identical.

    The working copy is never touched: the module and Utilities are copied to a temp workspace and
    the build runs there.

.PARAMETER RepositoryRoot
    Root of the Microsoft365DSC repository. Defaults to the parent of this script's folder.

.PARAMETER BucketCount
    The -BucketCount values to measure.

.PARAMETER Repetition
    Timed runs per data point. The median is reported. One extra warm-up run per data point is
    always discarded.

.PARAMETER DscParserPath
    Manifest of the DSCParser build to measure against. Defaults to the highest installed version.
    Point this at a working copy to measure a parser change alongside a module change.

.PARAMETER SkipDiscovery
    Skip the Get-DscResourceV2 measurement, which is the slowest part of the sweep.

.PARAMETER SkipWindowsPowerShell
    Skip the Windows PowerShell 5.1 import measurement.

.PARAMETER OutputPath
    Optional CSV to write the results to, on top of returning them.

.EXAMPLE
    .\Measure-M365DSCLoadPerformance.ps1

.EXAMPLE
    .\Measure-M365DSCLoadPerformance.ps1 -BucketCount 8, 16, 32 -Repetition 5 -OutputPath .\sweep.csv

.OUTPUTS
    System.Management.Automation.PSCustomObject
#>
[CmdletBinding()]
[OutputType([System.Management.Automation.PSCustomObject])]
param
(
    [Parameter()]
    [System.String]
    $RepositoryRoot = (Split-Path -Path $PSScriptRoot -Parent),

    [Parameter()]
    [ValidateRange(1, 64)]
    [System.Int32[]]
    $BucketCount = @(1, 2, 4, 8, 12, 16, 24, 32, 48),

    [Parameter()]
    [ValidateRange(1, 25)]
    [System.Int32]
    $Repetition = 3,

    [Parameter()]
    [System.String]
    $DscParserPath,

    [Parameter()]
    [Switch]
    $SkipDiscovery,

    [Parameter()]
    [Switch]
    $SkipWindowsPowerShell,

    [Parameter()]
    [System.String]
    $OutputPath
)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'M365DSCBuildHelpers.psm1') -Force

#region Helpers

function Write-MeasureLog
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateSet('Info', 'Detail', 'Success', 'Warning')]
        [System.String]
        $Level = 'Info'
    )

    $color = switch ($Level)
    {
        'Info' { 'Cyan' }
        'Detail' { 'DarkGray' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
    }

    Write-Host "[measure] $Message" -ForegroundColor $color
}

# Runs a snippet in a fresh host process and returns its non-empty output lines.
function Invoke-InFreshProcess
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('pwsh', 'powershell')]
        [System.String]
        $Executable,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Script
    )

    $output = & $Executable -NoProfile -NonInteractive -Command $Script 2>$null

    return @($output |
            Where-Object { $_ -is [System.String] -and $_.Trim().Length -gt 0 } |
            ForEach-Object { $_.Trim() })
}

<#
    Runs the snippet Repetition + 1 times and returns the median of the timed runs. The first run
    is discarded: it pays for assembly JIT and a cold file cache that no later run repeats.
#>
function Measure-Median
{
    [CmdletBinding()]
    [OutputType([System.Nullable[System.Int32]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Executable,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Script,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $Count
    )

    $null = Invoke-InFreshProcess -Executable $Executable -Script $Script

    $samples = [System.Collections.Generic.List[System.Int32]]::new()
    for ($i = 0; $i -lt $Count; $i++)
    {
        $lines = @(Invoke-InFreshProcess -Executable $Executable -Script $Script)
        $value = if ($lines.Count -gt 0) { $lines[-1] } else { $null }
        $parsed = 0
        if ([System.Int32]::TryParse($value, [ref] $parsed))
        {
            $samples.Add($parsed)
        }
        else
        {
            Write-MeasureLog "Unusable sample from ${Executable}: '$value'" -Level Warning
        }
    }

    if ($samples.Count -eq 0)
    {
        return $null
    }

    $sorted = @($samples | Sort-Object)
    return $sorted[[System.Math]::Floor($sorted.Count / 2)]
}

#endregion

#region Workspace

$workspace = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('M365DSCPerf_' + [Guid]::NewGuid().ToString('N'))
$workModuleRoot = Join-Path -Path $workspace -ChildPath 'Modules/Microsoft365DSC'
$workUtilities = Join-Path -Path $workspace -ChildPath 'Utilities'
$workManifest = Join-Path -Path $workModuleRoot -ChildPath 'Microsoft365DSC.psd1'
$workClassRoot = Join-Path -Path $workModuleRoot -ChildPath 'Classes'

Write-MeasureLog "Repository : $RepositoryRoot"
Write-MeasureLog "Workspace  : $workspace"
Write-MeasureLog 'Copying the module into the workspace...'

$null = New-Item -Path (Join-Path -Path $workspace -ChildPath 'Modules') -ItemType Directory -Force
Copy-Item -Path (Join-Path -Path $RepositoryRoot -ChildPath 'Modules/Microsoft365DSC') -Destination $workModuleRoot -Recurse -Force
Copy-Item -Path (Join-Path -Path $RepositoryRoot -ChildPath 'Utilities') -Destination $workUtilities -Recurse -Force

$results = [System.Collections.Generic.List[Object]]::new()

try
{
    foreach ($buckets in $BucketCount)
    {
        Write-MeasureLog "BucketCount $buckets - building..."

        $buildOutput = & (Join-Path -Path $workUtilities -ChildPath 'Build-Microsoft365DSC.ps1') `
            -RepositoryRoot $workspace -BucketCount $buckets -SkipSchema -SkipValidation 2>&1

        $failed = @($buildOutput | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
        if ($failed.Count -gt 0)
        {
            throw "Build failed at BucketCount ${buckets}: $($failed[0])"
        }

        $classFiles = @(Get-ChildItem -Path $workClassRoot -Filter '*.psm1')
        $totalBytes = ($classFiles | Measure-Object -Property Length -Sum).Sum
        $largestBytes = ($classFiles | Measure-Object -Property Length -Maximum).Maximum

        $importScript = @"
`$sw = [System.Diagnostics.Stopwatch]::StartNew()
Import-Module -Name '$workManifest' -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
`$sw.Stop()
[System.Int32] `$sw.ElapsedMilliseconds
"@

        $parseScript = @"
`$sw = [System.Diagnostics.Stopwatch]::StartNew()
foreach (`$file in Get-ChildItem -Path '$workClassRoot' -Filter '*.psm1')
{
    `$tokens = `$null
    `$errors = `$null
    `$null = [System.Management.Automation.Language.Parser]::ParseFile(`$file.FullName, [ref] `$tokens, [ref] `$errors)
}
`$sw.Stop()
[System.Int32] `$sw.ElapsedMilliseconds
"@

        Write-MeasureLog "BucketCount $buckets - timing import (pwsh)..." -Level Detail
        $importCore = Measure-Median -Executable 'pwsh' -Script $importScript -Count $Repetition

        $importDesktop = $null
        if (-not $SkipWindowsPowerShell)
        {
            Write-MeasureLog "BucketCount $buckets - timing import (powershell 5.1)..." -Level Detail
            $importDesktop = Measure-Median -Executable 'powershell' -Script $importScript -Count $Repetition
        }

        Write-MeasureLog "BucketCount $buckets - timing parse..." -Level Detail
        $parseMs = Measure-Median -Executable 'pwsh' -Script $parseScript -Count $Repetition

        $discoveryMs = $null
        $discoveryTotal = $null
        $discoveryClassBased = $null

        if (-not $SkipDiscovery)
        {
            Write-MeasureLog "BucketCount $buckets - timing Get-DscResourceV2..." -Level Detail

            $version = ([Version] (Import-PowerShellDataFile -Path $workManifest).ModuleVersion).ToString()
            $stage = New-M365DSCProbeStage -ModuleRoot $workModuleRoot -Version $version

            try
            {
                $stageRoot = $stage.Root.Replace("'", "''")
                $discoveryScript = @"
`$parserPath = '$($DscParserPath -replace "'", "''")'
if ([System.String]::IsNullOrEmpty(`$parserPath))
{
    `$parser = @(Get-Module -ListAvailable -Name 'DSCParser' | Sort-Object Version -Descending)[0]
    if (`$null -eq `$parser)
    {
        throw 'DSCParser is not installed; Get-DscResourceV2 is unavailable.'
    }

    `$parserPath = `$parser.Path
}

`$entries = @(`$env:PSModulePath -split [System.IO.Path]::PathSeparator |
    Where-Object { `$_ -and -not (Test-Path -Path (Join-Path -Path `$_ -ChildPath 'Microsoft365DSC')) })
`$env:PSModulePath = (@('$stageRoot') + `$entries) -join [System.IO.Path]::PathSeparator

Import-Module -Name `$parserPath -Force -WarningAction SilentlyContinue

`$sw = [System.Diagnostics.Stopwatch]::StartNew()
`$found = @(Get-DscResourceV2 -Module 'Microsoft365DSC' -ErrorAction SilentlyContinue)
`$sw.Stop()

'COUNT:{0}:{1}' -f `$found.Count, @(`$found | Where-Object { `$_.ImplementationDetail -eq 'ClassBased' }).Count
[System.Int32] `$sw.ElapsedMilliseconds
"@

                $discoveryMs = Measure-Median -Executable 'pwsh' -Script $discoveryScript -Count $Repetition

                $countLine = @(Invoke-InFreshProcess -Executable 'pwsh' -Script $discoveryScript |
                        Where-Object { $_ -match '^COUNT:(\d+):(\d+)$' })
                if ($countLine.Count -gt 0 -and $countLine[0] -match '^COUNT:(\d+):(\d+)$')
                {
                    $discoveryTotal = [System.Int32] $Matches[1]
                    $discoveryClassBased = [System.Int32] $Matches[2]
                }
            }
            finally
            {
                Remove-M365DSCProbeStage -Stage $stage
            }
        }

        $entry = [PSCustomObject] @{
            BucketCount         = $buckets
            ClassFiles          = $classFiles.Count
            TotalClassKB        = [System.Math]::Round($totalBytes / 1KB)
            LargestClassKB      = [System.Math]::Round($largestBytes / 1KB)
            ImportCoreMs        = $importCore
            ImportDesktopMs     = $importDesktop
            ParseOnlyMs         = $parseMs
            DiscoveryMs         = $discoveryMs
            DiscoveryTotal      = $discoveryTotal
            DiscoveryClassBased = $discoveryClassBased
        }

        $results.Add($entry)
        Write-MeasureLog ("BucketCount {0}: import {1} ms (core) / {2} ms (desktop), parse {3} ms, discovery {4} ms" -f
            $buckets, $importCore, $importDesktop, $parseMs, $discoveryMs) -Level Success
    }
}
finally
{
    Remove-Item -Path $workspace -Recurse -Force -ErrorAction SilentlyContinue
}

#endregion

if ($PSBoundParameters.ContainsKey('OutputPath'))
{
    $results | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-MeasureLog "Wrote $OutputPath"
}

return $results.ToArray()
