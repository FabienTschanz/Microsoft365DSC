<#
.SYNOPSIS
    Renders a drift result as the body of the weekly tracking Issue.

.DESCRIPTION
    The first section is the approval interface. Each auto-fixable finding is a task list item
    carrying its id in backticks, one per line, and phase 4 filters on exactly those strings.
    Nothing carries a timestamp or a run URL: unchanged input has to render byte identical.

.PARAMETER Result
    Specifies the output of Compare-M365DSCApiSurface.

.PARAMETER Ticked
    Specifies the finding ids a maintainer already ticked, carried over from the current body.

.OUTPUTS
    The Issue body text.
#>
function Format-DriftIssueBody
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Result,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]
        $Ticked = @()
    )

    $tickedSet = [System.Collections.Generic.HashSet[System.String]]::new(
        [System.String[]] $Ticked, [System.StringComparer]::Ordinal)

    $findings = @($Result.Findings)
    $lines = [System.Collections.Generic.List[System.String]]::new()

    $sections = @(Get-DriftSection)
    $first = $sections[0]
    $autoFixable = @($findings | Where-Object -FilterScript { $_.code -in $first.Codes -and $_.autoFixable })

    $lines.Add("## Auto-fixable  (tick, then comment /apply-drift)  ($($autoFixable.Count))")
    $lines.Add('')

    if ($autoFixable.Count -eq 0)
    {
        $lines.Add('None.')
    }
    else
    {
        foreach ($finding in $autoFixable)
        {
            $box = '- [ ]'
            if ($tickedSet.Contains([System.String] $finding.id))
            {
                $box = '- [x]'
            }

            $lines.Add("$box ``$($finding.id)``")
            $lines.Add("      $(Get-FindingEvidenceLine -Finding $finding)")
        }
    }

    $lines.Add('')
    $lines.Add('<details>')
    $lines.Add('')

    foreach ($section in ($sections | Select-Object -Skip 1))
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

    $skipped = @($Result.Coverage | Where-Object -FilterScript { -not $_.compared })
    $lines.Add("## Coverage gaps  ($($skipped.Count))")
    $lines.Add('')
    $lines.Add("$($Result.Summary.compared) resources compared, $($Result.Summary.skipped) skipped, $($Result.Backlog) undeclared vendor properties.")
    $lines.Add('')

    $unaccepted = @($findings | Where-Object -FilterScript { $_.severity -eq 'breaking' })
    $lines.Add("## Unaccepted breaking findings  ($($unaccepted.Count))")
    $lines.Add('')

    if ($unaccepted.Count -eq 0)
    {
        $lines.Add('None.')
    }
    else
    {
        foreach ($finding in $unaccepted)
        {
            $lines.Add("- ``$($finding.id)``  first seen $($finding.firstSeen)")
        }
    }

    $lines.Add('')
    $lines.Add('</details>')

    return ($lines -join "`n").TrimEnd() + "`n"
}

<#
.SYNOPSIS
    Reads the ticked finding ids back out of an Issue body.

.DESCRIPTION
    The inverse of the task list Format-DriftIssueBody writes. A body and its parse have to
    round trip, otherwise a maintainer's approval is lost on the next rewrite.

.PARAMETER Body
    Specifies the Issue body.

.OUTPUTS
    The ticked finding ids.
#>
function Get-DriftIssueTicked
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter()]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String]
        $Body
    )

    if ([System.String]::IsNullOrEmpty($Body))
    {
        return [System.String[]] @()
    }

    $ticked = [System.Collections.Generic.List[System.String]]::new()

    foreach ($line in ($Body -split "`r?`n"))
    {
        if ($line -match '^\s*-\s\[x\]\s+`([^`]+)`\s*$')
        {
            $ticked.Add($Matches[1])
        }
    }

    return [System.String[]] $ticked
}
