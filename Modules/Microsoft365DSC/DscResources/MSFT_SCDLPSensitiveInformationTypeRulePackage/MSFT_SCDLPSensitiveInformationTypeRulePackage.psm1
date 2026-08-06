# Editor-only: lets this file resolve [M365DSCResourceBase] when parsed on its own.
# Build-Microsoft365DSC.ps1 emits only the class extent, so this line is not shipped.
using module ..\_Base\M365DSCResourceBase.psm1

[DscResource()]
class SCDLPSensitiveInformationTypeRulePackage : M365DSCResourceBase
{
    [DscProperty(Key)]
    [System.ComponentModel.Description('The Name parameter specifies a name for the sensitive information type rule package. The value must be less than 256 characters.')]
    [System.String] $Name

    [DscProperty()]
    [System.ComponentModel.Description('Unique identifier of the Sensitive Information Type Rule Package.')]
    [System.String] $Identity

    [DscProperty()]
    [System.ComponentModel.Description('The XML file data for the Sensitive Information Type Rule Package.')]
    [System.String] $XmlFileData

    [DscProperty()]
    [System.ComponentModel.Description('Present ensures the instance exists, absent ensures it is removed.')]
    [ValidateSet('Absent', 'Present')]
    [System.String] $Ensure

    [DscProperty()]
    [System.ComponentModel.Description('Credentials of the workload''s Admin')]
    [System.Management.Automation.PSCredential] $Credential

    [DscProperty()]
    [System.ComponentModel.Description('Id of the Azure Active Directory application to authenticate with.')]
    [System.String] $ApplicationId

    [DscProperty()]
    [System.ComponentModel.Description('Id of the Azure Active Directory tenant used for authentication.')]
    [System.String] $TenantId

    [DscProperty()]
    [System.ComponentModel.Description('Thumbprint of the Azure Active Directory application''s authentication certificate to use for authentication.')]
    [System.String] $CertificateThumbprint

    [DscProperty()]
    [System.ComponentModel.Description('Managed ID being used for authentication.')]
    [System.Nullable[System.Boolean]] $ManagedIdentity

    [DscProperty()]
    [System.ComponentModel.Description('Access token used for authentication.')]
    [System.String[]] $AccessTokens

    # Export-only. Not part of the resource schema.
    [System.Management.Automation.PSCredential] $ApplicationSecret

