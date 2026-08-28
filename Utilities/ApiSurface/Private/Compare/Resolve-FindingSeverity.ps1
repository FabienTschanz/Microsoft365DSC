<#
.SYNOPSIS
    Builds one finding object.

.DESCRIPTION
    The id is built only from the code, the subject and the property. Severity and
    auto-fixability come from the code table in 00-context.md, and a property excluded as
    Deferred drops to info whatever its code says.

.PARAMETER Code
    Specifies the finding code.

.PARAMETER Subject
    Specifies the resource name, or the cmdlet or type name for a vendor finding.

.PARAMETER Property
    Specifies the property, parameter or member the finding is about.

.PARAMETER Workload
    Specifies the workload the subject belongs to.

.PARAMETER Resource
    Specifies the resource the finding is actionable on, when there is one.

.PARAMETER From
    Specifies the previous state.

.PARAMETER To
    Specifies the new state, carrying raw vendor types. The orchestrator projects it into CLR
    types afterwards.

.PARAMETER Evidence
    Specifies where the finding came from.

.PARAMETER AutoFixable
    Overrides the code table default.

.PARAMETER Severity
    Overrides the code table default.

.OUTPUTS
    An ordered dictionary holding the finding.
#>
function New-M365DSCApiSurfaceFinding
{
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Code,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Subject,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $Property,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $Workload,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $Resource,

        [Parameter()]
        [AllowNull()]
        [System.Object]
        $From,

        [Parameter()]
        [AllowNull()]
        [System.Object]
        $To,

        [Parameter()]
        [AllowNull()]
        [System.Object]
        $Evidence,

        [Parameter()]
        [AllowNull()]
        [System.Object]
        $AutoFixable,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $Severity
    )

    $default = Resolve-FindingSeverity -Code $Code

    $id = "${Code}:$Subject"
    if (-not [System.String]::IsNullOrEmpty($Property))
    {
        $id = "${id}:$Property"
    }

    $resolvedSeverity = $Severity
    if ([System.String]::IsNullOrEmpty($resolvedSeverity))
    {
        $resolvedSeverity = $default.Severity
    }

    $resolvedAutoFixable = $AutoFixable
    if ($null -eq $resolvedAutoFixable)
    {
        $resolvedAutoFixable = $default.AutoFixable
    }

    return [ordered]@{
        id          = $id
        code        = $Code
        severity    = $resolvedSeverity
        autoFixable = [System.Boolean] $resolvedAutoFixable
        resource    = $Resource
        workload    = $Workload
        property    = $Property
        from        = $From
        to          = $To
        evidence    = $Evidence
        firstSeen   = $null
    }
}

<#
.SYNOPSIS
    Returns the default severity and auto-fixability of a finding code.

.DESCRIPTION
    Mirrors the code table in 00-context.md. An unknown code throws rather than defaulting,
    which would let a typo ship a finding nobody triages.

.PARAMETER Code
    Specifies the finding code.

.OUTPUTS
    An ordered dictionary with Severity and AutoFixable.
#>
function Resolve-FindingSeverity
{
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Code
    )

    $table = @{
        'VND-CMDLET-REMOVED'    = @{ Severity = 'breaking'; AutoFixable = $false }
        'VND-CMDLET-REROUTED'   = @{ Severity = 'breaking'; AutoFixable = $false }
        'VND-PARAM-ADDED'       = @{ Severity = 'info'; AutoFixable = $false }
        'VND-PARAM-TYPECHANGED' = @{ Severity = 'breaking'; AutoFixable = $false }
        'VND-TYPE-PROP-ADDED'   = @{ Severity = 'info'; AutoFixable = $false }
        'VND-ENUM-MEMBER-ADDED' = @{ Severity = 'warning'; AutoFixable = $true }
        'VND-NEWER-VERSION'     = @{ Severity = 'info'; AutoFixable = $false }
        'RES-PROP-MISSING'      = @{ Severity = 'warning'; AutoFixable = $true }
        'RES-PROP-READONLY'     = @{ Severity = 'info'; AutoFixable = $false }
        'RES-PROP-ORPHANED'     = @{ Severity = 'breaking'; AutoFixable = $false }
        'RES-TYPE-MISMATCH'     = @{ Severity = 'breaking'; AutoFixable = $false }
        'RES-ENUM-STALE'        = @{ Severity = 'warning'; AutoFixable = $true }
        'SHIM-MISSING'          = @{ Severity = 'breaking'; AutoFixable = $false }
        'SHIM-STALE'            = @{ Severity = 'warning'; AutoFixable = $true }
    }

    if (-not $table.ContainsKey($Code))
    {
        throw "Finding code '$Code' is not in the code table. Add it to 00-context.md and to Resolve-FindingSeverity."
    }

    return [ordered]@{
        Severity    = $table[$Code].Severity
        AutoFixable = $table[$Code].AutoFixable
    }
}

<#
.SYNOPSIS
    Applies a resource's excludedProperties list to a candidate finding.

.DESCRIPTION
    Four reasons suppress a finding outright. Deferred instead drops it to info, which keeps an
    acknowledged but postponed property on the report.

.PARAMETER Exclusion
    Specifies the excludedProperties entries of the resource.

.PARAMETER Property
    Specifies the DSC property name the finding is about.

.OUTPUTS
    An ordered dictionary with Suppressed, Severity and Reason.
#>
function Resolve-FindingExclusion
{
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [System.Object]
        $Exclusion,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Property
    )

    $result = [ordered]@{
        Suppressed = $false
        Severity   = $null
        Reason     = $null
    }

    foreach ($entry in @($Exclusion))
    {
        if ($null -eq $entry -or [System.String] $entry.name -ne $Property)
        {
            continue
        }

        $reason = [System.String] $entry.reason
        $result.Reason = $reason

        if ($reason -eq 'Deferred')
        {
            $result.Severity = 'info'
            return $result
        }

        $result.Suppressed = $true
        return $result
    }

    return $result
}
