<#
.SYNOPSIS
    Copies a map into an ordered dictionary whose keys are sorted ordinally.

.DESCRIPTION
    Hashtable enumeration order in PowerShell is not stable and Sort-Object applies the current
    culture. Every map that reaches the snapshot goes through here, and ordinal sorting keeps two
    runs on two machines byte identical.

    The result compares keys ordinally as well. A plain [ordered]@{} is case insensitive and would
    drop one of two CSDL names that differ only in case.

.PARAMETER Map
    Specifies the map to order.

.OUTPUTS
    An ordered dictionary.
#>
function ConvertTo-M365DSCOrderedMap
{
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary]
        $Map
    )

    $keys = [System.String[]] @($Map.Keys)
    [System.Array]::Sort($keys, [System.StringComparer]::Ordinal)

    $ordered = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
    foreach ($key in $keys)
    {
        $ordered[$key] = $Map[$key]
    }

    return $ordered
}

<#
.SYNOPSIS
    Returns a string collection in ordinal order.

.DESCRIPTION
    Sort-Object applies the current culture, which orders names differently on a machine with a
    different locale. Every list that reaches the snapshot goes through here instead.

.PARAMETER Value
    Specifies the strings to sort.

.OUTPUTS
    The sorted strings.
#>
function Get-M365DSCOrderedName
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]
        $Value = @()
    )

    $names = [System.String[]] @($Value)
    [System.Array]::Sort($names, [System.StringComparer]::Ordinal)

    return $names
}

<#
.SYNOPSIS
    Serializes an API surface snapshot into the text that lands in api-surface.json.

.DESCRIPTION
    The single place that decides how the snapshot is written, with a fixed depth and CRLF line
    endings. Every writer uses it, and a snapshot taken by a developer compares byte for byte with
    one taken by CI.

.PARAMETER Surface
    Specifies the snapshot from Get-M365DSCApiSurface.

.OUTPUTS
    The JSON text.
#>
function ConvertTo-M365DSCApiSurfaceJson
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Surface
    )

    process
    {
        return ($Surface | ConvertTo-Json -Depth 20) -replace "`r`n", "`n" -replace "`n", "`r`n"
    }
}
