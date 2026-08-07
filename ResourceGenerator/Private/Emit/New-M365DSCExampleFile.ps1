<#
.SYNOPSIS
    Emits the three example configurations of a resource: 1-Create, 2-Update and 3-Remove.

.DESCRIPTION
    Unlike the old generator - which wrote the same placeholder into all three files - the
    examples are genuinely distinct: Create uses the fake desired-state values, Update drifts
    them, and Remove keeps only the key properties with Ensure = 'Absent'. Complex properties
    render as DSC CIM instance blocks (MSFT_Xyz { ... }).

.PARAMETER ResourceModel
    Specifies the resource model.

.PARAMETER DestinationFolder
    Specifies the folder receiving 1-Create.ps1, 2-Update.ps1 and 3-Remove.ps1.
#>
function New-M365DSCExampleFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ResourceModel,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DestinationFolder
    )

    $templatePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Templates\Example.Template.ps1'

    $examples = @(
        @{ FileName = '1-Create.ps1'; Drift = $false; Ensure = 'Present'; KeysOnly = $false }
        @{ FileName = '2-Update.ps1'; Drift = $true; Ensure = 'Present'; KeysOnly = $false }
        @{ FileName = '3-Remove.ps1'; Drift = $false; Ensure = 'Absent'; KeysOnly = $true }
    )

    foreach ($example in $examples)
    {
        $valueBlock = New-M365DSCExampleValueBlock -ResourceModel $ResourceModel `
            -Drift $example.Drift `
            -Ensure $example.Ensure `
            -KeysOnly $example.KeysOnly

        $tokens = @{
            ResourceName = $ResourceModel.ResourceName
            FakeValues   = $valueBlock
        }

        $destination = Join-Path -Path $DestinationFolder -ChildPath $example.FileName
        Expand-M365DSCTemplate -TemplatePath $templatePath -Tokens $tokens -DestinationPath $destination
    }
}

<#
.SYNOPSIS
    Renders the property assignments of one example resource block.
#>
function New-M365DSCExampleValueBlock
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ResourceModel,

        [Parameter()]
        [System.Boolean]
        $Drift = $false,

        [Parameter()]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Boolean]
        $KeysOnly = $false
    )

    $indent = ' ' * 12
    $entries = [ordered]@{}

    foreach ($property in $ResourceModel.SchemaProperties)
    {
        if ($KeysOnly -and -not $property.IsKey -and $property.Name -ne $ResourceModel.AlternativeKey)
        {
            continue
        }

        # Keys must stay stable between the create, update and remove examples.
        $value = $property.FakeValue
        if ($Drift -and -not $property.IsKey)
        {
            $driftValue = $property.DriftValue
            if ($null -ne $driftValue)
            {
                $value = $driftValue
            }
        }

        if ($null -eq $value)
        {
            continue
        }

        $entries[$property.Name] = ConvertTo-M365DSCExampleValue -Property $property -Value $value -IndentCount 12
    }

    if (-not $ResourceModel.IsSingleInstance)
    {
        $entries['Ensure'] = "`"$Ensure`""
    }
    else
    {
        $entries['IsSingleInstance'] = '"Yes"'
    }

    $entries['ApplicationId'] = '$ApplicationId'
    $entries['TenantId'] = '$TenantId'
    $entries['CertificateThumbprint'] = '$CertificateThumbprint'

    $longestName = ($entries.Keys | Measure-Object -Property Length -Maximum).Maximum
    $builder = [System.Text.StringBuilder]::new()
    foreach ($entryName in $entries.Keys)
    {
        $padding = ' ' * ($longestName - $entryName.Length)
        $null = $builder.AppendLine('')
        # Every property line ends with a semicolon - including the closing line of a CIM
        # instance value, but never the lines inside one.
        $null = $builder.Append("$indent$entryName$padding = $($entries[$entryName]);")
    }

    return $builder.ToString()
}

<#
.SYNOPSIS
    Renders one example value; complex properties become DSC CIM instance blocks.
#>
function ConvertTo-M365DSCExampleValue
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Property,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $Value,

        [Parameter()]
        [System.Int32]
        $IndentCount = 12
    )

    if (-not $Property.IsComplex)
    {
        return (ConvertTo-M365DSCPSLiteral -Value $Value -IndentCount $IndentCount -DoubleQuoteStrings)
    }

    $indent = ' ' * $IndentCount
    $childIndent = ' ' * ($IndentCount + 4)
    $grandChildIndent = ' ' * ($IndentCount + 8)

    $instances = @($Value)
    $builder = [System.Text.StringBuilder]::new()

    if ($Property.IsArray)
    {
        $null = $builder.AppendLine('@(')
    }

    foreach ($instance in $instances)
    {
        $instanceIndent = $indent
        $memberIndent = $childIndent
        if ($Property.IsArray)
        {
            $instanceIndent = $childIndent
            $memberIndent = $grandChildIndent
            $null = $builder.AppendLine("$instanceIndent$($Property.CimClassName){")
        }
        else
        {
            # Single instance: the class name continues the '<Name> = ' line, so no leading
            # indent, and the opening brace sits directly against the class name.
            $null = $builder.AppendLine("$($Property.CimClassName){")
        }

        $memberEntries = [ordered]@{}
        foreach ($member in $Property.Members)
        {
            if ($instance -is [System.Collections.IDictionary] -and $instance.Contains($member.Name) -and $null -ne $instance[$member.Name])
            {
                $memberEntries[$member.Name] = ConvertTo-M365DSCExampleValue -Property $member -Value $instance[$member.Name] -IndentCount ($IndentCount + 8)
            }
        }

        $longestName = 1
        if ($memberEntries.Count -gt 0)
        {
            $longestName = ($memberEntries.Keys | Measure-Object -Property Length -Maximum).Maximum
        }

        foreach ($memberName in $memberEntries.Keys)
        {
            $padding = ' ' * ($longestName - $memberName.Length)
            $null = $builder.AppendLine("$memberIndent$memberName$padding = $($memberEntries[$memberName])")
        }

        $null = $builder.AppendLine("$instanceIndent}")
    }

    if ($Property.IsArray)
    {
        $null = $builder.Append("$indent)")
    }

    return $builder.ToString().TrimEnd()
}
