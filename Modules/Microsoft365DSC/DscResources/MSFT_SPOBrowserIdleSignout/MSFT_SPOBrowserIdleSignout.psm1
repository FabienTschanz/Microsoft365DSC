# Editor-only: lets this file resolve [M365DSCResourceBase] when parsed on its own.
# Build-Microsoft365DSC.ps1 emits only the class extent, so this line is not shipped.
using module ..\_Base\M365DSCResourceBase.psm1

[DscResource()]
class SPOBrowserIdleSignout : M365DSCResourceBase
{
    [DscProperty(Key)]
    [System.ComponentModel.Description('Specifies the resource is a single instance, the value must be ''Yes''')]
    [ValidateSet('Yes')]
    [System.String] $IsSingleInstance

    [DscProperty()]
    [System.ComponentModel.Description('Enables the browser idle sign-out policy')]
    [System.Nullable[System.Boolean]] $Enabled

    [DscProperty()]
    [System.ComponentModel.Description('Specifies a time interval of inactivity before the user gets signed out')]
    [ValidatePattern('^([0-9]{0,7}\.?[0-2][0-9]:[0-5][0-9]:[0-5][0-9])$')]
    [System.String] $SignOutAfter

    [DscProperty()]
    [System.ComponentModel.Description('Specifies a time interval of inactivity before the user gets a warning about being signed out')]
    [ValidatePattern('^([0-9]{0,7}\.?[0-2][0-9]:[0-5][0-9]:[0-5][0-9])$')]
    [System.String] $WarnAfter

    [DscProperty()]
    [System.ComponentModel.Description('Credentials of the SharePoint Admin')]
    [System.Management.Automation.PSCredential] $Credential

    [DscProperty()]
    [System.ComponentModel.Description('Id of the Azure Active Directory application to authenticate with.')]
    [System.String] $ApplicationId

    [DscProperty()]
    [System.ComponentModel.Description('Secret of the Azure Active Directory application to authenticate with.')]
    [System.Management.Automation.PSCredential] $ApplicationSecret

    [DscProperty()]
    [System.ComponentModel.Description('Name of the Azure Active Directory tenant used for authentication. Format contoso.onmicrosoft.com')]
    [System.String] $TenantId

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

