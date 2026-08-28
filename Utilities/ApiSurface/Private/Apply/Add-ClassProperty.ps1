<#
.SYNOPSIS
    Builds the edits that declare a new scalar or enum property on a resource.

.DESCRIPTION
    Two edits, both required. The declaration alone leaves the property null forever, because
    Get() fills the instance from the hashtable it hands to AsResult and nothing else writes the
    property.

    The declaration is rendered by the resource generator's New-M365DSCClassPropertyBlock. It goes
    before Ensure, or before the first auth property on a singleton, because shipped resources keep
    their MOF era order and there is no alphabetical slot to aim at.

    The declaration is built from the generator's own CSDL walk rather than from the finding. The
    snapshot carries no descriptions by design, and every declaration needs one, so the model comes
    from Get-M365DSCGraphTypeProperty for the entity named in generatedFrom. That also makes the
    rendered block identical to what New-M365DSCResource would emit.

    The unit test and the examples are NOT touched. A new property needs a value in the API mock,
    one in every Context of the test file, and an entry in Examples/Resources, which is more than a
    splice can decide. Per finding verification runs the resource test, so an unfinished addition
    reverts itself and is reported as scaffold and review.

.PARAMETER ClassEdit
    Specifies the parsed resource from Get-ResourceClassEdit.

.PARAMETER Finding
    Specifies the RES-PROP-MISSING finding.

.PARAMETER Generator
    Specifies the resource generator module.

.PARAMETER Origin
    Specifies the generatedFrom block of the resource.

.OUTPUTS
    The edit records.
