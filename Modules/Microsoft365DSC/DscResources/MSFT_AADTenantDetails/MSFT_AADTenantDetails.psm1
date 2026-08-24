# Editor-only: lets this file resolve [M365DSCResourceBase] when parsed on its own.
# Build-Microsoft365DSC.ps1 emits only the class extent, so this line is not shipped.
using module ..\_Base\M365DSCResourceBase.psm1

[DscResource()]
class AADTenantDetails : M365DSCResourceBase
{
    [DscProperty(Key)]
    [System.ComponentModel.Description('Only valid value is ''Yes''.')]
    [ValidateSet('Yes')]
    [System.String] $IsSingleInstance

    [DscProperty()]
    [System.ComponentModel.Description('Email-addresses from the people who should receive Marketing Notifications')]
    [System.String[]] $MarketingNotificationEmails

    [DscProperty()]
    [System.ComponentModel.Description('Email-addresses from the people who should receive Security Compliance Notifications')]
    [System.String[]] $SecurityComplianceNotificationMails

    [DscProperty()]
    [System.ComponentModel.Description('Phone Numbers from the people who should receive Security Notifications')]
    [System.String[]] $SecurityComplianceNotificationPhones

    [DscProperty()]
    [System.ComponentModel.Description('Email-addresses from the people who should receive Technical Notifications')]
    [System.String[]] $TechnicalNotificationMails

    [DscProperty()]
    [System.ComponentModel.Description('Credentials of the Azure Active Directory Admin')]
    [System.Management.Automation.PSCredential] $Credential

    [DscProperty()]
    [System.ComponentModel.Description('Id of the Azure Active Directory application to authenticate with.')]
    [System.String] $ApplicationId

    [DscProperty()]
    [System.ComponentModel.Description('Id of the Azure Active Directory tenant used for authentication.')]
    [System.String] $TenantId

    [DscProperty()]
    [System.ComponentModel.Description('Secret of the Azure Active Directory application to authenticate with.')]
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

    [AADTenantDetails] Get()
    {
        if ($this.RequiresPowerShellCore())
        {
            $remote = [AADTenantDetails]::new()
            $remote.FromHashtable($this.InvokeInPowerShellCore('Get'))
            return $remote
        }

        Write-Verbose -Message 'Getting configuration of AzureAD Tenant Details'

        try
        {
            $null = $this.Connect('MicrosoftGraph')

            #Ensure the proper dependencies are installed in the current environment.
            Confirm-M365DSCDependencies

            #region Telemetry
            $this.AddTelemetry('Get')
            #endregion

            $aadTenantDetails = Get-MgBetaOrganization -ErrorAction Stop

            Write-Verbose -Message 'Found existing AzureAD Tenant Details'
            $result = @{
                IsSingleInstance                     = 'Yes'
                MarketingNotificationEmails          = $aadTenantDetails.MarketingNotificationEmails
                SecurityComplianceNotificationMails  = $aadTenantDetails.SecurityComplianceNotificationMails
                SecurityComplianceNotificationPhones = $aadTenantDetails.SecurityComplianceNotificationPhones
                TechnicalNotificationMails           = $aadTenantDetails.TechnicalNotificationMails
                Credential                           = $this.Credential
                ApplicationId                        = $this.ApplicationId
                TenantId                             = $this.TenantId
                ApplicationSecret                    = $this.ApplicationSecret
                CertificateThumbprint                = $this.CertificateThumbprint
                CertificatePath                      = $this.CertificatePath
                CertificatePassword                  = $this.CertificatePassword
                ManagedIdentity                      = $this.ManagedIdentity.IsPresent
                AccessTokens                         = $this.AccessTokens
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

        Write-Verbose -Message 'Setting configuration of AzureAD Tenant Details'

        $null = $this.Connect('MicrosoftGraph')

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Set')
        #endregion

        $currentParameters = Remove-M365DSCAuthenticationParameter -BoundParameters $this.GetBoundParameters()
        $currentParameters.Remove('IsSingleInstance') | Out-Null

        try
        {
            Write-Verbose -Message 'Calling Update-MGBetaOrganization with parameters:'
            Write-Verbose -Message "$(Convert-M365DscHashtableToString -Hashtable $currentParameters)"
            Update-MgBetaOrganization -OrganizationId (Get-MgBetaOrganization).Id -BodyParameter $currentParameters
        }
        catch
        {
            Write-Verbose -Message 'Cannot Set AzureAD Tenant Details'
        }
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

        $dscContent = [System.Text.StringBuilder]::new()
        try
        {
            if ($null -ne $Global:M365DSCExportResourceInstancesCount)
            {
                $Global:M365DSCExportResourceInstancesCount++
            }

            $aadTenantDetails = Get-MgBetaOrganization -ErrorAction Stop

            $Params = @{
                MarketingNotificationEmails          = $aadTenantDetails.MarketingNotificationEmails
                SecurityComplianceNotificationMails  = $aadTenantDetails.SecurityComplianceNotificationMails
                SecurityComplianceNotificationPhones = $aadTenantDetails.SecurityComplianceNotificationPhones
                TechnicalNotificationMails           = $aadTenantDetails.TechnicalNotificationMails
                IsSingleInstance                     = 'Yes'
                Credential                           = $this.Credential
                ApplicationId                        = $this.ApplicationId
                TenantId                             = $this.TenantId
                ApplicationSecret                    = $this.ApplicationSecret
                CertificateThumbprint                = $this.CertificateThumbprint
                CertificatePath                      = $this.CertificatePath
                CertificatePassword                  = $this.CertificatePassword
                ManagedIdentity                      = $this.ManagedIdentity.IsPresent
                AccessTokens                         = $this.AccessTokens
            }

            $Results = $this.GetForExport($Params)
            if ($Results -is [System.Collections.Hashtable] -and $Results.Count -gt 1)
            {
                $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $this.GetResourceName() -ConnectionMode $ConnectionMode `
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

    hidden [AADTenantDetails] AsResult([System.Object] $Values)
    {
        if ($Values -is [AADTenantDetails])
        {
            return $Values
        }

        $result = [AADTenantDetails]::new()
        if ($Values -is [System.Collections.Hashtable])
        {
            $result.FromHashtable($Values)
        }

        return $result
    }
}
