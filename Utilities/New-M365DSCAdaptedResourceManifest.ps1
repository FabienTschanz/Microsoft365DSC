#Requires -Version 5.1

<#
.SYNOPSIS
    Generates the DSC v3 adapted resource manifests for the class-based resources.

.DESCRIPTION
    Writes one Modules/Microsoft365DSC/Microsoft365DSC.<Name>.dsc.adaptedResource.json per entry
    of DscResourcesToExport, next to Microsoft365DSC.psd1, so the manifests ship in the package.
    Each manifest names the resource Microsoft365DSC/<Name>, points at Microsoft365DSC.psd1,
    requires the Microsoft.Adapter/PowerShell adapter and embeds a JSON schema for the resource
    properties.

    The manifests come from the DscResource.Authoring module. New-DscAdaptedResourceManifest
    reads a resource from its source file by AST, names it after that file, maps property types
    by their short PowerShell spelling and takes property descriptions from comment-based help.
    The sources declare fully qualified types and describe properties with
    [System.ComponentModel.Description()]. Every manifest is therefore corrected after generation
    through New-DscPropertyOverride and Update-DscAdaptedResourceManifest:

      - type becomes Microsoft365DSC/<Name> and path becomes Microsoft365DSC.psd1
      - the resource description comes from the readme.md of the resource
      - property descriptions come from the Description attributes
      - property types follow the declared CLR types, with System.Nullable[T] unwrapped
      - complex MSFT_* types and PSCredential are emitted once under $defs and referenced. The
        tool serializes at a fixed JSON depth that nested complex types exceed.
      - a [ValidateSet] on a string array carries its enum under items
      - the export capability is dropped. dsc invokes a static Export() and the resources
        implement an instance method.
      - the version is Major.Minor.Build, the form the adapter reports for module versions

    The work runs in a child PowerShell 7 process. DscResource.Authoring is installed under the
    PowerShell 7 module path, while the build also runs under Windows PowerShell.

    dsc 3.3.0-preview.4 lists these manifests and returns their schemas. Get, set and test through
    path Microsoft365DSC.psd1 still fail inside the shipped adapter, which cannot load class
    resources from a manifest without a RootModule and types nested classes after the file that
    declares them. Both defects are tracked upstream.

.PARAMETER RepositoryRoot
    Root of the Microsoft365DSC repository. Defaults to the parent of this script's folder.

.PARAMETER WarnOnly
    Warn instead of failing when PowerShell 7 or DscResource.Authoring is not available. A
    mismatch between the written manifests and DscResourcesToExport always fails.

.EXAMPLE
    .\New-M365DSCAdaptedResourceManifest.ps1

.EXAMPLE
    .\New-M365DSCAdaptedResourceManifest.ps1 -WarnOnly

.NOTES
    Called by Utilities/Build-Microsoft365DSC.ps1 after the class modules are built. Reads the
    DscResources tree, which places it before Remove-M365DSCBuildOnlySource.ps1 in the release
    flow. Install the tool with Install-PSResource -Name DscResource.Authoring -Prerelease.
#>

[CmdletBinding(SupportsShouldProcess)]
param
(
    [Parameter()]
    [System.String]
    $RepositoryRoot,

    [Parameter()]
    [Switch]
    $WarnOnly
)

$ErrorActionPreference = 'Stop'

if ([System.String]::IsNullOrEmpty($RepositoryRoot))
{
    $RepositoryRoot = Split-Path -Path (Split-Path -Path $PSCommandPath -Parent) -Parent
}

$moduleRoot = Join-Path -Path $RepositoryRoot -ChildPath 'Modules/Microsoft365DSC'
$manifestPath = Join-Path -Path $moduleRoot -ChildPath 'Microsoft365DSC.psd1'
$sourceRoot = Join-Path -Path $moduleRoot -ChildPath 'DscResources'

if (-not (Test-Path -Path $manifestPath))
{
    throw "Manifest not found: $manifestPath"
}

$manifest = Import-PowerShellDataFile -Path $manifestPath
$resourceNames = @($manifest.DscResourcesToExport | Sort-Object)
if ($resourceNames.Count -eq 0)
{
    throw "DscResourcesToExport in '$manifestPath' is empty. Run Build-Microsoft365DSC.ps1 first."
}

