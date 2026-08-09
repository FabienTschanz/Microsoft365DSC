#Requires -Version 5.1

<#
.SYNOPSIS
    Deletes the per-resource source files that the packaged module does not need.

.DESCRIPTION
    DscResources/MSFT_*/MSFT_*.psm1 are the editing surface for the class-based resources.
    Build-Microsoft365DSC.ps1 compiles them into Classes/*.psm1, so shipping both duplicates
    roughly 12 MB into every install, and DSC discovery walks the folder on top of that. Nothing
    reads them at runtime, so all of them go.

    settings.json and readme.md are always kept: the first drives permissions and module
    requirements at runtime, the second is the source of the resource descriptions in
    SchemaDefinition.json.

    Meant for a publishing checkout, not for a development one - it deletes source files.

.PARAMETER RepoRoot
    Root of the Microsoft365DSC repository. Defaults to the parent of this script's folder.

.EXAMPLE
    .\Remove-M365DSCBuildOnlySource.ps1 -WhatIf

.EXAMPLE
    .\Remove-M365DSCBuildOnlySource.ps1
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param
(
    [Parameter()]
    [System.String]
    $RepoRoot = (Split-Path -Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'

$moduleRoot = Join-Path -Path $RepoRoot -ChildPath 'Modules/Microsoft365DSC'
$sourceRoot = Join-Path -Path $moduleRoot -ChildPath 'DscResources'
$classRoot = Join-Path -Path $moduleRoot -ChildPath 'Classes'

if (-not (Test-Path -Path $classRoot))
{
    throw "Classes folder not found at '$classRoot'. Run Build-Microsoft365DSC.ps1 first - removing the sources before they are compiled would leave nothing to ship."
}

$removed = 0
$freed = 0

foreach ($directory in (Get-ChildItem -Path $sourceRoot -Directory -Filter 'MSFT_*'))
{
    $sourceFile = Join-Path -Path $directory.FullName -ChildPath "$($directory.Name).psm1"
    if (-not (Test-Path -Path $sourceFile))
    {
        continue
    }

    $freed += (Get-Item -Path $sourceFile).Length
    if ($PSCmdlet.ShouldProcess($sourceFile, 'Remove build-only source'))
    {
        Remove-Item -Path $sourceFile -Force
    }

    $removed++
}

Write-Host ("[trim] Removed {0} source file(s), {1} MB" -f $removed, [System.Math]::Round($freed / 1MB, 1)) -ForegroundColor Green
