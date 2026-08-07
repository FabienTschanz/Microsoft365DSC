#Requires -Version 5.1

<#
.SYNOPSIS
    Builds the class-based resource files for the Microsoft365DSC module.

.DESCRIPTION
    Reads the per-resource source files under Modules/Microsoft365DSC/DscResources/MSFT_*/ and emits
    the class files the shipped module actually loads:

        Modules/Microsoft365DSC/Classes/_Shared.psm1     base class, factory, every complex type
        Modules/Microsoft365DSC/Classes/Part<NN>.psm1    the [DscResource()] classes, bucketed

    then wires both into Microsoft365DSC.psd1 and regenerates SchemaDefinition.json from class
    reflection.

    Why this shape?

      - PowerShell type creation is superlinear in the number of classes in ONE parse unit. All
        ~1000 classes together costs ~41 s to import on both editions, against a 4.50 s baseline
        for the module as it ships today. Each NestedModules entry is its own parse unit, so
        bucketing collapses that back to ~7 s. Parsing itself is never the cost; type creation is.

      - Class types do not cross module boundaries, so each part must open with
        `using module .\_Shared.psm1` to see the base class and the complex types.

      - Because the parts are separate modules, no single scope can resolve every resource class
        with `$Name -as [System.Type]`. Each part therefore ends with
        [M365DSCResourceBase]::Register([X]) and the factory resolves through that registry.

      - The manifest's FunctionsToExport key MUST stay absent or '*'. An explicit list silently
        drops every class-based resource from Get-DscResource, on both editions, with no error
        raised. This script never writes that key.

.PARAMETER RepoRoot
    Root of the Microsoft365DSC repository. Defaults to the parent of this script's folder.

.PARAMETER BucketCount
    Number of Part<NN>.psm1 files to spread the resource classes across. 16 measured best
    (6.95 s import); 4 and 8 are close, 32 regresses.

.PARAMETER SkipSchema
    Skip regenerating SchemaDefinition.json.

.PARAMETER SkipValidation
    Skip the post-build import and discovery check.

.EXAMPLE
    .\Build-Microsoft365DSC.ps1

.EXAMPLE
    .\Build-Microsoft365DSC.ps1 -BucketCount 8 -SkipSchema

.NOTES
    Replaces a regex-based predecessor that shadowed New-ModuleManifest with a self-recursive
    function, and that resolved complex-type name collisions by renaming one side - which would
    silently break every exported configuration referencing that type. Collisions are now a hard
    failure.
#>

[CmdletBinding(SupportsShouldProcess)]
param
(
    [Parameter()]
    [System.String]
    $RepoRoot = (Split-Path -Path $PSScriptRoot -Parent),

    [Parameter()]
    [ValidateRange(1, 64)]
    [System.Int32]
    $BucketCount = 16,

    [Parameter()]
    [Switch]
    $SkipSchema,

    [Parameter()]
    [Switch]
    $SkipValidation
)

$ErrorActionPreference = 'Stop'

$script:ModuleRoot = Join-Path -Path $RepoRoot -ChildPath 'Modules/Microsoft365DSC'
$script:SourceRoot = Join-Path -Path $script:ModuleRoot -ChildPath 'DscResources'
$script:BaseRoot = Join-Path -Path $script:SourceRoot -ChildPath '_Base'
$script:ClassRoot = Join-Path -Path $script:ModuleRoot -ChildPath 'Classes'
$script:ManifestPath = Join-Path -Path $script:ModuleRoot -ChildPath 'Microsoft365DSC.psd1'

# Markers let the generated NestedModules entries be rewritten in place without disturbing the
# hand-maintained ones around them.
$script:BeginMarker = '# BEGIN GENERATED CLASS MODULES - Utilities/Build-Microsoft365DSC.ps1'
$script:EndMarker = '# END GENERATED CLASS MODULES'

#region Helpers

function Write-BuildLog
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Detail')]
        [System.String]
        $Level = 'Info'
    )

    $color = switch ($Level)
    {
        'Info' { 'Cyan' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Success' { 'Green' }
        'Detail' { 'DarkGray' }
    }

    Write-Host "[build] $Message" -ForegroundColor $color
}

