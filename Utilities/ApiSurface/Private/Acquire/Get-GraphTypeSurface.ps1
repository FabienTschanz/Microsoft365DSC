<#
.SYNOPSIS
    Captures the Graph CSDL types the resources are built on.

.DESCRIPTION
    Seeds from the entityType and odataSubtype of every generatedFrom block, then follows the
    complex types those entities reference until the set closes. Enum members are recorded on the
    property that uses them rather than as their own entries. Navigation properties are recorded
    with their target type name but the target is not followed, which would otherwise pull in most
    of the Graph entity graph.

    Every type is flattened over its inheritance chain. A comparison against a resource never has
    to resolve base types a second time.

.PARAMETER Generator
    Specifies the resource generator module, which owns the CSDL walking.

.PARAMETER Origin
    Specifies the resource rows from Get-ResourceOriginSurface.

.PARAMETER CsdlPath
    Specifies a map of API version to CSDL file. An absent entry falls back to the generator's
    cached download.

.OUTPUTS
    A hashtable with Types, an ordered map keyed '<apiVersion>:<typeName>', and Missing, the seed
    keys that do not exist in the metadata.
#>
function Get-GraphTypeSurface
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseLiteralInitializerForHashtable', '',
        Justification = 'CSDL names differ by case. A literal hashtable is case insensitive and drops one of two such names.')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSModuleInfo]
        $Generator,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Object[]]
        $Origin,

        [Parameter()]
        [System.Collections.IDictionary]
        $CsdlPath = @{}
    )

    $seeds = [System.Collections.Generic.List[System.String]]::new()
    foreach ($row in $Origin)
    {
        if ([System.String]::IsNullOrEmpty($row.EntityType))
        {
            continue
        }

        $apiVersion = $row.ApiVersion
        if ([System.String]::IsNullOrEmpty($apiVersion))
        {
            $apiVersion = 'beta'
        }

        $seeds.Add("$apiVersion|$($row.EntityType)")
        if (-not [System.String]::IsNullOrEmpty($row.ODataSubtype))
        {
            $seeds.Add("$apiVersion|$($row.ODataSubtype)")
        }
    }

    $seedKeys = Get-M365DSCOrderedName -Value ([System.String[]] @($seeds | Select-Object -Unique))

    $schemas = @{}
    $indexes = @{}
    $types = [System.Collections.Hashtable]::new([System.StringComparer]::Ordinal)
    $missing = [System.Collections.Generic.List[System.String]]::new()

    $queue = [System.Collections.Generic.Queue[System.String]]::new()
    foreach ($seedKey in $seedKeys)
    {
        $queue.Enqueue($seedKey)
    }

    $visited = [System.Collections.Generic.HashSet[System.String]]::new([System.StringComparer]::Ordinal)

    while ($queue.Count -gt 0)
    {
        $key = $queue.Dequeue()
        if (-not $visited.Add($key))
        {
            continue
        }

        $apiVersion, $typeName = $key -split '\|', 2

        if (-not $indexes.ContainsKey($apiVersion))
        {
            $schemas[$apiVersion] = Get-GraphCsdlSchema -Generator $Generator -ApiVersion $apiVersion -Path $CsdlPath[$apiVersion]
            $indexes[$apiVersion] = & $Generator { param($Schema) New-M365DSCGraphSchemaIndex -Schema $Schema } $schemas[$apiVersion]
        }

        $index = $indexes[$apiVersion]
        $definition = & $Generator {
            param($Schema, $Entity, $Index)
            Get-M365DSCGraphTypeDefinition -Schema $Schema -Entity $Entity -Index $Index -Qualified
        } $schemas[$apiVersion] $typeName $index

        if ($null -eq $definition -or $definition.Kind -eq 'EnumType')
        {
            if ($null -eq $definition)
            {
                $missing.Add($key)
            }
            continue
        }

        $properties = [System.Collections.Hashtable]::new([System.StringComparer]::Ordinal)
        foreach ($entry in $definition.Properties)
        {
            $name = [System.String] $entry.Node.Name
            if ($properties.ContainsKey($name))
            {
                continue
            }

            $access = & $Generator {
                param($Index, $NamespaceName, $TypeName, $PropertyName)
                Get-M365DSCGraphPropertyAccess -Index $Index -NamespaceName $NamespaceName -TypeName $TypeName -PropertyName $PropertyName
            } $index $entry.DeclaringNamespace $entry.DeclaringType $name

            $properties[$name] = New-GraphPropertySurface -Generator $Generator `
                -Index $index `
                -ApiVersion $apiVersion `
                -TypeReference ([System.String] $entry.Node.Type) `
                -IsReadOnly $access.IsReadOnly `
                -IsImmutable $access.IsImmutable `
                -IsNavigation $false `
                -Queue $queue
        }

        foreach ($entry in $definition.NavigationProperties)
        {
            $name = [System.String] $entry.Node.Name
            if ($properties.ContainsKey($name))
            {
                continue
            }

            $properties[$name] = New-GraphPropertySurface -Generator $Generator `
                -Index $index `
                -ApiVersion $apiVersion `
                -TypeReference ([System.String] $entry.Node.Type) `
                -IsReadOnly $false `
                -IsImmutable $false `
                -IsNavigation $true `
                -Queue $null
        }

        $baseType = $null
        if (-not [System.String]::IsNullOrEmpty($definition.BaseType))
        {
            $baseEntry = & $Generator {
                param($Index, $TypeReference) Resolve-M365DSCGraphTypeReference -Index $Index -TypeReference $TypeReference
            } $index $definition.BaseType

            if ($null -ne $baseEntry)
            {
                $baseType = & $Generator {
                    param($NamespaceName, $Name) Get-M365DSCGraphContractTypeName -NamespaceName $NamespaceName -Name $Name
                } $baseEntry.NamespaceName $baseEntry.Name
            }
        }

        $contractName = & $Generator {
            param($NamespaceName, $Name) Get-M365DSCGraphContractTypeName -NamespaceName $NamespaceName -Name $Name
        } $definition.NamespaceName $definition.Name

        $types["${apiVersion}:$contractName"] = [ordered]@{
            kind        = $definition.Kind
            baseType    = $baseType
            isAbstract  = $definition.IsAbstract
            properties  = ConvertTo-M365DSCOrderedMap -Map $properties
        }
    }

    return @{
        Types   = ConvertTo-M365DSCOrderedMap -Map $types
        Missing = Get-M365DSCOrderedName -Value ([System.String[]] $missing)
        Seeds   = $seedKeys
    }
}

