<#
    Get()-side conversion: turns what the workload cmdlet returned into the hashtable a class
    resource builds its result from. Three pieces, all driven by the property models:

      - New-M365DSCComplexConversionBlock: the lines inside Get() that convert complex, enum and
        date properties into local variables.
      - New-M365DSCHashtableMappingBlock: the $result = @{ ... } body.
      - New-M365DSCHelperFunctionBlock: one Get-<Resource><Type>AsHashtable helper function per
        complex class, following the shipped hand-written resources' pattern (helper names are
        suffixed with the resource name because all resources share one module scope).
#>

<#
.SYNOPSIS
    Returns the Get()-side access path of a property on the cmdlet output object.
#>
function Get-M365DSCPropertyAccessPath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Property,

        [Parameter()]
        [System.String]
        $ObjectVariable = '$getValue'
    )

    if ($Property.IsFromAdditionalProperties)
    {
        if ($Property.GraphName -match '[^\w]')
        {
            return "$ObjectVariable.AdditionalProperties.'$($Property.GraphName)'"
        }

        return "$ObjectVariable.AdditionalProperties.$($Property.GraphName)"
    }

    return "$ObjectVariable.$($Property.Name)"
}

<#
.SYNOPSIS
    Renders the conversion statements that precede the $result hashtable in Get().
#>
function New-M365DSCComplexConversionBlock
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ResourceModel,

        [Parameter()]
        [System.Int32]
        $IndentCount = 12
    )

    $indent = ' ' * $IndentCount
    $builder = [System.Text.StringBuilder]::new()

    foreach ($property in $ResourceModel.SchemaProperties)
    {
        if (Test-M365DSCAssignmentProperty -Property $property)
        {
            # Assignments convert through their own block, after the result hashtable.
            continue
        }

        $path = Get-M365DSCPropertyAccessPath -Property $property
        $name = $property.Name

        if ($property.IsComplex)
        {
            $helperName = Get-M365DSCComplexHelperName -ResourceName $ResourceModel.ResourceName -CimClassName $property.CimClassName

            if ($property.IsArray)
            {
                $null = $builder.AppendLine("$indent`$complex$name = @()")
                $null = $builder.AppendLine("${indent}foreach (`$current$name in $path)")
                $null = $builder.AppendLine("$indent{")
                $null = $builder.AppendLine("$indent    `$complex$name += $helperName -ComplexObject `$current$name")
                $null = $builder.AppendLine("$indent}")
            }
            else
            {
                $null = $builder.AppendLine("$indent`$complex$name = $helperName -ComplexObject $path")
            }
            $null = $builder.AppendLine('')
        }
        elseif ($property.IsEnum -and $property.Name -ne 'Ensure')
        {
            if ($property.IsArray)
            {
                $null = $builder.AppendLine("$indent`$enum$name = [System.String[]]@($path | ForEach-Object { `$_.ToString() })")
            }
            else
            {
                $null = $builder.AppendLine("$indent`$enum$name = `$null")
                $null = $builder.AppendLine("${indent}if (`$null -ne $path)")
                $null = $builder.AppendLine("$indent{")
                $null = $builder.AppendLine("$indent    `$enum$name = $path.ToString()")
                $null = $builder.AppendLine("$indent}")
            }
            $null = $builder.AppendLine('')
        }
        elseif ($property.FakeKind -in @('DateTime', 'Time'))
        {
            $toString = ".ToUniversalTime().ToString('o')"
            if ($property.FakeKind -eq 'Time')
            {
                $toString = '.ToString()'
            }

            $null = $builder.AppendLine("$indent`$date$name = `$null")
            $null = $builder.AppendLine("${indent}if (`$null -ne $path)")
            $null = $builder.AppendLine("$indent{")
            $null = $builder.AppendLine("$indent    `$date$name = $path$toString")
            $null = $builder.AppendLine("$indent}")
            $null = $builder.AppendLine('')
        }
    }

    return $builder.ToString().TrimEnd()
}

<#
.SYNOPSIS
    Renders the body of the $result hashtable in Get().
#>
function New-M365DSCHashtableMappingBlock
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ResourceModel,

        [Parameter()]
        [System.Int32]
        $IndentCount = 16
    )

    $indent = ' ' * $IndentCount
    $builder = [System.Text.StringBuilder]::new()

    $longestName = ($ResourceModel.Properties | Measure-Object -Maximum { $_.Name.Length }).Maximum

    foreach ($property in $ResourceModel.Properties)
    {
        if (Test-M365DSCAssignmentProperty -Property $property)
        {
            # Added to the result after the hashtable, by the assignments Get block.
            continue
        }

        $name = $property.Name
        $padding = ' ' * ($longestName - $name.Length)

        if ($property.IsAuth)
        {
            $value = "`$this.$name"
        }
        elseif ($name -eq 'Ensure')
        {
            $value = "'Present'"
        }
        elseif ($name -eq 'IsSingleInstance')
        {
            $value = "'Yes'"
        }
        elseif ($property.IsComplex)
        {
            $value = "`$complex$name"
            if ($property.IsArray)
            {
                $value = "[Array]`$complex$name"
            }
        }
        elseif ($property.IsEnum)
        {
            $value = "`$enum$name"
        }
        elseif ($property.FakeKind -in @('DateTime', 'Time'))
        {
            $value = "`$date$name"
        }
        else
        {
            $value = Get-M365DSCPropertyAccessPath -Property $property
        }

        $null = $builder.AppendLine("$indent$name$padding = $value")
    }

    return $builder.ToString().TrimEnd()
}

<#
.SYNOPSIS
    Renders one Get-<Resource><Type>AsHashtable helper function per complex class.
