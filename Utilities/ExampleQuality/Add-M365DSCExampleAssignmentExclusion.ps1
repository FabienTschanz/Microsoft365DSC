#Requires -Version 5.1

<#
.SYNOPSIS
    Gives every assignment that targets all devices or all licensed users an exclusion group.

.DESCRIPTION
    A bare 'All' target applies to the whole tenant. Each such assignment block gets a sibling
    exclusion-group block of the same CIM type, using the same quote style and column as the block
    it follows. Files that already carry an exclusion are left alone.
#>

[CmdletBinding(SupportsShouldProcess)]
param
(
    [Parameter()]
    [System.String]
    $RepositoryRoot = (Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent),

    [Parameter()]
    [System.String[]]
    $Workload,

    [Parameter()]
    [System.String]
    $GroupDisplayName = 'Policy Exclusions'
)

$ErrorActionPreference = 'Stop'

$allTarget = "#microsoft\.graph\.(allDevices|allLicensedUsers)AssignmentTarget"
$changed = 0

foreach ($exampleDirectory in (Get-ChildItem -Path (Join-Path $RepositoryRoot 'Examples/Resources') -Directory))
{
    if ($Workload -and -not ($Workload | Where-Object -FilterScript { $exampleDirectory.Name -like "$_*" })) { continue }

    foreach ($exampleFile in (Get-ChildItem -Path $exampleDirectory.FullName -Filter '*.ps1'))
    {
        $bytes = [System.IO.File]::ReadAllBytes($exampleFile.FullName)
        $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 239)
        $original = [System.IO.File]::ReadAllText($exampleFile.FullName)
        if ($original -notmatch $allTarget -or $original -match 'exclusionGroupAssignmentTarget') { continue }

        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.AddRange([string[]] ($original -split "`r`n"))

        for ($index = $lines.Count - 1; $index -ge 0; $index--)
        {
            if ($lines[$index] -notmatch "^(?<indent>\s+)dataType(?<pad>\s*)= (?<quote>['`"])$allTarget\k<quote>\s*$") { continue }

            $indent = $Matches['indent']
            $quote = $Matches['quote']

            $open = $index
            while ($open -ge 0 -and $lines[$open] -notmatch '^(?<blockIndent>\s*)(?<type>MSFT_[A-Za-z0-9_]+)\s*(?<brace>\{?)\s*$') { $open-- }
            if ($open -lt 0) { continue }

            $blockIndent = $Matches['blockIndent']
            $type = $Matches['type']
            $sameLineBrace = ($Matches['brace'] -eq '{')

            # A nested CIM block has its own closing brace, so count depth from the block's own brace.
            $close = if ($sameLineBrace) { $open } else { $open + 1 }
            $depth = 0

            do
            {
                $depth += ([regex]::Matches($lines[$close], '\{')).Count - ([regex]::Matches($lines[$close], '\}')).Count
                if ($depth -le 0) { break }
                $close++
            }
            while ($close -lt $lines.Count)

            if ($close -ge $lines.Count) { continue }

            $names = @('dataType', 'groupDisplayName')
            $width = ($names | Measure-Object -Property Length -Maximum).Maximum

            $header = if ($sameLineBrace) { @('{0}{1}{{' -f $blockIndent, $type) } else { @('{0}{1}' -f $blockIndent, $type; '{0}{{' -f $blockIndent) }

            $lines.InsertRange($close + 1, [string[]] @(
                    $header
                    '{0}dataType{1} = {2}#microsoft.graph.exclusionGroupAssignmentTarget{2}' -f $indent, (' ' * ($width - 'dataType'.Length)), $quote
                    '{0}groupDisplayName{1} = {2}{3}{2}' -f $indent, (' ' * ($width - 'groupDisplayName'.Length)), $quote, $GroupDisplayName
                    '{0}}}' -f $blockIndent
                ))
        }

        $updated = ($lines -join "`r`n")
        if ($updated -ceq $original) { continue }

        $parseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseInput(
            [regex]::Replace($updated, '(?i)\bConfiguration\b', 'C0nfiguration'), [ref] $null, [ref] $parseErrors)

        if (@($parseErrors).Count -gt 0)
        {
            Write-Warning "Skipped $($exampleFile.FullName): the rewrite introduced a parse error."
            continue
        }

        if ($PSCmdlet.ShouldProcess($exampleFile.FullName, 'Add exclusion group'))
        {
            [System.IO.File]::WriteAllText($exampleFile.FullName, $updated, (New-Object System.Text.UTF8Encoding($hasBom)))
        }

        $changed++
    }
}

"Added an exclusion group in $changed file(s)."
