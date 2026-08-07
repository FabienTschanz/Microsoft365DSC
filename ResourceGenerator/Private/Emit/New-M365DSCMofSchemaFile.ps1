<#
.SYNOPSIS
    Emits the MOF schema of a resource from the same property models that drive the class.

.DESCRIPTION
    Because the MOF and the class render the same model in the same order, the two cannot drift
    apart. Embedded CIM classes (complex types) are emitted first, depth-first, then the resource
    class itself.

.PARAMETER ResourceModel
    Specifies the resource model.

.PARAMETER DestinationPath
    Specifies the MOF file to write. When omitted the content is returned as a string.
#>
function New-M365DSCMofSchemaFile
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ResourceModel,

        [Parameter()]
        [System.String]
        $DestinationPath
    )

    $builder = [System.Text.StringBuilder]::new()

    foreach ($complexClass in $ResourceModel.ComplexTypeClasses)
    {
        $null = $builder.AppendLine('[ClassVersion("1.0.0")]')
        $null = $builder.AppendLine("class $($complexClass.CimClassName)")
        $null = $builder.AppendLine('{')
        foreach ($member in $complexClass.Members)
        {
            $null = $builder.AppendLine((New-M365DSCMofPropertyLine -Property $member))
        }
        $null = $builder.AppendLine('};')
        $null = $builder.AppendLine('')
    }

    $null = $builder.AppendLine("[ClassVersion(`"1.0.0.0`"), FriendlyName(`"$($ResourceModel.ResourceName)`")]")
    $null = $builder.AppendLine("class MSFT_$($ResourceModel.ResourceName) : OMI_BaseResource")
    $null = $builder.AppendLine('{')
    foreach ($property in $ResourceModel.Properties)
    {
        $null = $builder.AppendLine((New-M365DSCMofPropertyLine -Property $property))
    }
    $null = $builder.AppendLine('};')

    $content = $builder.ToString()

    if ($PSBoundParameters.ContainsKey('DestinationPath'))
    {
        Set-Content -Path $DestinationPath -Value $content -NoNewline -Encoding UTF8
        return $null
    }

    return $content
}

<#
.SYNOPSIS
    Renders one MOF property declaration.
#>
function New-M365DSCMofPropertyLine
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Property
    )

    $qualifiers = @()
    if ($Property.IsKey)
    {
        $qualifiers += 'Key'
    }
    elseif ($Property.IsMandatory)
    {
        $qualifiers += 'Required'
    }
    else
    {
        $qualifiers += 'Write'
    }

    $escapedDescription = $Property.Description.Replace('\', '\\').Replace('"', '\"')
    $qualifiers += "Description(`"$escapedDescription`")"

    if ($Property.IsEnum)
    {
        $valueList = '"' + ($Property.EnumValues -join '","') + '"'
        $qualifiers += "ValueMap{$valueList}"
        $qualifiers += "Values{$valueList}"
    }

    if (-not [System.String]::IsNullOrEmpty($Property.MofEmbeddedInstance))
    {
        $qualifiers += "EmbeddedInstance(`"$($Property.MofEmbeddedInstance)`")"
    }

    $arraySuffix = ''
    if ($Property.IsArray)
    {
        $arraySuffix = '[]'
    }

    return "    [$($qualifiers -join ', ')] $($Property.MofType) $($Property.Name)$arraySuffix;"
}