    [SPOBrowserIdleSignout] Get()
    {
        if ($this.RequiresPowerShellCore())
        {
            $remote = [SPOBrowserIdleSignout]::new()
            $remote.FromHashtable($this.InvokeInPowerShellCore('Get'))
            return $remote
        }

        Write-Verbose -Message 'Getting configuration for SPO Browser Idle Signout settings'

        try
        {
            if ($null -eq $this.ExportedInstance)
            {
                $null = $this.Connect('PnP')

                #Ensure the proper dependencies are installed in the current environment.
                Confirm-M365DSCDependencies

                #region Telemetry
                $this.AddTelemetry('Get')
                #endregion

                $BrowserIdleSignout = Get-PnPBrowserIdleSignout -ErrorAction Stop
            }
            else
            {
                $BrowserIdleSignout = $this.ExportedInstance
            }

            return $this.AsResult(@{
                IsSingleInstance      = 'Yes'
                Enabled               = $BrowserIdleSignout.Enabled
                SignOutAfter          = $BrowserIdleSignout.SignOutAfter.ToString()
                WarnAfter             = $BrowserIdleSignout.WarnAfter.ToString()
                Credential            = $this.Credential
                ApplicationId         = $this.ApplicationId
                TenantId              = $this.TenantId
                ApplicationSecret     = $this.ApplicationSecret
                CertificateThumbprint = $this.CertificateThumbprint
                CertificatePath       = $this.CertificatePath
                CertificatePassword   = $this.CertificatePassword
                ManagedIdentity       = $this.ManagedIdentity.IsPresent
                AccessTokens          = $this.AccessTokens
            })
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

        Write-Verbose -Message 'Setting configuration for SPO Browser Idle Signout settings'

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Set')
        #endregion

        $null = $this.Connect('PnP')

        $CurrentParameters = Remove-M365DSCAuthenticationParameter -BoundParameters $this.GetBoundParameters()
        $CurrentParameters.Remove('IsSingleInstance') | Out-Null

        Set-PnPBrowserIdleSignout @CurrentParameters | Out-Null
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
        if ($this.RequiresPowerShellCore())
        {
            return [string] $this.InvokeInPowerShellCore('Export')
        }

        try
        {
            $ConnectionMode = $this.Connect('PNP')

            #Ensure the proper dependencies are installed in the current environment.
            Confirm-M365DSCDependencies

            #region Telemetry
            $this.AddTelemetry('Export')
            #endregion

            if ($null -ne $Global:M365DSCExportResourceInstancesCount)
            {
                $Global:M365DSCExportResourceInstancesCount++
            }

            $this.ExportedInstance = Get-PnPBrowserIdleSignout -ErrorAction Stop

            $Params = @{
                IsSingleInstance      = 'Yes'
                Enabled               = $false
                ApplicationId         = $this.ApplicationId
                TenantId              = $this.TenantId
                CertificateThumbprint = $this.CertificateThumbprint
                CertificatePath       = $this.CertificatePath
                CertificatePassword   = $this.CertificatePassword
                ManagedIdentity       = $this.ManagedIdentity.IsPresent
                Credential            = $this.Credential
                ApplicationSecret     = $this.ApplicationSecret
                AccessTokens          = $this.AccessTokens
            }

            $dscContent = [System.Text.StringBuilder]::new()
            $Results = $this.GetForExport($Params)
            if ($Results -is [System.Collections.Hashtable] -and $Results.Count -gt 1)
            {
                $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $this.GetResourceName() `
                    -ConnectionMode $ConnectionMode `
                    -ModulePath $this.GetModulePath() `
                    -Results $Results `
                    -Credential $this.Credential
                [void]$dscContent.Append($currentDSCBlock)
                Save-M365DSCPartialExport -Content $currentDSCBlock `
                    -FileName $Global:PartialExportFileName

                Write-M365DSCHost -Message $Global:M365DSCEmojiGreenCheckMark -CommitWrite
            }
            else
            {
                Write-M365DSCHost -Message $Global:M365DSCEmojiRedX -CommitWrite
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
            PostProcessing = {
                param($DesiredValues, $CurrentValues, $ValuesToCheck, $ignore)
                if ($null -ne $DesiredValues.SignOutAfter -and $null -ne $CurrentValues.SignOutAfter)
                {
                    $desiredTimeSpan = [System.TimeSpan]::Parse($DesiredValues.SignOutAfter)
                    $currentTimeSpan = [System.TimeSpan]::Parse($CurrentValues.SignOutAfter)
                    $delta = [System.TimeSpan]::FromSeconds(30)
                    if ([System.TimeSpan]::Compare($desiredTimeSpan, $currentTimeSpan) -ne 0 -and [System.TimeSpan]::Compare(($desiredTimeSpan - $currentTimeSpan).Duration(), $delta) -le 0)
                    {
                        Write-Verbose -Message "Difference between Desired and Current SignOutAfter is less than or equal to 30 seconds. Desired: $desiredTimeSpan, Current: $currentTimeSpan. Treating as equal."
                        $ValuesToCheck.Remove('SignOutAfter') | Out-Null
                    }
                }
                if ($null -ne $DesiredValues.WarnAfter -and $null -ne $CurrentValues.WarnAfter)
                {
                    $desiredTimeSpan = [System.TimeSpan]::Parse($DesiredValues.WarnAfter)
                    $currentTimeSpan = [System.TimeSpan]::Parse($CurrentValues.WarnAfter)
                    $delta = [System.TimeSpan]::FromSeconds(30)
                    if ([System.TimeSpan]::Compare($desiredTimeSpan, $currentTimeSpan) -ne 0 -and [System.TimeSpan]::Compare(($desiredTimeSpan - $currentTimeSpan).Duration(), $delta) -le 0)
                    {
                        Write-Verbose -Message "Difference between Desired and Current WarnAfter is less than or equal to 30 seconds. Desired: $desiredTimeSpan, Current: $currentTimeSpan. Treating as equal."
                        $ValuesToCheck.Remove('WarnAfter') | Out-Null
                    }
                }
                return [System.Tuple[Hashtable, Hashtable, Hashtable]]::new($DesiredValues, $CurrentValues, $ValuesToCheck)
            }
        }
    }

    # Materialises a Get() result. The script-based body built a hashtable; DSC needs the type.
    hidden [SPOBrowserIdleSignout] AsResult([System.Object] $Values)
    {
        if ($Values -is [SPOBrowserIdleSignout])
        {
            return $Values
        }

        $result = [SPOBrowserIdleSignout]::new()
        if ($Values -is [System.Collections.Hashtable])
        {
            $result.FromHashtable($Values)
        }

        return $result
    }
}

