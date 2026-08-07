<#
.SYNOPSIS
    Emits the resource's settings.json, including the roles, permissions and commands sections
    that the old generator left out.

.PARAMETER ResourceModel
    Specifies the resource model.

.PARAMETER DestinationPath
    Specifies the settings.json path to write. When omitted the content is returned as a string.
#>
function New-M365DSCSettingsFile
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

    $isGraph = $ResourceModel.Workload -in @('MicrosoftGraph', 'Intune')

    # The resource cmdlets, grouped by the module that ships them.
    $cmdletNames = @(
        $ResourceModel.Cmdlets.GetCmdlet
        $ResourceModel.Cmdlets.NewCmdlet
        $ResourceModel.Cmdlets.UpdateCmdlet
        $ResourceModel.Cmdlets.RemoveCmdlet
    ) | Where-Object { -not [System.String]::IsNullOrEmpty($_) } | Sort-Object -Unique

    $commandGroups = [ordered]@{}
    $requiredModules = @()
    foreach ($cmdletName in $cmdletNames)
    {
        $command = Get-Command -Name $cmdletName -ErrorAction SilentlyContinue
        if ($null -eq $command)
        {
            continue
        }

        $moduleName = $command.ModuleName
        if (-not $commandGroups.Contains($moduleName))
        {
            $commandGroups[$moduleName] = @()
        }
        $commandGroups[$moduleName] += $cmdletName

        if ($isGraph -and $moduleName -like 'Microsoft.Graph*' -and $moduleName -notin $requiredModules)
        {
            $requiredModules += $moduleName
        }
    }

    $commands = @()
    foreach ($moduleName in $commandGroups.Keys)
    {
        $commands += [ordered]@{
            module  = $moduleName
            cmdlets = @($commandGroups[$moduleName] | Sort-Object)
        }
    }

    $permissions = [ordered]@{}
    if ($isGraph)
    {
        $permissions['graph'] = Get-M365DSCGraphPermission -ResourceModel $ResourceModel
    }

    $settings = [ordered]@{
        resourceName          = $ResourceModel.ResourceName
        description           = "This resource configures a $($ResourceModel.ResourceDescription)."
        roles                 = [ordered]@{
            read   = @()
            update = @()
        }
        permissions           = $permissions
        requiredModules       = @($requiredModules | Sort-Object)
        supportedEnvironments = @('Global', 'USGov')
        mode                  = 'Configuration'
        commands              = $commands
    }

    $content = ($settings | ConvertTo-Json -Depth 20) -replace "`r`n", "`n" -replace "`n", "`r`n"

    if ($PSBoundParameters.ContainsKey('DestinationPath'))
    {
        Set-Content -Path $DestinationPath -Value $content -Encoding UTF8
        return $null
    }

    return $content
}

<#
.SYNOPSIS
    Scrapes the Graph permissions of the resource's cmdlets through Find-MgGraphCommand.
#>
function Get-M365DSCGraphPermission
{
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ResourceModel
    )

    $readPermissions = @()
    $updatePermissions = @()

    try
    {
        $apiVersion = $ResourceModel.Cmdlets.APIVersion
        if ([System.String]::IsNullOrEmpty($apiVersion))
        {
            $apiVersion = 'v1.0'
        }

        $getDetails = Find-MgGraphCommand -Command $ResourceModel.Cmdlets.GetCmdlet -ApiVersion $apiVersion -ErrorAction SilentlyContinue
        $readPermissions = @($getDetails.Permissions.Name | Sort-Object -Unique)

        $updateDetails = Find-MgGraphCommand -Command $ResourceModel.Cmdlets.UpdateCmdlet -ApiVersion $apiVersion -ErrorAction SilentlyContinue
        $updatePermissions = @($updateDetails.Permissions.Name | Sort-Object -Unique)
    }
    catch
    {
        Write-Warning -Message "Could not read Graph permissions: $($_.Exception.Message). Fill the permissions section of settings.json manually."
    }

    $readEntries = @($readPermissions | Where-Object { $_ } | ForEach-Object { [ordered]@{ name = $_ } })
    $updateEntries = @($updatePermissions | Where-Object { $_ } | ForEach-Object { [ordered]@{ name = $_ } })

    return [ordered]@{
        delegated   = [ordered]@{
            read   = $readEntries
            update = $updateEntries
        }
        application = [ordered]@{
            read   = $readEntries
            update = $updateEntries
        }
    }
}
