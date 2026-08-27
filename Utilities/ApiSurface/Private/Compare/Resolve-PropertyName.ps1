<#
.SYNOPSIS
    Matches a DSC property name against the vendor property set.

.DESCRIPTION
    A resource that flattens a complex type concatenates the path into one name, so
    'SignInFrequencyIsEnabled' is 'sessionControls.signInFrequency.isEnabled'. Rules are tried
    most exact first and the winner is reported.

.PARAMETER Name
    Specifies the declared DSC property name.

.PARAMETER VendorProperty
    Specifies the expanded vendor property set from Expand-VendorPropertySet.

.OUTPUTS
    An ordered dictionary with Matched, VendorName and Rule.
#>
function Resolve-PropertyName
{
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]
        $VendorProperty
    )

    foreach ($candidate in (Get-PropertyNameCandidate -Name $Name))
    {
        if ($VendorProperty.Contains($candidate.Value))
        {
            return [ordered]@{
                Matched    = $true
                VendorName = $candidate.Value
                Rule       = $candidate.Rule
            }
        }
    }

    $lowered = $Name.ToLowerInvariant()
    foreach ($vendorName in $VendorProperty.Keys)
    {
        if ($vendorName.ToLowerInvariant() -eq $lowered)
        {
            return [ordered]@{
                Matched    = $true
                VendorName = $vendorName
                Rule       = 'CaseInsensitive'
            }
        }
    }

    foreach ($vendorName in $VendorProperty.Keys)
    {
        $path = $VendorProperty[$vendorName].Path
        if ([System.String]::IsNullOrEmpty($path))
        {
            continue
        }

        if (($path -replace '\.', '').ToLowerInvariant() -eq $lowered)
        {
            return [ordered]@{
                Matched    = $true
                VendorName = $vendorName
                Rule       = 'FlattenedPath'
            }
        }

        # A flattening resource usually drops the plural on the container, so grantControls.operator
        # is declared as GrantControlOperator.
        $singular = @($path -split '\.' | ForEach-Object -Process { $_ -replace 's$', '' }) -join ''
        if ($singular.ToLowerInvariant() -eq $lowered)
        {
            return [ordered]@{
                Matched    = $true
                VendorName = $vendorName
                Rule       = 'FlattenedPathSingular'
            }
        }
    }

    return [ordered]@{
        Matched    = $false
        VendorName = $null
        Rule       = 'None'
    }
}

<#
.SYNOPSIS
    Lists the vendor spellings a DSC property name can take, most exact first.

.PARAMETER Name
    Specifies the declared DSC property name.

.OUTPUTS
    Objects with Value and Rule.
#>
function Get-PropertyNameCandidate
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $candidates = [System.Collections.Generic.List[System.Object]]::new()
    $candidates.Add([PSCustomObject]@{ Value = $Name; Rule = 'Exact' })

    $camel = $Name.Substring(0, 1).ToLowerInvariant() + $Name.Substring(1)
    $candidates.Add([PSCustomObject]@{ Value = $camel; Rule = 'Camel' })

    if ($Name -eq 'ODataType')
    {
        $candidates.Add([PSCustomObject]@{ Value = '@odata.type'; Rule = 'ODataType' })
    }

    # A leading run of capitals is one acronym, so 'MDMAuthority' answers to 'mdmAuthority'.
    if ($Name -cmatch '^([A-Z]{2,})(?=[A-Z][a-z]|$)')
    {
        $acronym = $Matches[1]
        $candidates.Add([PSCustomObject]@{
                Value = $acronym.ToLowerInvariant() + $Name.Substring($acronym.Length)
                Rule  = 'Acronym'
            })
    }

    return $candidates.ToArray()
}

<#
.SYNOPSIS
    Turns a vendor property name into the DSC spelling a resource would declare.

.PARAMETER Name
    Specifies the vendor property name.

.OUTPUTS
    The PascalCase name.
#>
function ConvertTo-DscPropertyName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    if ($Name -eq '@odata.type')
    {
        return 'ODataType'
    }

    return $Name.Substring(0, 1).ToUpperInvariant() + $Name.Substring(1)
}
