<#
.SYNOPSIS
    Renders a drift result as a Markdown report.

.DESCRIPTION
    Every section states its count even when empty, otherwise two runs cannot be compared by
    eye. Nothing carries a timestamp or a run number: unchanged input has to render byte
    identical.

.PARAMETER Result
    Specifies the output of Compare-M365DSCApiSurface.

.OUTPUTS
    The Markdown text.
#>
function Format-DriftMarkdown
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Result
    )

    $lines = [System.Collections.Generic.List[System.String]]::new()
    $findings = @($Result.Findings)

    $lines.Add('# API surface drift')
    $lines.Add('')
    $lines.Add("Resource comparison: $($Result.Summary.compared) compared, $($Result.Summary.skipped) skipped.")
    $lines.Add("Undeclared vendor properties across compared resources: $($Result.Backlog).")
    $lines.Add('')

    foreach ($section in (Get-DriftSection))
    {
        $matched = @($findings | Where-Object -FilterScript { $_.code -in $section.Codes })
        $lines.Add("## $($section.Title)  ($($matched.Count))")
        $lines.Add('')

        if ($matched.Count -eq 0)
        {
            $lines.Add('None.')
            $lines.Add('')
            continue
        }

        if ($section.Title -eq 'Newer dependency versions available')
        {
            $lines.AddRange([System.String[]] @(Format-VersionSection -Finding $matched))
            continue
        }

        foreach ($finding in $matched)
        {
            $lines.Add("- ``$($finding.id)``")
            $lines.Add("      $(Get-FindingEvidenceLine -Finding $finding)")
        }

        $lines.Add('')
    }

    $lines.Add('## Coverage')
    $lines.Add('')

    $skipped = @($Result.Coverage | Where-Object -FilterScript { -not $_.compared })
    $byReason = @{}
    foreach ($row in $skipped)
    {
        $reason = [System.String] $row.reason
        $byReason[$reason] = 1 + $byReason[$reason]
    }

    foreach ($reason in (Get-M365DSCOrderedName -Value ([System.String[]] @($byReason.Keys))))
    {
        $lines.Add("- $($byReason[$reason]) resources skipped: $reason")
    }

    $lines.Add('')

    $backlog = @($Result.Coverage | Where-Object -FilterScript { $_.compared -and $_.backlog -gt 0 } |
            Sort-Object -Property @{ Expression = { $_.backlog }; Descending = $true }, @{ Expression = { $_.resource }; Ascending = $true })

    if ($backlog.Count -gt 0)
    {
        $lines.Add('Largest gaps between declared and offered properties:')
        $lines.Add('')
        foreach ($row in ($backlog | Select-Object -First 20))
        {
            $lines.Add("- $($row.resource): $($row.declared) of $($row.vendorTop) vendor properties declared")
        }
        $lines.Add('')
    }

    return ($lines -join "`n").TrimEnd() + "`n"
}

<#
.SYNOPSIS
    Renders the dependency section grouped by the size of the version jump.

.PARAMETER Finding
    Specifies the VND-NEWER-VERSION findings.

.OUTPUTS
    The Markdown lines.
#>
function Format-VersionSection
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter()]
        [AllowEmptyCollection()]
        [System.Object[]]
        $Finding = @()
    )

    $lines = [System.Collections.Generic.List[System.String]]::new()

    foreach ($jump in @('Major', 'Minor', 'Patch'))
    {
        $matched = @($Finding | Where-Object -FilterScript { $_.to.jump -eq $jump })
        if ($matched.Count -eq 0)
        {
            continue
        }

        $lines.Add("$jump ($($matched.Count))")
        foreach ($item in $matched)
        {
            $lines.Add("- ``$($item.id)``")
            $lines.Add("      $($item.from.version) -> $($item.to.version)")
        }

        $lines.Add('')
    }

    return [System.String[]] $lines
}

<#
.SYNOPSIS
    Returns the report sections and the finding codes each one holds.

.DESCRIPTION
    Order is by how urgently a maintainer has to act. The auto-fixable section comes first
    because it is the approval interface phase 4 reads back.

.OUTPUTS
    Objects with Title and Codes.
#>
function Get-DriftSection
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param ()

    return @(
        [PSCustomObject]@{ Title = 'Auto-fixable'; Codes = @('RES-ENUM-STALE', 'VND-ENUM-MEMBER-ADDED', 'RES-PROP-MISSING') }
        [PSCustomObject]@{ Title = 'Needs a decision'; Codes = @('VND-CMDLET-REMOVED', 'VND-CMDLET-REROUTED', 'VND-PARAM-TYPECHANGED', 'RES-PROP-ORPHANED', 'RES-TYPE-MISMATCH') }
        [PSCustomObject]@{ Title = 'Read-only, suggested for no implementation'; Codes = @('RES-PROP-READONLY') }
        [PSCustomObject]@{ Title = 'Vendor changes'; Codes = @('VND-TYPE-PROP-ADDED', 'VND-PARAM-ADDED') }
        [PSCustomObject]@{ Title = 'Newer dependency versions available'; Codes = @('VND-NEWER-VERSION') }
    )
}

<#
.SYNOPSIS
    Renders the one evidence line that sits under a finding id.

.PARAMETER Finding
    Specifies the finding.

.OUTPUTS
    The evidence text.
#>
function Get-FindingEvidenceLine
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Finding
    )

    $source = [System.String] $Finding.evidence.source
    if ([System.String]::IsNullOrEmpty($source))
    {
        $source = [System.String] $Finding.code
    }

    switch ([System.String] $Finding.code)
    {
        'VND-CMDLET-REMOVED'
        {
            $callers = @($Finding.evidence.calledBy)
            return "$source, called by $($callers.Count) resource(s): $((Get-M365DSCOrderedName -Value ([System.String[]] $callers)) -join ', ')"
        }
        'RES-ENUM-STALE'
        {
            return "$source, missing member(s): $(@($Finding.to.added) -join ', ')"
        }
        'VND-ENUM-MEMBER-ADDED'
        {
            return "$source, new member(s): $(@($Finding.to.added) -join ', ')"
        }
        'RES-TYPE-MISMATCH'
        {
            return "$source, declared $($Finding.from.typeConstraint), vendor $($Finding.to.vendorType)"
        }
        'RES-PROP-ORPHANED'
        {
            return "$source, declared $($Finding.from.typeConstraint), not offered by the vendor type"
        }
        'VND-PARAM-TYPECHANGED'
        {
            return "$source, $($Finding.from.type) -> $($Finding.to.type)"
        }
        'VND-CMDLET-REROUTED'
        {
            return "$source, $($Finding.from.method) $($Finding.from.uri) is gone"
        }
    }

    return $source
}
