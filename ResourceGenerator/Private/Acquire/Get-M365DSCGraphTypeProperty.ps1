<#
.SYNOPSIS
    Walks the Graph CSDL metadata and returns the property models of an entity or complex type.

.DESCRIPTION
    Climbs the type's inheritance chain, resolves enums, recurses into complex types and -
    optionally - navigation properties, and returns ready-to-emit property models. Recursion
    carries an explicit visited set: a type referencing itself (directly or through a chain) stops
    the descent instead of looping forever, which is what the old generator's disabled guard
    allowed with navigation properties.

.PARAMETER Schema
    Specifies the CSDL schema nodes from Get-M365DSCGraphCsdlMetadata.

.PARAMETER Entity
    Specifies the entity or complex type name, e.g. 'permissionGrantPolicy'.

.PARAMETER IncludeNavigationProperties
    Indicates that navigation properties (Graph relationships) are included as complex properties.

.PARAMETER ExistingCimClassNames
    Specifies the CIM class names already used by shipped resources, for collision suffixing.

.PARAMETER Visited
    Specifies the set of type names already on the current recursion path.
#>
function Get-M365DSCGraphTypeProperty
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Schema,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Entity,

        [Parameter()]
        [System.Boolean]
        $IncludeNavigationProperties = $false,

        [Parameter()]
        [System.String[]]
        $ExistingCimClassNames = @(),

        [Parameter()]
        [System.Collections.Generic.HashSet[System.String]]
        $Visited
    )

    if ($null -eq $Visited)
    {
        $Visited = [System.Collections.Generic.HashSet[System.String]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    $null = $Visited.Add($Entity)

    $namespace = $Schema | Where-Object -FilterScript { $_.EntityType.Name -contains $Entity }
    if ($null -eq $namespace)
    {
        $namespace = $Schema | Where-Object -FilterScript { $_.ComplexType.Name -contains $Entity }
    }

    if ($null -eq $namespace)
    {
        Write-Warning -Message "Type '$Entity' was not found in the Graph metadata."
        return @()
    }

    # Collect the raw CSDL property nodes across the whole inheritance chain. Each entry keeps
    # whether its declaring type is a "root" type (directly below graph.entity): on polymorphic
    # resources the Graph cmdlets surface root properties on the output object itself, while
    # subtype properties travel inside AdditionalProperties.
    $rawProperties = @()
    $navigationProperties = @()
    $derivedSubtypeNames = @()
    $baseTypeName = $Entity

    do
    {
        $typeNode = $namespace.EntityType | Where-Object -FilterScript { $_.Name -eq $baseTypeName }
        $isComplexType = $false
        if ($null -eq $typeNode)
        {
            $typeNode = $namespace.ComplexType | Where-Object -FilterScript { $_.Name -eq $baseTypeName }
            $isComplexType = $true
        }

        if ($null -eq $typeNode)
        {
            break
        }

        $isRootType = ($typeNode.BaseType -eq 'graph.entity') -or ($typeNode.Name -eq 'entity')

        if ($null -ne $typeNode.Property)
        {
            foreach ($propertyNode in @($typeNode.Property))
            {
                $rawProperties += [PSCustomObject]@{
                    Node   = $propertyNode
                    IsRoot = $isRootType
                }
            }
        }

        # An abstract complex type surfaces the union of its subtypes' properties plus a
        # synthesized @odata.type discriminator.
        if ($isComplexType -and $baseTypeName -eq $Entity -and $null -eq $typeNode.BaseType)
        {
            $subtypes = @($namespace.ComplexType | Where-Object -FilterScript { $_.BaseType -eq "graph.$baseTypeName" })
            foreach ($subtype in $subtypes)
            {
                $derivedSubtypeNames += $subtype.Name
                foreach ($subtypeProperty in @($subtype.Property))
                {
                    if ($null -ne $subtypeProperty -and $subtypeProperty.Name -notin @($rawProperties.Node.Name))
                    {
                        $rawProperties += [PSCustomObject]@{
                            Node   = $subtypeProperty
                            IsRoot = $false
                        }
                    }
                }
            }
        }

        if ($IncludeNavigationProperties -and $null -ne $typeNode.NavigationProperty)
        {
            foreach ($navigationNode in @($typeNode.NavigationProperty))
            {
                $navigationProperties += [PSCustomObject]@{
                    Node   = $navigationNode
                    IsRoot = $isRootType
                }
            }
        }

        $baseTypeName = $null
        if ($typeNode.BaseType -is [System.String] -and -not [System.String]::IsNullOrEmpty($typeNode.BaseType))
        {
            $baseTypeName = $typeNode.BaseType.Replace('graph.', '')
        }
    } while ($null -ne $baseTypeName)

    # Project the raw nodes into property models.
    $models = @()

    foreach ($rawEntry in ($rawProperties + $navigationProperties))
    {
        $rawProperty = $rawEntry.Node
        $isFromAdditionalProperties = -not $rawEntry.IsRoot

        $rawType = $rawProperty.Type
        $isArray = $false
        if ($rawType -like 'Collection(*)')
        {
            $isArray = $true
            $rawType = $rawType.Replace('Collection(', '').Replace(')', '')
        }

        $description = Get-M365DSCGraphPropertyDescription -Schema $Schema -Property $rawProperty

        if ($rawType -like 'graph.*')
        {
            $typeName = $rawType.Replace('graph.', '')

            $enumType = $namespace.EnumType | Where-Object -FilterScript { $_.Name -eq $typeName }
            if ($null -ne $enumType)
            {
                $models += New-M365DSCPropertyModel -Name $rawProperty.Name `
                    -GraphName $rawProperty.Name `
                    -Description $description `
                    -IsArray $isArray `
                    -EnumValues ([System.String[]] @($enumType.Member.Name)) `
                    -IsFromAdditionalProperties $isFromAdditionalProperties
                continue
            }

            # Complex type (or navigation target): recurse unless this closes a cycle.
            if ($Visited.Contains($typeName))
            {
                Write-Warning -Message "Skipping property '$($rawProperty.Name)' on '$Entity': type '$typeName' is already part of the current type chain (cycle)."
                continue
            }

            $nestedVisited = [System.Collections.Generic.HashSet[System.String]]::new($Visited, [System.StringComparer]::OrdinalIgnoreCase)
            $members = @(Get-M365DSCGraphTypeProperty -Schema $Schema `
                    -Entity $typeName `
                    -ExistingCimClassNames $ExistingCimClassNames `
                    -Visited $nestedVisited)

            if ($members.Count -eq 0)
            {
                Write-Warning -Message "Skipping property '$($rawProperty.Name)' on '$Entity': complex type '$typeName' has no usable members."
                continue
            }

            $cimClassName = Get-M365DSCUniqueCimClassName -TypeName $typeName -ExistingCimClassNames $ExistingCimClassNames

            $models += New-M365DSCPropertyModel -Name $rawProperty.Name `
                -GraphName $rawProperty.Name `
                -Description $description `
                -IsArray $isArray `
                -CimClassName $cimClassName `
                -Members $members `
                -IsFromAdditionalProperties $isFromAdditionalProperties
            continue
        }

        # Scalar Edm type.
        $models += New-M365DSCPropertyModel -Name $rawProperty.Name `
            -GraphName $rawProperty.Name `
            -Type $rawType `
            -Description $description `
            -IsArray $isArray `
            -IsFromAdditionalProperties $isFromAdditionalProperties
    }

    # Discriminator for abstract complex types: which concrete subtype an instance is.
    if ($derivedSubtypeNames.Count -gt 0)
    {
        $models += New-M365DSCPropertyModel -Name 'ODataType' `
            -GraphName '@odata.type' `
            -Description 'The type of the entity.' `
            -EnumValues ([System.String[]] @($derivedSubtypeNames | ForEach-Object { "#microsoft.graph.$_" }))
    }

    return $models
}

<#
.SYNOPSIS
    Extracts a property description from its CSDL annotation, falling back to the schema-level
    annotations block.
#>
function Get-M365DSCGraphPropertyDescription
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Schema,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $Property
    )

    $description = ''

    if (-not [System.String]::IsNullOrWhiteSpace($Property.Annotation.String))
    {
        $description = $Property.Annotation.String
    }
    else
    {
        $target = "microsoft.graph.$($Property.ParentNode.Name)/$($Property.Name)"
        $annotation = $Schema.Annotations | Where-Object -FilterScript { $_.Target -like $target }
        if (-not [System.String]::IsNullOrWhiteSpace($annotation.Annotation.String))
        {
            $description = $annotation.Annotation.String
        }
    }

    if ([System.String]::IsNullOrEmpty($description))
    {
        return ''
    }

    $description = $description.Replace('"', "'")
    # Keep letters, digits and basic punctuation only - MOF descriptions choke on the rest.
    return ($description -replace '[^\p{L}\p{Nd}/(/}/_ -.,=:)'']', '')
}

<#
.SYNOPSIS
    Builds the MSFT_MicrosoftGraph* CIM class name for a complex type, suffixing on collision
    with classes already shipped by other resources.
#>
function Get-M365DSCUniqueCimClassName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TypeName,

        [Parameter()]
        [System.String[]]
        $ExistingCimClassNames = @()
    )

    $pascalTypeName = Get-StringFirstCharacterToUpper -Value $TypeName
    $cimClassName = "MSFT_MicrosoftGraph$pascalTypeName"

    if ($ExistingCimClassNames -contains $cimClassName)
    {
        $collisionCount = @($ExistingCimClassNames | Where-Object -FilterScript { $_ -like "$cimClassName*" }).Count
        $cimClassName += $collisionCount.ToString()
    }

    return $cimClassName
}