# Parses one source file and returns its top-level class definitions.
function Get-M365DSCClassDefinition
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref] $null, [ref] $errors)

    <#
        Two error kinds are expected when a resource file is parsed on its own and must not be
        fatal, because they are artefacts of the split layout rather than defects in the source:

          TypeNotFound                 - the file opens `class X : M365DSCResourceBase`, and the
                                         base lives in _Shared.psm1, which this file does not pull
                                         in. The generated Part<NN>.psm1 does.
          DscResourceMissingTestMethod - Test() is inherited from M365DSCResourceBase, which the
                                         parser cannot see here for the same reason.

        Anything else is a real syntax error and still stops the build.
    #>
    $ignorable = @('TypeNotFound', 'DscResourceMissingTestMethod')
    $fatal = @($errors | Where-Object { $_.ErrorId -notin $ignorable })

    if ($fatal.Count -gt 0)
    {
        throw "Cannot parse '$Path': $($fatal[0].Message) (line $($fatal[0].Extent.StartLineNumber))"
    }

    # searchNestedScriptBlocks = $false: DSC only recognises classes at file top level, so anything
    # nested would not be discoverable anyway.
    $typeDefinitions = $ast.FindAll(
        { $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] },
        $false)

    $resourceClasses = [System.Collections.Generic.List[Object]]::new()
    $complexTypes = [System.Collections.Generic.List[Object]]::new()

    foreach ($typeDefinition in $typeDefinitions)
    {
        if ($typeDefinition.IsEnum)
        {
            # Enums are emitted alongside the complex types; they carry no DscResource attribute.
            $complexTypes.Add($typeDefinition)
            continue
        }

        $isResource = $false
        foreach ($attribute in $typeDefinition.Attributes)
        {
            if ($attribute.TypeName.Name -in @('DscResource', 'DscResourceAttribute'))
            {
                $isResource = $true
                break
            }
        }

        if ($isResource)
        {
            $resourceClasses.Add($typeDefinition)
        }
        else
        {
            $complexTypes.Add($typeDefinition)
        }
    }

    <#
        Converted resources carry private helpers alongside the class (Get-<Resource>SettingValue
        and friends). They are module-scope functions, not class members, so they must be emitted
        into the same part file or every call site fails at runtime.
    #>
    $typeSpans = @($typeDefinitions | ForEach-Object {
            [PSCustomObject] @{ Start = $_.Extent.StartOffset; End = $_.Extent.EndOffset }
        })

    $helperFunctions = @($ast.FindAll(
            { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] },
            $false) |
            Where-Object {
                $function = $_
                $inside = @($typeSpans | Where-Object {
                        $function.Extent.StartOffset -ge $_.Start -and $function.Extent.EndOffset -le $_.End
                    })
                $inside.Count -eq 0
            })

    return @{
        ResourceClasses = $resourceClasses
        ComplexTypes    = $complexTypes
        HelperFunctions = $helperFunctions
    }
}

function Get-NormalizedText
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Text
    )

    return (($Text -replace '\s+', ' ').Trim())
}

#endregion

#region Collect

Write-BuildLog "Repository : $RepoRoot"
Write-BuildLog "Source     : $script:SourceRoot"

foreach ($required in @('M365DSCResourceBase.psm1', 'M365DSCResourceFactory.psm1'))
{
    $path = Join-Path -Path $script:BaseRoot -ChildPath $required
    if (-not (Test-Path -Path $path))
    {
        throw "Required base file not found: $path"
    }
}

$sourceFiles = @(Get-ChildItem -Path $script:SourceRoot -Directory -Filter 'MSFT_*' |
        ForEach-Object {
            $candidate = Join-Path -Path $_.FullName -ChildPath "$($_.Name).psm1"
            if (Test-Path -Path $candidate) { Get-Item -Path $candidate }
        })

Write-BuildLog "Found $($sourceFiles.Count) resource source files"

$resourceEntries = [System.Collections.Generic.List[Object]]::new()

# Keyed case-insensitively on purpose. Complex types are declared once per resource that uses
# them and the casing is not always consistent between those copies.
$complexByName = [System.Collections.Generic.Dictionary[String, Object]]::new([StringComparer]::OrdinalIgnoreCase)
$collisions = [System.Collections.Generic.List[String]]::new()
$skipped = [System.Collections.Generic.List[String]]::new()