    [SCDLPSensitiveInformationTypeRulePackage] Get()
    {
        # Declared up front: assigned conditionally below, which class methods reject.
        $CertificatePassword = $null
        # Declared up front: assigned conditionally below, which class methods reject.
        $CertificatePath = $null
        if ($this.RequiresPowerShellCore())
        {
            $remote = [SCDLPSensitiveInformationTypeRulePackage]::new()
            $remote.FromHashtable($this.InvokeInPowerShellCore('Get'))
            return $remote
        }

        Write-Verbose -Message "Getting configuration of DLPSensitiveInformationTypeRulePackage for $($this.Name)"

        try
        {
            if (-not $this.ExportedInstance -or $this.ExportedInstance.Name -ne $this.Name)
            {
                $null = $this.Connect('SecurityComplianceCenter')

                #Ensure the proper dependencies are installed in the current environment.
                Confirm-M365DSCDependencies

                #region Telemetry
                $this.AddTelemetry('Get')
                #endregion

                $nullReturn = $this.GetBoundParameters()
                $nullReturn.Ensure = 'Absent'

                $SIT = Invoke-M365DSCCommand -ScriptBlock { Get-DlpSensitiveInformationTypeRulePackage -Identity $this.Name -ErrorAction Stop } -SuppressNotFoundError

                if ($null -eq $SIT)
                {
                    Write-Verbose -Message "DLPSensitiveInformationTypeRulePackage $($this.Name) does not exist."
                    return $this.AsResult($nullReturn)
                }
            }
            else
            {
                $SIT = $this.ExportedInstance
            }

            Write-Verbose "Found existing DLPSensitiveInformationTypeRulePackage $($this.Name)"

            $result = @{
                Ensure                = 'Present'
                Name                  = $SIT.RuleCollectionName
                Identity              = $SIT.Identity
                XmlFileData           = $SIT.ClassificationRuleCollectionXml -replace "lastModifiedTime=`".*?`"", '' # Remove last modified time as it is not relevant to the configuration and causes noise in diffs
                Credential            = $this.Credential
                ApplicationId         = $this.ApplicationId
                TenantId              = $this.TenantId
                CertificateThumbprint = $this.CertificateThumbprint
                CertificatePath       = $CertificatePath
                CertificatePassword   = $CertificatePassword
                AccessTokens          = $this.AccessTokens
            }

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

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Set')
        #endregion

        $currentInstance = $this.Get().ToHashtable()
        $setParameters = Remove-M365DSCAuthenticationParameter -BoundParameters $this.GetBoundParameters()

        # CREATE
        if ($this.Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Absent')
        {
            Write-Verbose -Message "Creating a new DLPSensitiveInformationTypeRulePackage with RuleCollectionName $($this.Name)"
            New-DLPSensitiveInformationTypeRulePackage -FileData ([System.Text.Encoding]::Unicode.GetBytes($this.XmlFileData))
        }
        # UPDATE
        elseif ($this.Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Present')
        {
            Write-Verbose -Message "Updating a DLPSensitiveInformationTypeRulePackage with RuleCollectionName $($this.Name)"
            Set-DLPSensitiveInformationTypeRulePackage -FileData ([System.Text.Encoding]::Unicode.GetBytes($this.XmlFileData))
        }
        # REMOVE
        elseif ($this.Ensure -eq 'Absent' -and $currentInstance.Ensure -eq 'Present')
        {
            Write-Verbose -Message "Removing a DLPSensitiveInformationTypeRulePackage with RuleCollectionName $($this.Name)"
            Remove-DLPSensitiveInformationTypeRulePackage -Identity $currentInstance.Identity
        }
    }

    [bool] Test()
    {
        if ($this.RequiresPowerShellCore())
        {
            return [bool] $this.InvokeInPowerShellCore('Test')
        }

        #region Telemetry
        $this.AddTelemetry('Test')
        #endregion

        $compareParameters = $this.GetCompareParameters()
        $result = Test-M365DSCTargetResource -DesiredValues $this.GetBoundParameters() `
            -ResourceName $this.GetResourceName() `
            @compareParameters -CurrentValues $this.Get().ToHashtable()
        return $result
    }

    [string] Export()
    {
        # Declared up front: assigned conditionally below, which class methods reject.
        $rules = $null
        if ($this.RequiresPowerShellCore())
        {
            return [string] $this.InvokeInPowerShellCore('Export')
        }

        $ConnectionMode = $this.Connect('SecurityComplianceCenter')

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Export')
        #endregion

        try
        {
            [array]$SITs = Get-DLPSensitiveInformationTypeRulePackage -ErrorAction Stop | Where-Object {
                $null -ne $_.Identity
            }

            $i = 1
            $dscContent = [System.Text.StringBuilder]::new()
            if ($rules.Length -eq 0)
            {
                Write-M365DSCHost -Message $Global:M365DSCEmojiGreenCheckMark -CommitWrite
            }
            else
            {
                Write-M365DSCHost -Message "`r`n" -DeferWrite
            }
            foreach ($SIT in $SITs)
            {
                if ($null -ne $Global:M365DSCExportResourceInstancesCount)
                {
                    $Global:M365DSCExportResourceInstancesCount++
                }

                Write-M365DSCHost -Message "    |---[$i/$($SITs.Length)] $($SIT.RuleCollectionName)" -DeferWrite

                $this.ExportedInstance = $SIT
                $Results = $this.GetForExport(@{ Name = $SIT.RuleCollectionName; XmlFileData = 'temp' })

                $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $this.GetResourceName() `
                    -ConnectionMode $ConnectionMode `
                    -ModulePath $this.GetModulePath() `
                    -Results $Results `
                    -Credential $this.Credential `
                    -NoEscape @()

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
            $this.LogError($_, 'Error during Export:')

            throw
        }
    }

    # Was Get-CompareParameters. M365DSCResourceBase declares this; the default returns
    # GetBoundParameters().
    [System.Collections.Hashtable] GetCompareParameters()
    {
        return @{
            ExcludedProperties = @('Identity')
        }
    }

    # Materialises a Get() result. The script-based body built a hashtable; DSC needs the type.
    hidden [SCDLPSensitiveInformationTypeRulePackage] AsResult([System.Object] $Values)
    {
        if ($Values -is [SCDLPSensitiveInformationTypeRulePackage])
        {
            return $Values
        }

        $result = [SCDLPSensitiveInformationTypeRulePackage]::new()
        if ($Values -is [System.Collections.Hashtable])
        {
            $result.FromHashtable($Values)
        }

        return $result
    }
}