$moduleVersion = [System.Version] $manifest.ModuleVersion
$build = if ($moduleVersion.Build -ge 0) { $moduleVersion.Build } else { 0 }
$semanticVersion = '{0}.{1}.{2}' -f $moduleVersion.Major, $moduleVersion.Minor, $build

function ConvertTo-SingleLine
{
    param
    (
        [System.String]
        $Text
    )

    return (($Text -split '\r?\n') | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join ' '
}

$defaultDescription = ConvertTo-SingleLine -Text $manifest.Description

$resources = foreach ($name in $resourceNames)
{
    $sourceDirectory = Join-Path -Path $sourceRoot -ChildPath "MSFT_$name"
    $sourceFile = Join-Path -Path $sourceDirectory -ChildPath "MSFT_$name.psm1"
    if (-not (Test-Path -Path $sourceFile))
    {
        throw "Source file not found for resource '$name': $sourceFile"
    }

    $description = $defaultDescription
    $readMePath = Join-Path -Path $sourceDirectory -ChildPath 'readme.md'
    if (Test-Path -Path $readMePath)
    {
        $parts = (Get-Content -Path $readMePath -Raw) -split '## Description'
        if ($parts.Count -gt 1)
        {
            $readMeDescription = ConvertTo-SingleLine -Text $parts[1]
            if ($readMeDescription)
            {
                $description = $readMeDescription
            }
        }
    }

    @{
        Name        = $name
        SourceFile  = $sourceFile
        Description = $description
    }
}

if (-not (Get-Command -Name pwsh -ErrorAction Ignore))
{
    $message = 'PowerShell 7 (pwsh) was not found on PATH. The adapted resource manifests were not generated.'
    if ($WarnOnly)
    {
        Write-Warning -Message $message
        return
    }
    throw $message
}

if (-not $PSCmdlet.ShouldProcess($moduleRoot, 'Write adapted resource manifests'))
{
    return
}

$inputs = @{
    ModuleRoot = $moduleRoot
    Version    = $semanticVersion
    Author     = $manifest.Author
    SchemaUri  = 'https://aka.ms/dsc/schemas/v3/bundled/resource/adapted/manifest.json'
    Resources  = @($resources)
} | ConvertTo-Json -Depth 5 -Compress

$child = @'
param
(
    [Parameter(Mandatory = $true)]
    [System.String]
    $InputPath
)

$ErrorActionPreference = 'Stop'

$inputs = Get-Content -Path $InputPath -Raw | ConvertFrom-Json

$module = Get-Module -ListAvailable -Name 'DscResource.Authoring' |
    Where-Object { $_.Version -ge [System.Version] '0.2.0' } |
    Sort-Object -Property Version -Descending |
    Select-Object -First 1

if ($null -eq $module)
{
    'RESULT:' + (@{ Skipped = 'DscResource.Authoring 0.2.0 or later is not installed. Install it with Install-PSResource -Name DscResource.Authoring -Prerelease.' } | ConvertTo-Json -Compress)
    return
}

Import-Module -Name $module.Path -Force

$descriptionAttributeNames = @(
    'System.ComponentModel.Description',
    'System.ComponentModel.DescriptionAttribute',
    'Description',
    'DescriptionAttribute'
)

function Test-DscPropertyMember
{
    param
    (
        [System.Management.Automation.Language.MemberAst]
        $Member
    )

    if ($Member -isnot [System.Management.Automation.Language.PropertyMemberAst] -or $Member.IsStatic)
    {
        return $false
    }

    foreach ($attribute in $Member.Attributes)
    {
        if ($attribute.TypeName.Name -eq 'DscProperty')
        {
            return $true
        }
    }

    return $false
}

function Get-MemberDescription
{
    param
    (
        [System.Management.Automation.Language.PropertyMemberAst]
        $Member
    )

    foreach ($attribute in $Member.Attributes)
    {
        if ($attribute.TypeName.FullName -notin $descriptionAttributeNames)
        {
            continue
        }

        $argument = @($attribute.PositionalArguments)[0]
        if ($argument -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
            $argument -is [System.Management.Automation.Language.ExpandableStringExpressionAst])
        {
            return $argument.Value
        }
    }

    return $null
}

function Get-ValidateSetValue
{
    param
    (
        [System.Management.Automation.Language.PropertyMemberAst]
        $Member
    )

    foreach ($attribute in $Member.Attributes)
    {
        if ($attribute.TypeName.Name -eq 'ValidateSet')
        {
            return @($attribute.PositionalArguments | ForEach-Object { [System.String] $_.Value })
        }
    }

    return @()
}

function Get-ComplexTypeMember
{
    param
    (
        [System.Management.Automation.Language.TypeDefinitionAst]
        $TypeDefinition,

        [System.Collections.Hashtable]
        $TypeDefinitions
    )

    $chain = [System.Collections.Generic.List[System.Management.Automation.Language.TypeDefinitionAst]]::new()
    $current = $TypeDefinition
    while ($null -ne $current -and -not $chain.Contains($current))
    {
        $chain.Insert(0, $current)
        $baseName = if ($current.BaseTypes.Count -gt 0) { $current.BaseTypes[0].TypeName.Name } else { $null }
        $current = if ($baseName -and $TypeDefinitions.ContainsKey($baseName)) { $TypeDefinitions[$baseName] } else { $null }
    }

    $members = [ordered] @{}
    foreach ($type in $chain)
    {
        foreach ($member in $type.Members)
        {
            if (Test-DscPropertyMember -Member $member)
            {
                $members[$member.Name] = $member
            }
        }
    }

    return $members
}

function ConvertTo-M365DSCJsonSchema
{
    param
    (
        [System.Management.Automation.Language.ITypeName]
        $TypeName,

        [System.String[]]
        $EnumValues,

        [System.Collections.Hashtable]
        $TypeDefinitions,

        [System.Collections.Specialized.OrderedDictionary]
        $Definitions
    )

    if ($null -eq $TypeName)
    {
        return [ordered] @{ type = 'string' }
    }

    if ($TypeName -is [System.Management.Automation.Language.ArrayTypeName])
    {
        $items = ConvertTo-M365DSCJsonSchema -TypeName $TypeName.ElementType -EnumValues $EnumValues `
            -TypeDefinitions $TypeDefinitions -Definitions $Definitions
        return [ordered] @{ type = 'array'; items = $items }
    }

    if ($TypeName -is [System.Management.Automation.Language.GenericTypeName] -and
        $TypeName.TypeName.Name -in @('System.Nullable', 'Nullable'))
    {
        return ConvertTo-M365DSCJsonSchema -TypeName $TypeName.GenericArguments[0] -EnumValues $EnumValues `
            -TypeDefinitions $TypeDefinitions -Definitions $Definitions
    }

    if ($TypeDefinitions.ContainsKey($TypeName.Name))
    {
        $definitionName = Add-M365DSCComplexDefinition -Name $TypeName.Name `
            -TypeDefinitions $TypeDefinitions -Definitions $Definitions
        return [ordered] @{ '$ref' = "#/`$defs/$definitionName" }
    }

    $reflectionType = $TypeName.GetReflectionType()
    $fullName = if ($null -ne $reflectionType) { $reflectionType.FullName } else { $TypeName.FullName }

    $schema = switch ($fullName)
    {
        'System.String' { [ordered] @{ type = 'string' } }
        'System.Boolean' { [ordered] @{ type = 'boolean' } }
        { $_ -in @('System.Int16', 'System.Int32', 'System.Int64', 'System.UInt16', 'System.UInt32', 'System.UInt64', 'System.Byte', 'System.SByte') }
        {
            [ordered] @{ type = 'integer' }
        }
        { $_ -in @('System.Single', 'System.Double', 'System.Decimal') }
        {
            [ordered] @{ type = 'number' }
        }
        'System.DateTime' { [ordered] @{ type = 'string'; format = 'date-time' } }
        'System.Collections.Hashtable' { [ordered] @{ type = 'object' } }
        'System.Management.Automation.PSCredential'
        {
            if (-not $Definitions.Contains('PSCredential'))
            {
                $Definitions['PSCredential'] = [ordered] @{
                    type       = 'object'
                    properties = [ordered] @{
                        username = [ordered] @{ type = 'string' }
                        password = [ordered] @{ type = 'string' }
                    }
                }
            }
            [ordered] @{ '$ref' = '#/$defs/PSCredential' }
        }
        default { throw "No JSON schema mapping for type '$fullName'." }
    }

    if ($EnumValues.Count -gt 0 -and $schema['type'] -eq 'string')
    {
        $schema['enum'] = $EnumValues
    }

    return $schema
}

function New-M365DSCPropertySchema
{
    param
    (
        [System.Management.Automation.Language.PropertyMemberAst]
        $Member,

        [System.Collections.Hashtable]
        $TypeDefinitions,

        [System.Collections.Specialized.OrderedDictionary]
        $Definitions
    )

    $typeName = if ($null -ne $Member.PropertyType) { $Member.PropertyType.TypeName } else { $null }
    $schema = ConvertTo-M365DSCJsonSchema -TypeName $typeName -EnumValues (Get-ValidateSetValue -Member $Member) `
        -TypeDefinitions $TypeDefinitions -Definitions $Definitions
    $schema['title'] = $Member.Name

    $description = Get-MemberDescription -Member $Member
    if ($description)
    {
        $schema['description'] = $description
    }

    return $schema
}

function Add-M365DSCComplexDefinition
{
    param
    (
        [System.String]
        $Name,

        [System.Collections.Hashtable]
        $TypeDefinitions,

        [System.Collections.Specialized.OrderedDictionary]
        $Definitions
    )

    $typeDefinition = $TypeDefinitions[$Name]
    $definitionName = $typeDefinition.Name
    if ($Definitions.Contains($definitionName))
    {
        return $definitionName
    }

    $Definitions[$definitionName] = $null

    $properties = [ordered] @{}
    $members = Get-ComplexTypeMember -TypeDefinition $typeDefinition -TypeDefinitions $TypeDefinitions
    foreach ($member in $members.Values)
    {
        $properties[$member.Name] = New-M365DSCPropertySchema -Member $member `
            -TypeDefinitions $TypeDefinitions -Definitions $Definitions
    }

    $Definitions[$definitionName] = [ordered] @{
        type                 = 'object'
        additionalProperties = $false
        properties           = $properties
    }

    return $definitionName
}