foreach ($file in $sourceFiles)
{
    $definition = Get-M365DSCClassDefinition -Path $file.FullName

    if ($definition.ResourceClasses.Count -eq 0)
    {
        # Not converted yet - still a script-based resource. Expected during the transition.
        $skipped.Add($file.BaseName)
        continue
    }

    if ($definition.ResourceClasses.Count -gt 1)
    {
        throw ("'{0}' declares {1} [DscResource()] classes. One resource per source file." -f
            $file.Name, $definition.ResourceClasses.Count)
    }

    $resourceClass = $definition.ResourceClasses[0]

    $resourceEntries.Add([PSCustomObject] @{
            Name       = $resourceClass.Name
            SourceFile = $file.FullName
            SourceDir  = $file.DirectoryName
            Text       = $resourceClass.Extent.Text
            Helpers    = @($definition.HelperFunctions | ForEach-Object { $_.Extent.Text })
        })

    foreach ($complexType in $definition.ComplexTypes)
    {
        $normalized = Get-NormalizedText -Text $complexType.Extent.Text

        if ($complexByName.ContainsKey($complexType.Name))
        {
            $existing = $complexByName[$complexType.Name]
            if ($existing.Normalized -ne $normalized)
            {
                $collisions.Add(("{0}: declared differently in '{1}' and '{2}'" -f
                        $complexType.Name, $existing.Source, $file.Name))
            }
            continue
        }

        $complexByName[$complexType.Name] = [PSCustomObject] @{
            Name       = $complexType.Name
            Text       = $complexType.Extent.Text
            Normalized = $normalized
            Source     = $file.Name
        }
    }
}

if ($collisions.Count -gt 0)
{
    $message = "Complex type collisions must be resolved at the source:`n  " + ($collisions -join "`n  ")
    throw $message
}

Write-BuildLog "Class-based resources : $($resourceEntries.Count)"
Write-BuildLog "Complex types         : $($complexByName.Count)"
Write-BuildLog "Still script-based    : $($skipped.Count)" -Level $(if ($skipped.Count -gt 0) { 'Warning' } else { 'Info' })

if ($resourceEntries.Count -eq 0)
{
    throw "No class-based resources found under $script:SourceRoot. Nothing to build."
}

#endregion

#region Emit

if (-not $PSCmdlet.ShouldProcess($script:ClassRoot, 'Generate class modules'))
{
    Write-BuildLog 'WhatIf: stopping before any file is written.' -Level Warning
    return
}

if (Test-Path -Path $script:ClassRoot)
{
    Get-ChildItem -Path $script:ClassRoot -Filter '*.psm1' | Remove-Item -Force
}
else
{
    $null = New-Item -Path $script:ClassRoot -ItemType Directory -Force
}

# --- _Shared.psm1 -----------------------------------------------------------------------------
# Order matters inside one parse unit: the base class first, then the factory that references it,
# then the complex types. Complex types are emitted in name order rather than dependency order -
# PowerShell resolves class property types across a whole file, so forward references between them
# are fine, which the full-scale spike confirmed at ~470 types.
$shared = [System.Text.StringBuilder]::new()
[void] $shared.AppendLine('# GENERATED FILE - do not edit.')
[void] $shared.AppendLine('# Produced by Utilities/Build-Microsoft365DSC.ps1 from DscResources/_Base and DscResources/MSFT_*.')
[void] $shared.AppendLine('')
[void] $shared.AppendLine((Get-Content -Path (Join-Path $script:BaseRoot 'M365DSCResourceBase.psm1') -Raw))
[void] $shared.AppendLine('')
[void] $shared.AppendLine((Get-Content -Path (Join-Path $script:BaseRoot 'M365DSCResourceFactory.psm1') -Raw))
[void] $shared.AppendLine('')
[void] $shared.AppendLine('#region Complex types')
[void] $shared.AppendLine('')

<#
    Name order is not enough once complex types inherit from one another: a base class must be
    defined before the class deriving from it, in the same file. Property references still need no
    ordering - PowerShell resolves those across the whole file - so inheritance is the only edge
    sorted on here, name order breaking ties so the output stays stable.
#>
$complexBase = @{}
foreach ($complexType in $complexByName.Values)
{
    $match = [regex]::Match($complexType.Text, '(?m)^\s*class\s+[A-Za-z0-9_]+\s*:\s*(?<Base>[A-Za-z0-9_]+)')
    if ($match.Success)
    {
        $complexBase[$complexType.Name] = $match.Groups['Base'].Value
    }
}

$orderedComplex = [System.Collections.Generic.List[Object]]::new()
$placedComplex = [System.Collections.Generic.HashSet[String]]::new([StringComparer]::OrdinalIgnoreCase)

$placeComplex = {
    param([String] $Name)

    if (-not $complexByName.ContainsKey($Name) -or -not $placedComplex.Add($Name))
    {
        return
    }

    $base = $complexBase[$Name]
    if (-not [String]::IsNullOrEmpty($base))
    {
        & $placeComplex $base
    }

    $orderedComplex.Add($complexByName[$Name])
}

foreach ($complexType in ($complexByName.Values | Sort-Object Name))
{
    & $placeComplex $complexType.Name
}