#>
function Add-ClassProperty
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]
        $ClassEdit,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $Finding,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $Generator,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $Origin
    )

    $name = [System.String] $Finding.property
    if ($ClassEdit.Property.Contains($name))
    {
        throw "'$($ClassEdit.ClassName)' already declares '$name'."
    }

    if ($ClassEdit.InsertOffset -lt 0)
    {
        throw "'$($ClassEdit.ClassName)' carries neither an Ensure nor an auth property to anchor on."
    }

    if ($null -eq $ClassEdit.ResultHashtable)
    {
        throw "The Get() result hashtable of '$($ClassEdit.ClassName)' could not be resolved. Apply this one by hand."
    }

    $model = Get-VendorPropertyModel -Name $name -Origin $Origin -Generator $Generator

    $declaration = & $Generator {
        param ($Model)

        return New-M365DSCClassPropertyBlock -Properties @($Model)
    } $model

    $edits = @(New-ResourceEdit -Offset $ClassEdit.InsertOffset `
            -Length 0 `
            -Text ("$($declaration.Trim())`r`n`r`n    ") `
            -Reason "Declaration of $($ClassEdit.ClassName).$name")

    $edits += Add-ResultHashtableEntry -ClassEdit $ClassEdit -Name $model.Name -GraphName $model.GraphName

    return $edits
}

<#
.SYNOPSIS
    Returns the generator's own property model for a vendor property.

.DESCRIPTION
    Walks the CSDL entity the resource was generated from and picks the model whose name matches.
    The walk is the generator's, so the description, the CLR type, the nullability and the
    ValidateSet are the ones New-M365DSCResource would have emitted. Building a model from the
    finding instead would ship a declaration with no description, which every resource has and the
    class convention tests require.

.PARAMETER Name
    Specifies the declared property name.

.PARAMETER Origin
    Specifies the generatedFrom block, which names the entity type and the API version.

.PARAMETER Generator
    Specifies the resource generator module.

.OUTPUTS
    The property model.
#>
function Get-VendorPropertyModel
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $Origin,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $Generator
    )

    $entityType = [System.String] $Origin.entityType
    if (-not [System.String]::IsNullOrEmpty([System.String] $Origin.odataSubtype))
    {
        $entityType = [System.String] $Origin.odataSubtype
    }

    if ([System.String]::IsNullOrEmpty($entityType))
    {
        throw 'generatedFrom names no entity type, so the vendor description cannot be resolved.'
    }

    $models = & $Generator {
        param ($ApiVersion, $Entity, $IncludeNavigation)

        $schema = Get-M365DSCGraphCsdlMetadata -APIVersion $ApiVersion
        return @(Get-M365DSCGraphTypeProperty -Schema $schema `
                -Entity $Entity `
                -IncludeNavigationProperties $IncludeNavigation)
    } ([System.String] $Origin.apiVersion) ($entityType -replace '^.*\.', '') ([System.Boolean] $Origin.includeNavigationProperties)

    $model = @($models | Where-Object -FilterScript { $_.Name -eq $Name })[0]
    if ($null -eq $model)
    {
        throw "'$Name' was not found on the CSDL type '$entityType'."
    }

    return $model
}

<#
.SYNOPSIS
    Builds the edit that adds the property to the Get() result hashtable.

.DESCRIPTION
    The value expression reuses the accessor the surrounding entries already use, which is
    $getValue in the generated resources and varies in the hand written ones. Alignment follows
    the column the block already uses. A name longer than that column widens only its own line,
    where the generator would have reflowed the whole block.

.PARAMETER ClassEdit
    Specifies the parsed resource.

.PARAMETER Name
    Specifies the declared property name.

.PARAMETER GraphName
    Specifies the vendor property name the accessor reads.

.OUTPUTS
    An edit record.
#>
function Add-ResultHashtableEntry
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]
        $ClassEdit,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GraphName
    )

    $pairs = @($ClassEdit.ResultHashtable.KeyValuePairs)
    $anchor = $null
    foreach ($wanted in @('Ensure', 'Credential', 'ApplicationId', 'AccessTokens'))
    {
        $anchor = @($pairs | Where-Object -FilterScript { $_.Item1.Extent.Text -eq $wanted })[0]
        if ($null -ne $anchor)
        {
            break
        }
    }

    if ($null -eq $anchor)
    {
        throw "The Get() result hashtable of '$($ClassEdit.ClassName)' carries no Ensure or auth entry to anchor on."
    }

    $accessor = Get-ResultAccessorPrefix -Pair $pairs
    if ([System.String]::IsNullOrEmpty($accessor))
    {
        throw "No accessor could be derived from the Get() result hashtable of '$($ClassEdit.ClassName)'."
    }

    $keyOffset = $anchor.Item1.Extent.StartOffset
    $lineStart = $ClassEdit.Text.LastIndexOf("`n", $keyOffset) + 1
    $indent = $ClassEdit.Text.Substring($lineStart, $keyOffset - $lineStart)

    $column = ($anchor.Item2.Extent.StartOffset - $keyOffset) - 2
    $padding = ' ' * [System.Math]::Max($column - $Name.Length, 1)

    return @(New-ResourceEdit -Offset $lineStart `
            -Length 0 `
            -Text "$indent$Name$padding= $accessor$GraphName`r`n" `
            -Reason "Get() entry for $($ClassEdit.ClassName).$Name")
}

<#
.SYNOPSIS
    Returns the accessor prefix the result hashtable already uses, for example '$getValue.'.

.PARAMETER Pair
    Specifies the key value pairs of the hashtable.

.OUTPUTS
    The prefix, or an empty string.
#>
function Get-ResultAccessorPrefix
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Object[]]
        $Pair
    )

    $counts = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)

    foreach ($item in $Pair)
    {
        $value = [System.String] $item.Item2.Extent.Text
        if ($value -notmatch '^(\$[A-Za-z_][A-Za-z0-9_]*\.)[A-Za-z_]')
        {
            continue
        }

        $prefix = $Matches[1]
        if ($prefix -eq '$this.')
        {
            continue
        }

        $counts[$prefix] = 1 + $counts[$prefix]
    }

    $best = ''
    $bestCount = 0
    foreach ($key in (Get-M365DSCOrderedName -Value ([System.String[]] @($counts.Keys))))
    {
        if ($counts[$key] -gt $bestCount)
        {
            $best = $key
            $bestCount = $counts[$key]
        }
    }

    return $best
}
