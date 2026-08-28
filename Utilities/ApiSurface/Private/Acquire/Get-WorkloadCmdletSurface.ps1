<#
.SYNOPSIS
    Captures the non-Graph cmdlets the resources call.

.DESCRIPTION
    Reads the commands array of every resource, groups it by module, imports each pinned module
    once and records every parameter of every requested cmdlet across all parameter sets. The
    Graph SDK cmdlets are skipped because Get-GraphCmdletSurface already covers them from
    cmdlet-mapping.json.

    ExchangeOnline and Security and Compliance cmdlets are proxy-generated when
    Connect-ExchangeOnline runs and do not exist before that. Their modules are reported as skipped
    rather than empty, unless ConnectedModule carries a live proxy for them.

    Parameters come from Get-Command on an explicitly imported module. A bare Get-Command on a
    name that does not exist triggers module autodiscovery over every installed module, which
    takes minutes.

.PARAMETER Origin
    Specifies the resource rows from Get-ResourceOriginSurface.

.PARAMETER GraphCmdletName
    Specifies the cmdlet names already captured as Graph cmdlets.

.PARAMETER ModuleVersion
    Specifies a map of module name to pinned version.

.PARAMETER ConnectTimeModule
    Specifies the modules whose cmdlets only exist after a workload connection.

.PARAMETER ConnectedModule
    Specifies a map of workload name to the proxy module a connection produced. A connect-time
    module is captured from these instead of being skipped.

.PARAMETER IncludeModule
    Specifies the only modules to process. Empty means all of them. A connection loads assemblies
    that stop MicrosoftTeams importing, so the offline modules are captured in one call before the
    connection and the connect-time ones in a second call after it.

.OUTPUTS
    A hashtable with Cmdlets, an ordered map, SkippedModules and MissingCmdlets.
#>
function Get-WorkloadCmdletSurface
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Object[]]
        $Origin,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]
        $GraphCmdletName = @(),

        [Parameter()]
        [System.Collections.IDictionary]
        $ModuleVersion = @{},

        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]
        $ConnectTimeModule = @('ExchangeOnlineManagement'),

        [Parameter()]
        [System.Collections.IDictionary]
        $ConnectedModule = @{},

        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]
        $IncludeModule = @()
    )

    $graphNames = [System.Collections.Generic.HashSet[System.String]]::new(
        [System.String[]] $GraphCmdletName, [System.StringComparer]::OrdinalIgnoreCase)

    $requested = @{}
    foreach ($row in $Origin)
    {
        foreach ($command in $row.Commands)
        {
            if ($graphNames.Contains($command.Name))
            {
                continue
            }

            if (-not $requested.ContainsKey($command.Module))
            {
                $requested[$command.Module] = [System.Collections.Generic.HashSet[System.String]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }

            $null = $requested[$command.Module].Add($command.Name)
        }
    }

    $cmdlets = @{}
    $skipped = [System.Collections.Generic.List[System.String]]::new()
    $missing = [System.Collections.Generic.List[System.String]]::new()

    foreach ($moduleName in (Get-M365DSCOrderedName -Value ([System.String[]] @($requested.Keys))))
    {
        if ($IncludeModule.Count -gt 0 -and $moduleName -notin $IncludeModule)
        {
            continue
        }

        $sources = @()
        if ($moduleName -in $ConnectTimeModule)
        {
            $sources = @(Resolve-ConnectedSource -ConnectedModule $ConnectedModule)
            if ($sources.Count -eq 0)
            {
                $skipped.Add($moduleName)
                continue
            }
        }
        else
        {
            $module = Import-WorkloadModule -Name $moduleName -Version $ModuleVersion[$moduleName]
            if ($null -eq $module)
            {
                $skipped.Add($moduleName)
                continue
            }

            $sources = @([PSCustomObject]@{ Workload = (Get-ModuleWorkload -Name $moduleName); Module = $module })
        }

        foreach ($cmdletName in (Get-M365DSCOrderedName -Value ([System.String[]] @($requested[$moduleName]))))
        {
            # The proxies overlap, and the first source to export the name owns it.
            $source = @($sources | Where-Object -FilterScript { $_.Module.ExportedCommands.ContainsKey($cmdletName) })[0]
            if ($null -eq $source)
            {
                $missing.Add($cmdletName)
                continue
            }

            $command = $source.Module.ExportedCommands[$cmdletName]

            # settings.json carries the spelling the resource module uses, which is not always the
            # vendor's. Record the live one.
            $cmdlets[$command.Name] = [ordered]@{
                workload      = $source.Workload
                module        = $moduleName
                moduleVersion = $source.Module.Version.ToString()
                apiVersion    = $null
                variants      = @()
                parameters    = ConvertTo-CommandParameterMap -Command $command
            }
        }
    }

    return @{
        Cmdlets        = ConvertTo-M365DSCOrderedMap -Map $cmdlets
        SkippedModules = Get-M365DSCOrderedName -Value ([System.String[]] $skipped)
        MissingCmdlets = Get-M365DSCOrderedName -Value ([System.String[]] $missing)
    }
}

