<#
.SYNOPSIS
    Stages a module so DSC discovery can find it.

.DESCRIPTION
    Creates <temp>/<random>/Microsoft365DSC/<Version> pointing at the module root, which is the
    layout Get-DscResourceV2 requires: a PSModulePath entry, a folder named after the module and
    a folder named after its ModuleVersion. Prefers a junction/symlink and falls back to a copy
    when the filesystem or privileges do not allow one.

.PARAMETER ModuleRoot
    Folder holding the module manifest.

.PARAMETER Version
    Module version, used as the leaf folder name. Must match the manifest's ModuleVersion.

.PARAMETER ModuleName
    Module name, used as the parent folder name.

.EXAMPLE
    $stage = New-M365DSCProbeStage -ModuleRoot $moduleRoot -Version '1.26.1007.1'

.OUTPUTS
    System.Collections.Hashtable
#>
function New-M365DSCProbeStage
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleRoot,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Version,

        [Parameter()]
        [System.String]
        $ModuleName = 'Microsoft365DSC'
    )

    $root = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('M365DSCProbe_' + [Guid]::NewGuid().ToString('N'))
    $moduleFolder = Join-Path -Path $root -ChildPath $ModuleName
    $link = Join-Path -Path $moduleFolder -ChildPath $Version

    $null = New-Item -Path $moduleFolder -ItemType Directory -Force

    try
    {
        $onWindows = $PSVersionTable.PSEdition -eq 'Desktop' -or $global:IsWindows
        $linkType = if ($onWindows) { 'Junction' } else { 'SymbolicLink' }

        try
        {
            $null = New-Item -Path $link -ItemType $linkType -Value $ModuleRoot -ErrorAction Stop
            return @{ Root = $root; Link = $link; IsLink = $true }
        }
        catch
        {
            Write-Warning -Message "Could not create a $linkType at '$link' ($($_.Exception.Message)). Falling back to a copy."
        }

        $null = New-Item -Path $link -ItemType Directory -Force
        Copy-Item -Path (Join-Path -Path $ModuleRoot -ChildPath '*') -Destination $link -Recurse -Force

        return @{ Root = $root; Link = $link; IsLink = $false }
    }
    catch
    {
        Remove-Item -Path $root -Recurse -Force -ErrorAction SilentlyContinue
        throw
    }
}

<#
.SYNOPSIS
    Removes a staging folder created by New-M365DSCProbeStage.

.DESCRIPTION
    Deletes the junction itself before the tree, so a recursive delete never follows the link into
    the real module folder.

.PARAMETER Stage
    The hashtable returned by New-M365DSCProbeStage.

.EXAMPLE
    Remove-M365DSCProbeStage -Stage $stage
#>
function Remove-M365DSCProbeStage
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Stage
    )

    if (-not $PSCmdlet.ShouldProcess($Stage.Root, 'Remove staging folder'))
    {
        return
    }

    if ($Stage.IsLink -and (Test-Path -Path $Stage.Link))
    {
        [System.IO.Directory]::Delete($Stage.Link, $false)
    }

    Remove-Item -Path $Stage.Root -Recurse -Force -ErrorAction SilentlyContinue
}

function Write-MeasureLog
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateSet('Info', 'Detail', 'Success', 'Warning')]
        [System.String]
        $Level = 'Info'
    )

    $color = switch ($Level)
    {
        'Info' { 'Cyan' }
        'Detail' { 'DarkGray' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
    }

    Write-Host "[measure] $Message" -ForegroundColor $color
}

function Invoke-InFreshProcess
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('pwsh', 'powershell')]
        [System.String]
        $Executable,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Script
    )

    $output = & $Executable -NoProfile -NonInteractive -Command $Script 2>$null

    return @($output |
            Where-Object { $_ -is [System.String] -and $_.Trim().Length -gt 0 } |
            ForEach-Object { $_.Trim() })
}

function Measure-Median
{
    [CmdletBinding()]
    [OutputType([System.Nullable[System.Int32]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Executable,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Script,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $Count
    )

    $null = Invoke-InFreshProcess -Executable $Executable -Script $Script

    $samples = [System.Collections.Generic.List[System.Int32]]::new()
    for ($i = 0; $i -lt $Count; $i++)
    {
        $lines = @(Invoke-InFreshProcess -Executable $Executable -Script $Script)
        $value = if ($lines.Count -gt 0) { $lines[-1] } else { $null }
        $parsed = 0
        if ([System.Int32]::TryParse($value, [ref] $parsed))
        {
            $samples.Add($parsed)
        }
        else
        {
            Write-MeasureLog "Unusable sample from ${Executable}: '$value'" -Level Warning
        }
    }

    if ($samples.Count -eq 0)
    {
        return $null
    }

    $sorted = @($samples | Sort-Object)
    return $sorted[[System.Math]::Floor($sorted.Count / 2)]
}

Export-ModuleMember -Function New-M365DSCProbeStage, Remove-M365DSCProbeStage, Write-MeasureLog, Invoke-InFreshProcess, Measure-Median