foreach ($complexType in $orderedComplex)
{
    [void] $shared.AppendLine($complexType.Text)
    [void] $shared.AppendLine('')
}

[void] $shared.AppendLine('#endregion')

$sharedPath = Join-Path -Path $script:ClassRoot -ChildPath '_Shared.psm1'
Set-Content -Path $sharedPath -Value $shared.ToString() -Encoding UTF8
Write-BuildLog "Wrote $($sharedPath.Substring($RepoRoot.Length + 1)) ($([math]::Round((Get-Item $sharedPath).Length / 1KB)) KB)" -Level Detail

# --- Part<NN>.psm1 ----------------------------------------------------------------------------
$sortedResources = @($resourceEntries | Sort-Object Name)
$effectiveBuckets = [System.Math]::Min($BucketCount, $sortedResources.Count)
$perBucket = [System.Math]::Ceiling($sortedResources.Count / $effectiveBuckets)

$generatedFiles = [System.Collections.Generic.List[String]]::new()
$generatedFiles.Add('Classes/_Shared.psm1')

for ($bucket = 0; $bucket -lt $effectiveBuckets; $bucket++)
{
    $slice = @($sortedResources | Select-Object -Skip ($bucket * $perBucket) -First $perBucket)
    if ($slice.Count -eq 0)
    {
        continue
    }

    $part = [System.Text.StringBuilder]::new()
    [void] $part.AppendLine('# GENERATED FILE - do not edit.')
    [void] $part.AppendLine('# Produced by Utilities/Build-Microsoft365DSC.ps1.')
    [void] $part.AppendLine('')
    # Classes do not cross module boundaries; this is what makes M365DSCResourceBase and the
    # complex types visible here.
    [void] $part.AppendLine('using module .\_Shared.psm1')
    [void] $part.AppendLine('')

    foreach ($resource in $slice)
    {
        [void] $part.AppendLine($resource.Text)
        [void] $part.AppendLine('')

        foreach ($helper in $resource.Helpers)
        {
            [void] $part.AppendLine($helper)
            [void] $part.AppendLine('')
        }
    }

    [void] $part.AppendLine('# Self-registration. The factory cannot use `$Name -as [System.Type]`, because each part is')
    [void] $part.AppendLine('# its own module and no single scope sees every resource class.')
    [void] $part.AppendLine('#')
    [void] $part.AppendLine('# The module name is captured here rather than derived later: this runs at module top level,')
    [void] $part.AppendLine('# so $ExecutionContext.SessionState.Module is THIS part. A class type does not expose the')
    [void] $part.AppendLine('# module that declared it, and the unit tests need it to scope their mocks.')
    [void] $part.AppendLine('$partModuleName = $ExecutionContext.SessionState.Module.Name')
    foreach ($resource in $slice)
    {
        [void] $part.AppendLine(('[M365DSCResourceBase]::Register([{0}], $partModuleName)' -f $resource.Name))
    }

    $fileName = 'Part{0:D2}.psm1' -f $bucket

    <#
        Source resource files open with `using module ..\_Base\M365DSCResourceBase.psm1` so that
        they parse cleanly in an editor. That line must not survive into the generated part, which
        pulls the base class from _Shared.psm1 instead.
    #>
    if ($part.ToString() -match '(?m)^\s*using module (?!\.\\_Shared\.psm1)')
    {
        throw ("Generated $fileName carries a using statement other than _Shared.psm1. " +
            'Class-text extraction must exclude file-level using statements.')
    }

    Set-Content -Path (Join-Path $script:ClassRoot $fileName) -Value $part.ToString() -Encoding UTF8
    $generatedFiles.Add("Classes/$fileName")
}

Write-BuildLog "Wrote $($generatedFiles.Count - 1) part file(s), $perBucket resource(s) each at most"

#endregion

#region Manifest

