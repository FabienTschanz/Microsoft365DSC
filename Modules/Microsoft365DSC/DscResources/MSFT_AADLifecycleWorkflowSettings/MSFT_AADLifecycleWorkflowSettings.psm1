# Editor-only: lets this file resolve [M365DSCResourceBase] when parsed on its own.
# Build-Microsoft365DSC.ps1 emits only the class extent, so this line is not shipped.
using module ..\_Base\M365DSCResourceBase.psm1

[DscResource()]
class AADLifecycleWorkflowSettings : M365DSCResourceBase
{
    [DscProperty(Key)]
    [System.ComponentModel.Description('Only valid value is ''Yes''.')]
    [ValidateSet('Yes')]
    [System.String] $IsSingleInstance

    [DscProperty()]
    [System.ComponentModel.Description('Specifies the domain that should be used when sending email notifications. This domain must be verified in order to be used. We recommend that you use a domain that has the appropriate DNS records to facilitate email validation, like SPF, DKIM, DMARC, and MX, because this then complies with the RFC compliance for sending and receiving email. For details, see Learn more about Exchange Online Email Routing.')]
    [System.String] $SenderDomain

    [DscProperty()]
    [System.ComponentModel.Description('The interval in hours at which all workflows running in the tenant should be scheduled for execution. This interval has a minimum value of 1 and a maximum value of 24. The default value is 3 hours.')]
    [System.Nullable[System.UInt32]] $WorkflowScheduleIntervalInHours

    [DscProperty()]
    [System.ComponentModel.Description('Specifies if the organization''s banner logo should be included in email notifications. The banner logo will replace the Microsoft logo at the top of the email notification. If true the banner logo will be taken from the tenant''s branding settings. This value can only be set to true if the organizationalBranding bannerLogo property is set.')]
    [System.Nullable[System.Boolean]] $UseCompanyBranding

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
    [System.ComponentModel.Description('Secret of the Azure Active Directory tenant used for authentication.')]
    [System.Management.Automation.PSCredential] $ApplicationSecret

    [DscProperty()]
    [System.ComponentModel.Description('Thumbprint of the Azure Active Directory application''s authentication certificate to use for authentication.')]
    [System.String] $CertificateThumbprint

    [DscProperty()]
    [System.ComponentModel.Description('Username can be made up to anything but password will be used for CertificatePassword')]
    [System.Management.Automation.PSCredential] $CertificatePassword

    [DscProperty()]
    [System.ComponentModel.Description('Path to certificate used in service principal usually a PFX file.')]
    [System.String] $CertificatePath

    [DscProperty()]
    [System.ComponentModel.Description('Managed ID being used for authentication.')]
    [System.Nullable[System.Boolean]] $ManagedIdentity

    [DscProperty()]
    [System.ComponentModel.Description('Access token used for authentication.')]
    [System.String[]] $AccessTokens

    [AADLifecycleWorkflowSettings] Get()
    {
        # Declared up front: assigned conditionally below, which class methods reject.
        $nullResult = $null
        if ($this.RequiresPowerShellCore())
        {
            $remote = [AADLifecycleWorkflowSettings]::new()
            $remote.FromHashtable($this.InvokeInPowerShellCore('Get'))
            return $remote
        }

        Write-Verbose -Message 'Getting the AAD Lifecycle Workflow Settings'

        try
        {
            if (-not $this.ExportedInstance)
            {
                $null = $this.Connect('MicrosoftGraph')

                #Ensure the proper dependencies are installed in the current environment.
                Confirm-M365DSCDependencies

                #region Telemetry
                $this.AddTelemetry('Get')
                #endregion

                $nullResult = $this.GetBoundParameters()
                $instance = Get-MgBetaIdentityGovernanceLifecycleWorkflowSetting -ErrorAction SilentlyContinue
            }
            else
            {
                $instance = $this.ExportedInstance
            }

            if ($null -eq $instance)
            {
                return $this.AsResult($nullResult)
            }

            $results = @{
                IsSingleInstance                = 'Yes'
                WorkflowScheduleIntervalInHours = $instance.WorkflowScheduleIntervalInHours
                SenderDomain                    = $instance.EmailSettings.SenderDomain
                UseCompanyBranding              = $instance.EmailSettings.UseCompanyBranding
                Credential                      = $this.Credential
                ApplicationId                   = $this.ApplicationId
                TenantId                        = $this.TenantId
                ApplicationSecret               = $this.ApplicationSecret
                CertificateThumbprint           = $this.CertificateThumbprint
                CertificatePath                 = $this.CertificatePath
                CertificatePassword             = $this.CertificatePassword
                ManagedIdentity                 = $this.ManagedIdentity.IsPresent
                AccessTokens                    = $this.AccessTokens
            }
            return $this.AsResult($results)
        }
        catch
        {
            $this.LogError($_, 'Error retrieving data:')

            throw
        }
    }