<#
.SYNOPSIS
    Loads the CSDL schema nodes for one API version.

.DESCRIPTION
    Delegates to the generator, which keeps the download, the seven day cache and the byte order
    mark handling in one place. A path makes the call offline.

.PARAMETER Generator
    Specifies the resource generator module.

.PARAMETER ApiVersion
    Specifies the Graph API version.

.PARAMETER Path
    Specifies a CSDL file to read instead of the cached download.

.OUTPUTS
    The CSDL schema nodes.
#>
function Get-GraphCsdlSchema
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSModuleInfo]
        $Generator,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApiVersion,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $Path
    )

    if (-not [System.String]::IsNullOrEmpty($Path))
    {
        return & $Generator {
            param($Version, $File) Get-M365DSCGraphCsdlMetadata -APIVersion $Version -Path $File
        } $ApiVersion $Path
    }

    return & $Generator { param($Version) Get-M365DSCGraphCsdlMetadata -APIVersion $Version } $ApiVersion
}

<#
.SYNOPSIS
    Projects one CSDL property node into its snapshot entry.

.DESCRIPTION
    Records the vendor type name rather than the CLR type the generator would emit. The entry then
    reads as the service contract. An enum records its members inline. A complex type records its
    name and, unless it is reached through a navigation property, is queued for capture.

.PARAMETER Generator
    Specifies the resource generator module.

.PARAMETER Index
    Specifies the schema index of the API version.

.PARAMETER ApiVersion
    Specifies the Graph API version.

.PARAMETER TypeReference
    Specifies the raw CSDL type of the property.

.PARAMETER IsReadOnly
    Indicates that the service owns the value.

.PARAMETER IsImmutable
    Indicates that the value can be set on create but not changed afterwards.

.PARAMETER IsNavigation
    Indicates that the property is a Graph relationship.

.PARAMETER Queue
    Specifies the capture queue, or $null when the target must not be followed.

.OUTPUTS
    An ordered dictionary describing the property.
#>
function New-GraphPropertySurface
{
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSModuleInfo]
        $Generator,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Index,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApiVersion,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $TypeReference,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $IsReadOnly,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $IsImmutable,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $IsNavigation,

        [Parameter()]
        [AllowNull()]
        [System.Object]
        $Queue
    )

    $isArray = $false
    $rawType = $TypeReference
    if ($rawType -like 'Collection(*)')
    {
        $isArray = $true
        $rawType = $rawType -replace '^Collection\(', '' -replace '\)$', ''
    }

    $target = & $Generator {
        param($Index, $TypeReference) Resolve-M365DSCGraphTypeReference -Index $Index -TypeReference $TypeReference
    } $Index $rawType

    $entry = [ordered]@{}

    if ($null -eq $target)
    {
        $entry['type'] = $rawType
    }
    else
    {
        $contractName = & $Generator {
            param($NamespaceName, $Name) Get-M365DSCGraphContractTypeName -NamespaceName $NamespaceName -Name $Name
        } $target.NamespaceName $target.Name

        $entry['type'] = $contractName

        if ($target.Kind -eq 'EnumType')
        {
            $entry['enum'] = Get-M365DSCOrderedName -Value ([System.String[]] @(@($target.Node.Member) | ForEach-Object -Process { [System.String] $_.Name }))
            $entry['isFlags'] = ([System.String] $target.Node.IsFlags) -eq 'true'
        }
        else
        {
            $entry['isComplex'] = $true
            if ($null -ne $Queue -and $target.Kind -eq 'ComplexType')
            {
                $Queue.Enqueue("$ApiVersion|$contractName")
            }
        }
    }

    $entry['isArray'] = $isArray
    $entry['isNavigation'] = $IsNavigation
    $entry['isReadOnly'] = $IsReadOnly
    $entry['isImmutable'] = $IsImmutable

    return $entry
}
