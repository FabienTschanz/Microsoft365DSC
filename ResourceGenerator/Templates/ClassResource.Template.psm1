# Editor-only: lets this file resolve [M365DSCResourceBase] when parsed on its own.
# Build-Microsoft365DSC.ps1 emits only the class extent, so this line is not shipped.
using module ..\_Base\M365DSCResourceBase.psm1

[DscResource()]
class <ResourceName> : M365DSCResourceBase
{
<PropertyBlock>

    [<ResourceName>] Get()
    {
        if ($this.RequiresPowerShellCore())
        {
            $remote = [<ResourceName>]::new()
            $remote.FromHashtable($this.InvokeInPowerShellCore('Get'))
            return $remote
        }

        Write-Verbose -Message "Getting configuration of <ResourceDescription> {$($this.<PrimaryKey>)}"

        try
        {
            $null = $this.Connect('<Workload>')

            #Ensure the proper dependencies are installed in the current environment.
            Confirm-M365DSCDependencies

            #region Telemetry
            $this.AddTelemetry('Get')
            #endregion

            $nullResult = $this.GetBoundParameters()
<#IF HasEnsure#>
            $nullResult.Ensure = 'Absent'
<#ENDIF HasEnsure#>

            if (-not $this.ExportedInstance -or $this.ExportedInstance.<PrimaryKey> -ne $this.<PrimaryKey>)
            {
<GetInstanceBlock>
            }
            else
            {
                $getValue = $this.ExportedInstance
            }

            if ($null -eq $getValue)
            {
                Write-Verbose -Message "No <ResourceDescription> with <PrimaryKey> {$($this.<PrimaryKey>)} was found"
                return $this.AsResult($nullResult)
            }

            Write-Verbose -Message "Found <ResourceDescription> with <PrimaryKey> {$($this.<PrimaryKey>)}"

<ComplexConversionBlock>
            $result = @{
<HashtableMappingBlock>
            }
<AssignmentsGetBlock>

            return $this.AsResult($result)
        }
        catch
        {
            $this.LogError($_, 'Error retrieving data:')

            throw
        }
    }

    [void] Set()
    {
        if ($this.RequiresPowerShellCore())
        {
            $null = $this.InvokeInPowerShellCore('Set')
            return
        }

        Write-Verbose -Message "Setting configuration of <ResourceDescription> {$($this.<PrimaryKey>)}"

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Set')
        #endregion

        try
        {
            $null = $this.Connect('<Workload>')

            $currentInstance = $this.Get().ToHashtable()

<#IF HasEnsure#>
            if ($this.Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Absent')
            {
                Write-Verbose -Message "Creating new <ResourceDescription> {$($this.<PrimaryKey>)}"

<NewInvocationBlock>
            }
            elseif ($this.Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Present')
            {
                Write-Verbose -Message "Updating <ResourceDescription> {$($this.<PrimaryKey>)}"

<UpdateInvocationBlock>
            }
            elseif ($this.Ensure -eq 'Absent' -and $currentInstance.Ensure -eq 'Present')
            {
                Write-Verbose -Message "Removing <ResourceDescription> {$($this.<PrimaryKey>)}"

<RemoveInvocationBlock>
            }
<#ELSE#>
            Write-Verbose -Message "Updating <ResourceDescription> {$($this.<PrimaryKey>)}"

<UpdateInvocationBlock>
<#ENDIF HasEnsure#>
        }
        catch
        {
            $this.LogError($_, 'Error updating data:')

            throw
        }
    }

    [bool] Test()
    {
        if ($this.RequiresPowerShellCore())
        {
            return [bool] $this.InvokeInPowerShellCore('Test')
        }

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Test')
        #endregion

        Write-Verbose -Message "Testing configuration of <ResourceDescription> {$($this.<PrimaryKey>)}"

        $compareParameters = $this.GetCompareParameters()
        $result = Test-M365DSCTargetResource -DesiredValues $this.GetBoundParameters() `
            -ResourceName $this.GetResourceName() `
            @compareParameters -CurrentValues $this.Get().ToHashtable()

        Write-Verbose -Message "Test-TargetResource returned $result"

        return $result
    }

    [string] Export()
    {
        if ($this.RequiresPowerShellCore())
        {
            return [string] $this.InvokeInPowerShellCore('Export')
        }

        $ConnectionMode = $this.Connect('<Workload>')

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Export')
        #endregion

        try
        {
<ExportGetAllBlock>

            $dscContent = [System.Text.StringBuilder]::new()
            $i = 1

            if ($exportedInstances.Length -eq 0)
            {
                Write-M365DSCHost -Message $Global:M365DSCEmojiGreenCheckMark -CommitWrite
            }
            else
            {
                Write-M365DSCHost -Message "`r`n" -DeferWrite
            }

            foreach ($exportedInstance in $exportedInstances)
            {
                if ($null -ne $Global:M365DSCExportResourceInstancesCount)
                {
                    $Global:M365DSCExportResourceInstancesCount++
                }

                Write-M365DSCHost -Message "    |---[$i/$($exportedInstances.Count)] $($exportedInstance.<ExportedInstanceLabel>)" -DeferWrite

                $Params = @{
<ExportParameterBlock>
                }

                $this.ExportedInstance = $exportedInstance
                $Results = $this.GetForExport($Params)

<ExportComplexToStringBlock>
                $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $this.GetResourceName() `
                    -ConnectionMode $ConnectionMode `
                    -ModulePath $this.GetModulePath() `
                    -Results $Results `
                    -Credential $this.Credential<NoEscapeArgument>
                [void]$dscContent.Append($currentDSCBlock)
                Save-M365DSCPartialExport -Content $currentDSCBlock `
                    -FileName $Global:PartialExportFileName

                Write-M365DSCHost -Message $Global:M365DSCEmojiGreenCheckMark -CommitWrite
                $i++
            }

            return $dscContent.ToString()
        }
        catch
        {
            Write-M365DSCHost -Message $Global:M365DSCEmojiRedX

            $this.LogError($_, 'Error during Export:')

            throw
        }
    }

    # Materialises a Get() result. DSC needs the typed instance rather than a hashtable.
    hidden [<ResourceName>] AsResult([System.Object] $Values)
    {
        if ($Values -is [<ResourceName>])
        {
            return $Values
        }

        $result = [<ResourceName>]::new()
        if ($Values -is [System.Collections.Hashtable])
        {
            $result.FromHashtable($Values)
        }

        return $result
    }
}
<#IF CimInstanceClassBlock#>

<CimInstanceClassBlock>
<#ENDIF CimInstanceClassBlock#>
<#IF HelperFunctionBlock#>

<HelperFunctionBlock>
<#ENDIF HelperFunctionBlock#>