<#
.SYNOPSIS
    Orders the connected proxies into the sources a connect-time module is captured from.

.PARAMETER ConnectedModule
    Specifies a map of workload name to proxy module.

.OUTPUTS
    Objects with Workload and Module, in probe order.
#>
function Resolve-ConnectedSource
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter()]
        [System.Collections.IDictionary]
        $ConnectedModule = @{}
    )

    $sources = [System.Collections.Generic.List[System.Object]]::new()

    foreach ($probe in (Get-ConnectedWorkloadProbe))
    {
        if (-not $ConnectedModule.Contains($probe.Workload))
        {
            continue
        }

        $module = $ConnectedModule[$probe.Workload]
        if ($null -eq $module)
        {
            continue
        }

        $sources.Add([PSCustomObject]@{ Workload = $probe.Workload; Module = $module })
    }

    return [System.Object[]] $sources
}

<#
.SYNOPSIS
    Imports one workload module at its pinned version.

.DESCRIPTION
    Prefers the pinned version, which is what the shipped module declares as its dependency. A
    machine that only has another version falls back to the newest one it has.

.PARAMETER Name
    Specifies the module name.

.PARAMETER Version
    Specifies the pinned version, if the module is pinned.

.OUTPUTS
    The imported PSModuleInfo, or $null when the module is not installed.
#>
function Import-WorkloadModule
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSModuleInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $Version
    )

    $available = @(Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue)
    if ($available.Count -eq 0)
    {
        Write-Warning -Message "Module '$Name' is not installed. Its cmdlets are recorded as skipped."
        return $null
    }

    $selected = $null
    if (-not [System.String]::IsNullOrEmpty($Version))
    {
        $selected = $available | Where-Object -FilterScript { $_.Version.ToString() -eq $Version } | Select-Object -First 1
    }

    if ($null -eq $selected)
    {
        $selected = $available | Sort-Object -Property Version -Descending | Select-Object -First 1
    }

    try
    {
        return Import-Module -Name $selected.Path -PassThru -Force -DisableNameChecking -ErrorAction Stop
    }
    catch
    {
        Write-Warning -Message "Importing module '$Name' failed. Its cmdlets are recorded as skipped. $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Names the workload a module belongs to.

.DESCRIPTION
    Modules that carry no workload of their own, such as the login helper and the parser, are
    reported as Support. A removed cmdlet in one of them is still reported rather than dropped.

.PARAMETER Name
    Specifies the module name.

.OUTPUTS
    The workload name.
#>
function Get-ModuleWorkload
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    switch -Wildcard ($Name)
    {
        'MicrosoftTeams'
        {
            return 'MicrosoftTeams'
        }
        'PnP.PowerShell'
        {
            return 'PnP'
        }
        'Microsoft.PowerApps.*'
        {
            return 'PowerPlatforms'
        }
        'Az.*'
        {
            return 'Azure'
        }
    }

    return 'Support'
}

<#
.SYNOPSIS
    Records every parameter of a command across all parameter sets.

.DESCRIPTION
    Type names come from Type.ToString, which leaves out the assembly version a generic type
    carries in its FullName and would otherwise change the snapshot on a runtime patch.

.PARAMETER Command
    Specifies the command.

.OUTPUTS
    An ordered map of parameter name to type name.
#>
function ConvertTo-CommandParameterMap
{
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.CommandInfo]
        $Command
    )

    $commonParameters = @(
        'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ProgressAction',
        'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer',
        'PipelineVariable', 'WhatIf', 'Confirm'
    )

    $parameters = @{}
    foreach ($entry in $Command.Parameters.GetEnumerator())
    {
        if ($entry.Key -in $commonParameters)
        {
            continue
        }

        $parameters[$entry.Key] = $entry.Value.ParameterType.ToString()
    }

    return ConvertTo-M365DSCOrderedMap -Map $parameters
}