$moduleRoot = $inputs.ModuleRoot
Get-ChildItem -Path $moduleRoot -Filter 'Microsoft365DSC.*.dsc.adaptedResource.json' -File | Remove-Item -Force

$warnings = [System.Collections.Generic.List[System.String]]::new()
$written = 0
$encoding = [System.Text.UTF8Encoding]::new($false)

foreach ($resource in $inputs.Resources)
{
    try
    {
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($resource.SourceFile, [ref] $null, [ref] $parseErrors)
        if ($parseErrors.Count -gt 0)
        {
            throw "Parse errors: $(($parseErrors | ForEach-Object { $_.Message }) -join '; ')"
        }

        $typeDefinitions = @{}
        $resourceClass = $null
        foreach ($typeDefinition in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $false))
        {
            $typeDefinitions[$typeDefinition.Name] = $typeDefinition
            if (@($typeDefinition.Attributes | Where-Object { $_.TypeName.Name -eq 'DscResource' }).Count -gt 0)
            {
                $resourceClass = $typeDefinition
            }
        }

        if ($null -eq $resourceClass -or $resourceClass.Name -ne $resource.Name)
        {
            throw "Expected a [DscResource()] class named '$($resource.Name)'."
        }

        $toolWarnings = @()
        $manifests = @(New-DscAdaptedResourceManifest -Path $resource.SourceFile -Version $inputs.Version `
                -WarningAction SilentlyContinue -WarningVariable toolWarnings)
        foreach ($warning in $toolWarnings)
        {
            if ($warning.Message -notlike 'No comment-based help found above class*')
            {
                $warnings.Add("$($resource.Name): $($warning.Message)")
            }
        }

        if ($manifests.Count -ne 1)
        {
            throw "New-DscAdaptedResourceManifest returned $($manifests.Count) manifests."
        }

        $manifest = $manifests[0]
        $manifest.Schema = $inputs.SchemaUri
        $manifest.Type = "Microsoft365DSC/$($resource.Name)"
        $manifest.Path = 'Microsoft365DSC.psd1'
        $manifest.Author = $inputs.Author
        $manifest.Description = $resource.Description
        $manifest.Capabilities = @($manifest.Capabilities | Where-Object { $_ -ne 'export' })

        $embedded = $manifest.ManifestSchema.Embedded
        $embedded['title'] = $manifest.Type
        $embedded['description'] = $resource.Description

        $definitions = [ordered] @{}
        $overrides = foreach ($member in $resourceClass.Members)
        {
            if (-not (Test-DscPropertyMember -Member $member))
            {
                continue
            }

            $schema = New-M365DSCPropertySchema -Member $member -TypeDefinitions $typeDefinitions -Definitions $definitions

            $jsonSchema = @{}
            foreach ($key in $schema.Keys)
            {
                if ($key -notin @('title', 'description'))
                {
                    $jsonSchema[$key] = $schema[$key]
                }
            }

            $removeKeys = @()
            if ($jsonSchema.ContainsKey('$ref'))
            {
                $removeKeys += 'type'
            }
            if ($jsonSchema['type'] -eq 'array')
            {
                $removeKeys += 'enum'
            }

            $parameters = @{
                Name       = $member.Name
                JsonSchema = $jsonSchema
            }
            if ($removeKeys.Count -gt 0)
            {
                $parameters['RemoveKeys'] = $removeKeys
            }
            if ($schema.Contains('description'))
            {
                $parameters['Description'] = $schema['description']
            }

            New-DscPropertyOverride @parameters
        }

        if ($definitions.Count -gt 0)
        {
            $sorted = [ordered] @{}
            foreach ($definitionName in ($definitions.Keys | Sort-Object))
            {
                $sorted[$definitionName] = $definitions[$definitionName]
            }
            $embedded['$defs'] = $sorted
        }

        $null = Update-DscAdaptedResourceManifest -InputObject $manifest -PropertyOverride $overrides

        $outputPath = Join-Path -Path $moduleRoot -ChildPath "Microsoft365DSC.$($resource.Name).dsc.adaptedResource.json"
        [System.IO.File]::WriteAllText($outputPath, $manifest.ToJson(), $encoding)
        $written++
    }
    catch
    {
        throw "$($resource.Name): $($_.Exception.Message)"
    }
}

'RESULT:' + (@{ Written = $written; Warnings = @($warnings) } | ConvertTo-Json -Compress -Depth 3)
'@

$scriptFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('m365dsc-adapted-{0}.ps1' -f [System.Guid]::NewGuid())
$inputFile = "$scriptFile.json"

try
{
    Set-Content -Path $scriptFile -Value $child -Encoding UTF8
    Set-Content -Path $inputFile -Value $inputs -Encoding UTF8

    $output = @(& pwsh -NoProfile -NonInteractive -File $scriptFile -InputPath $inputFile)
    $exitCode = $LASTEXITCODE
}
finally
{
    Remove-Item -Path $scriptFile, $inputFile -Force -ErrorAction SilentlyContinue
}

foreach ($line in $output)
{
    if ($line -is [System.String] -and -not $line.StartsWith('RESULT:'))
    {
        Write-Host "[adapted] $line"
    }
}

if ($exitCode -ne 0)
{
    throw "Adapted resource manifest generation failed (exit $exitCode): $($output -join [System.Environment]::NewLine)"
}

$resultLine = @($output | Where-Object { $_ -is [System.String] -and $_.StartsWith('RESULT:') }) | Select-Object -First 1
if (-not $resultLine)
{
    throw "Adapted resource manifest generation produced no result: $($output -join [System.Environment]::NewLine)"
}

$result = $resultLine.Substring(7) | ConvertFrom-Json

if ($result.Skipped)
{
    $message = "$($result.Skipped) The adapted resource manifests were not generated."
    if ($WarnOnly)
    {
        Write-Warning -Message $message
        return
    }
    throw $message
}

foreach ($warning in @($result.Warnings | Where-Object { $_ }))
{
    Write-Warning -Message "[adapted] $warning"
}

if ([int] $result.Written -ne $resourceNames.Count)
{
    throw "Wrote $($result.Written) adapted resource manifests but the manifest exports $($resourceNames.Count) resources."
}

Write-Host "[adapted] Wrote $($result.Written) adapted resource manifests to $moduleRoot" -ForegroundColor Green