# Edits the existing manifest in place rather than regenerating it.
function Update-M365DSCBuildManifest
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ClassModule,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ResourceName
    )

    $content = Get-Content -Path $Path -Raw

    # 1. Drop any previously generated block so re-runs are idempotent. The leading newline and
    #    indent are part of the block: leaving them behind made each run inherit the previous
    #    run's padding, which grew the NestedModules closing line by four spaces every build.
    $pattern = '\r?\n[ \t]*' + [System.Text.RegularExpressions.Regex]::Escape($script:BeginMarker) +
    '.*?' + [System.Text.RegularExpressions.Regex]::Escape($script:EndMarker)
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, $pattern, '', 'Singleline')

    # 2. Insert the class modules at the end of the NestedModules array.
    $nestedMatch = [System.Text.RegularExpressions.Regex]::Match(
        $content, '(?s)(NestedModules\s*=\s*@\()(.*?)(\r?\n\s*\))')
    if (-not $nestedMatch.Success)
    {
        throw "Could not locate the NestedModules array in '$Path'."
    }

    $body = $nestedMatch.Groups[2].Value.TrimEnd()
    if (-not $body.EndsWith(','))
    {
        $body += ','
    }

    $block = "`r`n    $script:BeginMarker`r`n"
    $block += (($ClassModule | ForEach-Object { "    '$_'" }) -join ",`r`n")
    $block += "`r`n    $script:EndMarker"

    $content = $content.Remove($nestedMatch.Index, $nestedMatch.Length).Insert(
        $nestedMatch.Index,
        $nestedMatch.Groups[1].Value + $body + $block + "`r`n  )")

    # 3. DscResourcesToExport. Mandatory: DscClassCache returns immediately when it is missing or
    #    empty, so without it discovery yields zero resources.
    $exportBlock = "  DscResourcesToExport = @(`r`n"
    $exportBlock += (($ResourceName | Sort-Object | ForEach-Object { "    '$_'" }) -join ",`r`n")
    $exportBlock += "`r`n  )"

    $existing = [System.Text.RegularExpressions.Regex]::Match(
        $content, '(?s)^\s*DscResourcesToExport\s*=\s*@\(.*?\r?\n\s*\)', 'Multiline')

    if ($existing.Success)
    {
        $content = $content.Remove($existing.Index, $existing.Length).Insert($existing.Index, $exportBlock)
    }
    else
    {
        # Place it right after the NestedModules array.
        $anchor = [System.Text.RegularExpressions.Regex]::Match(
            $content, '(?s)NestedModules\s*=\s*@\(.*?\r?\n\s*\)')
        $insertAt = $anchor.Index + $anchor.Length
        $content = $content.Insert($insertAt, "`r`n`r`n  # DSC resources to export from this module.`r`n$exportBlock")
    }

    # 4. FunctionsToExport is deliberately untouched. An explicit list silently reduces
    #    Get-DscResource to zero resources on both editions - see Spike 1d.

    if ($PSCmdlet.ShouldProcess($Path, 'Update manifest'))
    {
        Set-Content -Path $Path -Value $content -Encoding UTF8 -NoNewline
    }
}

Update-M365DSCBuildManifest -Path $script:ManifestPath `
    -ClassModule $generatedFiles.ToArray() `
    -ResourceName @($resourceEntries.Name)

Write-BuildLog "Updated $($script:ManifestPath.Substring($RepoRoot.Length + 1))"

$manifestData = Import-PowerShellDataFile -Path $script:ManifestPath
if ($manifestData.ContainsKey('FunctionsToExport'))
{
    Write-BuildLog ('FunctionsToExport is present in the manifest. An explicit list drops every ' +
        'class-based resource from Get-DscResource. Remove or comment out the key.') -Level Error
    throw 'Manifest declares FunctionsToExport.'
}

#endregion

#region Schema

if (-not $SkipSchema)
{
    Write-BuildLog 'Regenerating SchemaDefinition.json from class reflection...'
    & (Join-Path -Path $PSScriptRoot -ChildPath 'New-M365DSCSchemaFromClasses.ps1') -RepoRoot $RepoRoot
}

#endregion

#region Validate

if (-not $SkipValidation)
{
    Write-BuildLog 'Validating...'

    $expected = $resourceEntries.Count
    $probe = @"
`$ErrorActionPreference = 'Stop'
Import-Module '$script:ManifestPath' -Force -WarningAction SilentlyContinue
`$found = @(Get-DscResource -Module 'Microsoft365DSC' -ErrorAction SilentlyContinue |
    Where-Object { `$_.ImplementationDetail -eq 'ClassBased' -or `$_.Name -in @('$($resourceEntries.Name -join "','")') })
'{0}' -f `$found.Count
"@

    $result = & pwsh -NoProfile -NonInteractive -Command $probe
    $count = 0
    [void] [int]::TryParse(($result | Select-Object -Last 1), [ref] $count)

    if ($count -ne $expected)
    {
        Write-BuildLog "Discovery returned $count class-based resources, expected $expected." -Level Error
        throw 'Validation failed.'
    }

    Write-BuildLog "Discovery: $count / $expected class-based resources" -Level Success
}

#endregion

Write-BuildLog 'Build complete.' -Level Success
