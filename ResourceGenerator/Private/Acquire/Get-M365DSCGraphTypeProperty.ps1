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

    $definition = Get-M365DSCGraphTypeDefinition -Schema $Schema -Entity $Entity
    if ($null -eq $definition)
    {
        Write-Warning -Message "Type '$Entity' was not found in the Graph metadata."
        return @()
    }

    $namespace = $definition.Schema
    $derivedSubtypeNames = $definition.DerivedSubtypeNames

    $rawEntries = @($definition.Properties)
    if ($IncludeNavigationProperties)
    {
        $rawEntries += @($definition.NavigationProperties)
    }

    # Project the raw nodes into property models.
    $models = @()

    foreach ($rawEntry in $rawEntries)
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

        $description = Get-M365DSCGraphPropertyDescription -Schema $Schema `
            -Property $rawProperty `
            -NamespaceName $rawEntry.DeclaringNamespace `
            -TypeName $rawEntry.DeclaringType

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

.PARAMETER Schema
    Specifies the CSDL schema nodes.

.PARAMETER Property
    Specifies the property node.

.PARAMETER NamespaceName
    Specifies the namespace declaring the property, for example 'microsoft.graph.networkaccess'.

.PARAMETER TypeName
    Specifies the declaring type. Defaults to the parent node of the property.

.OUTPUTS
    The description, or an empty string.
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
        $Property,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $NamespaceName = 'microsoft.graph',

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $TypeName
    )

    $description = Get-M365DSCGraphAnnotationDescription -Annotation $Property.Annotation

    if ([System.String]::IsNullOrWhiteSpace($description))
    {
        if ([System.String]::IsNullOrEmpty($NamespaceName))
        {
            $NamespaceName = 'microsoft.graph'
        }

        if ([System.String]::IsNullOrEmpty($TypeName))
        {
            $TypeName = [System.String] $Property.ParentNode.Name
        }

        $target = "$NamespaceName.$TypeName/$($Property.Name)"
        $annotation = $Schema.Annotations | Where-Object -FilterScript { $_.Target -like $target }
        $description = Get-M365DSCGraphAnnotationDescription -Annotation $annotation.Annotation
    }

    if ([System.String]::IsNullOrEmpty($description))
    {
        return ''
    }

    $description = $description.Replace('"', "'")
    # Keep letters, digits and basic punctuation only - Description attributes choke on the rest.
    return ($description -replace '[^\p{L}\p{Nd}/(/}/_ -.,=:)'']', '')
}

<#
.SYNOPSIS
    Returns the Description string out of a set of CSDL annotations.

.DESCRIPTION
    A node can carry several annotations. Reading String off the set yields an array whose
    capability entries are null, which fails on the first string operation.

.PARAMETER Annotation
    Specifies the annotation nodes.

.OUTPUTS
    The description, or an empty string.
#>
function Get-M365DSCGraphAnnotationDescription
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [System.Object]
        $Annotation
    )

    foreach ($entry in @($Annotation))
    {
        if ($null -eq $entry)
        {
            continue
        }

        if (([System.String] $entry.Term) -eq 'Org.OData.Core.V1.Description')
        {
            return [System.String] $entry.String
        }
    }

    return ''
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