    [void] Set()
    {
        # Declared up front: assigned conditionally below, which class methods reject.
        $payload = $null
        if ($this.RequiresPowerShellCore())
        {
            $null = $this.InvokeInPowerShellCore('Set')
            return
        }

        Write-Verbose -Message 'Setting the AAD Lifecycle Workflow Settings'

        $null = $this.Connect('MicrosoftGraph')

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Set')
        #endregion

        $updateSettings = @{
            workflowScheduleIntervalInHours = $this.WorkflowScheduleIntervalInHours
            emailSettings                   = @{
                senderDomain       = $this.SenderDomain
                useCompanyBranding = $this.UseCompanyBranding
            }
        }
        Write-Verbose -Message "Updating the lifecycle workflow settings with payload: $payload"
        Update-MgBetaIdentityGovernanceLifecycleWorkflowSetting -BodyParameter $updateSettings
    }

    [bool] Test()
    {
        return ([M365DSCResourceBase] $this).Test()
    }

    [string] Export()
    {
        if ($this.RequiresPowerShellCore())
        {
            return [string] $this.InvokeInPowerShellCore('Export')
        }

        $ConnectionMode = $this.Connect('MicrosoftGraph')

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Export')
        #endregion

        try
        {
            [array] $exportedInstances = Get-MgBetaIdentityGovernanceLifecycleWorkflowSetting -ErrorAction Stop

            $i = 1
            $dscContent = [System.Text.StringBuilder]::new()
            if ($exportedInstances.Length -eq 0)
            {
                Write-M365DSCHost -Message $Global:M365DSCEmojiGreenCheckMark -CommitWrite
            }
            else
            {
                Write-M365DSCHost -Message "`r`n" -DeferWrite
            }
            foreach ($config in $exportedInstances)
            {
                if ($null -ne $Global:M365DSCExportResourceInstancesCount)
                {
                    $Global:M365DSCExportResourceInstancesCount++
                }

                $displayedKey = $config.Id
                Write-M365DSCHost -Message "    |---[$i/$($exportedInstances.Count)] $displayedKey" -DeferWrite
                $params = @{
                    IsSingleInstance      = 'Yes'
                    Credential            = $this.Credential
                    ApplicationId         = $this.ApplicationId
                    TenantId              = $this.TenantId
                    ApplicationSecret     = $this.ApplicationSecret
                    CertificateThumbprint = $this.CertificateThumbprint
                    CertificatePath       = $this.CertificatePath
                    CertificatePassword   = $this.CertificatePassword
                    ManagedIdentity       = $this.ManagedIdentity.IsPresent
                    AccessTokens          = $this.AccessTokens
                }

                $this.ExportedInstance = $config
                $Results = $this.GetForExport($Params)

                $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $this.GetResourceName() `
                    -ConnectionMode $ConnectionMode `
                    -ModulePath $this.GetModulePath() `
                    -Results $Results `
                    -Credential $this.Credential
                [void]$dscContent.Append($currentDSCBlock)
                Save-M365DSCPartialExport -Content $currentDSCBlock `
                    -FileName $Global:PartialExportFileName
                $i++
                Write-M365DSCHost -Message $Global:M365DSCEmojiGreenCheckMark -CommitWrite
            }
            return $dscContent.ToString()
        }
        catch
        {
            if ($_.ErrorDetails.Message -like 'Insufficient license *')
            {
                Write-M365DSCHost -Message "`r`n    " -DeferWrite
                Write-M365DSCHost -Message $Global:M365DSCEmojiYellowCircle -DeferWrite
                Write-M365DSCHost -Message ' Insufficient license. You need the Entra ID Governance license.' -CommitWrite
            }
            else
            {
                $this.LogError($_, 'Error during Export:')

                throw
            }
        }
    
        # Every code path must return in a method with a declared return type.
        return ''
    }

    # Materialises a Get() result. The script-based body built a hashtable; DSC needs the type.
    hidden [AADLifecycleWorkflowSettings] AsResult([System.Object] $Values)
    {
        if ($Values -is [AADLifecycleWorkflowSettings])
        {
            return $Values
        }

        $result = [AADLifecycleWorkflowSettings]::new()
        if ($Values -is [System.Collections.Hashtable])
        {
            $result.FromHashtable($Values)
        }

        return $result
    }
}