#>
function New-M365DSCHelperFunctionBlock
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ResourceModel
    )

    $builder = [System.Text.StringBuilder]::new()
    $first = $true

    foreach ($complexClass in $ResourceModel.ComplexTypeClasses)
    {
        if ($complexClass.CimClassName -eq 'MSFT_DeviceManagementConfigurationPolicyAssignments')
        {
            # Assignments convert through ConvertFrom-IntunePolicyAssignment, not a helper.
            continue
        }

        if (-not $first)
        {
            $null = $builder.AppendLine('')
        }
        $first = $false

        $helperName = Get-M365DSCComplexHelperName -ResourceName $ResourceModel.ResourceName -CimClassName $complexClass.CimClassName

        $null = $builder.AppendLine("function $helperName")
        $null = $builder.AppendLine('{')
        $null = $builder.AppendLine('    [CmdletBinding()]')
        $null = $builder.AppendLine('    [OutputType([System.Collections.Hashtable])]')
        $null = $builder.AppendLine('    param')
        $null = $builder.AppendLine('    (')
        $null = $builder.AppendLine('        [Parameter()]')
        $null = $builder.AppendLine('        [System.Object]')
        $null = $builder.AppendLine('        $ComplexObject')
        $null = $builder.AppendLine('    )')
        $null = $builder.AppendLine('')
        $null = $builder.AppendLine('    if ($null -eq $ComplexObject)')
        $null = $builder.AppendLine('    {')
        $null = $builder.AppendLine('        return $null')
        $null = $builder.AppendLine('    }')
        $null = $builder.AppendLine('')
        $null = $builder.AppendLine('    $result = @{}')
        $null = $builder.AppendLine('')

        foreach ($member in $complexClass.Members)
        {
            $memberName = $member.Name

            if ($member.GraphName -eq '@odata.type')
            {
                # Typed SDK objects keep the discriminator in AdditionalProperties; plain
                # hashtables carry it directly.
                $null = $builder.AppendLine("    `$odataType = `$ComplexObject.AdditionalProperties.'@odata.type'")
                $null = $builder.AppendLine("    if (`$null -eq `$odataType)")
                $null = $builder.AppendLine('    {')
                $null = $builder.AppendLine("        `$odataType = `$ComplexObject.'@odata.type'")
                $null = $builder.AppendLine('    }')
                $null = $builder.AppendLine("    if (`$null -ne `$odataType)")
                $null = $builder.AppendLine('    {')
                $null = $builder.AppendLine("        `$result.Add('$memberName', `$odataType.ToString())")
                $null = $builder.AppendLine('    }')
                $null = $builder.AppendLine('')
                continue
            }

            $memberPath = "`$ComplexObject.$($member.GraphName)"

            if ($member.IsComplex)
            {
                $nestedHelperName = Get-M365DSCComplexHelperName -ResourceName $ResourceModel.ResourceName -CimClassName $member.CimClassName

                if ($member.IsArray)
                {
                    $null = $builder.AppendLine("    `$nested$memberName = @()")
                    $null = $builder.AppendLine("    foreach (`$current$memberName in $memberPath)")
                    $null = $builder.AppendLine('    {')
                    $null = $builder.AppendLine("        `$nested$memberName += $nestedHelperName -ComplexObject `$current$memberName")
                    $null = $builder.AppendLine('    }')
                    $null = $builder.AppendLine("    if (`$nested$memberName.Count -gt 0)")
                    $null = $builder.AppendLine('    {')
                    $null = $builder.AppendLine("        `$result.Add('$memberName', [Array]`$nested$memberName)")
                    $null = $builder.AppendLine('    }')
                }
                else
                {
                    $null = $builder.AppendLine("    `$nested$memberName = $nestedHelperName -ComplexObject $memberPath")
                    $null = $builder.AppendLine("    if (`$null -ne `$nested$memberName)")
                    $null = $builder.AppendLine('    {')
                    $null = $builder.AppendLine("        `$result.Add('$memberName', `$nested$memberName)")
                    $null = $builder.AppendLine('    }')
                }
                $null = $builder.AppendLine('')
                continue
            }

            $valueExpression = $memberPath
            if ($member.IsEnum)
            {
                if ($member.IsArray)
                {
                    $valueExpression = "[System.String[]]@($memberPath | ForEach-Object { `$_.ToString() })"
                }
                else
                {
                    $valueExpression = "$memberPath.ToString()"
                }
            }
            elseif ($member.FakeKind -eq 'DateTime')
            {
                $valueExpression = "$memberPath.ToUniversalTime().ToString('o')"
            }
            elseif ($member.FakeKind -eq 'Time')
            {
                $valueExpression = "$memberPath.ToString()"
            }
            elseif ($member.IsArray)
            {
                $valueExpression = "[Array]$memberPath"
            }

            $null = $builder.AppendLine("    if (`$null -ne $memberPath)")
            $null = $builder.AppendLine('    {')
            $null = $builder.AppendLine("        `$result.Add('$memberName', $valueExpression)")
            $null = $builder.AppendLine('    }')
            $null = $builder.AppendLine('')
        }

        $null = $builder.AppendLine('    if ($result.Count -eq 0)')
        $null = $builder.AppendLine('    {')
        $null = $builder.AppendLine('        return $null')
        $null = $builder.AppendLine('    }')
        $null = $builder.AppendLine('')
        $null = $builder.AppendLine('    return $result')
        $null = $builder.AppendLine('}')
    }

    return $builder.ToString().TrimEnd()
}

<#
.SYNOPSIS
    Builds the resource-suffixed helper function name for a complex class.
#>
function Get-M365DSCComplexHelperName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $CimClassName
    )

    $baseName = $CimClassName -replace '^MSFT_MicrosoftGraph', '' -replace '^MSFT_', ''
    return "Get-$ResourceName$($baseName)AsHashtable"
}
