# Editor-only: lets this file resolve [M365DSCResourceBase] when parsed on its own.
# Build-Microsoft365DSC.ps1 emits only the class extent, so this line is not shipped.
using module ..\_Base\M365DSCResourceBase.psm1

[DscResource()]
class SCSecurityFilter : M365DSCResourceBase
{
    [DscProperty(Key)]
    [System.ComponentModel.Description('The FilterName parameter specifies the name of the compliance security filter that you want to view. If the value contains spaces, enclose the value in quotation marks (\')]
    [System.String] $FilterName

    [DscProperty()]
    [System.ComponentModel.Description('The Action parameter filters the results by the type of search action that a filter is applied to. ')]
    [ValidateSet('Export', 'Preview', 'Purge', 'Search', 'All')]
    [System.String] $Action

    [DscProperty()]
    [System.ComponentModel.Description('The User parameter filters the results by the user who gets a filter applied to their searches. Acceptable values are : The alias or email address of a user, All or The name of a role group')]
    [System.String[]] $Users

    [DscProperty()]
    [System.ComponentModel.Description('The Description parameter specifies a description for the compliance security filter. The maximum length is 256 characters. If the value contains spaces, enclose the value in quotation marks (\')]
    [System.String] $Description

    [DscProperty()]
    [System.ComponentModel.Description('The Filters parameter specifies the search criteria for the compliance security filter. The filters are applied to the users specified by the Users parameter. You can create three different types of filters: Mailbox filter, Mailbox content filter or Site and site content filter')]
    [System.String[]] $Filters

    [DscProperty()]
    [System.ComponentModel.Description('The Region parameter specifies the satellite location for multi-geo tenants to conduct eDiscovery searches in.')]
    [ValidateSet('APC', 'AUS', 'CAN', 'EUR', 'FRA', 'GBR', 'IND', 'JPN', 'LAM', 'NAM', '')]
    [System.String] $Region

    [DscProperty()]
    [System.ComponentModel.Description('Specify if this label policy should exist or not.')]
    [ValidateSet('Present', 'Absent')]
    [System.String] $Ensure

    [DscProperty()]
    [System.ComponentModel.Description('Credentials of the Exchange Global Admin')]
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
    [System.ComponentModel.Description('Path to certificate used in service principal usually a PFX file.')]
    [System.String] $CertificatePath

    [DscProperty()]
    [System.ComponentModel.Description('Username can be made up to anything but password will be used for CertificatePassword')]
    [System.Management.Automation.PSCredential] $CertificatePassword

    [DscProperty()]
    [System.ComponentModel.Description('Managed ID being used for authentication.')]
    [System.Nullable[System.Boolean]] $ManagedIdentity

    [DscProperty()]
    [System.ComponentModel.Description('Access token used for authentication.')]
    [System.String[]] $AccessTokens

    [SCSecurityFilter] Get()
    {
        if ($this.RequiresPowerShellCore())
        {
            $remote = [SCSecurityFilter]::new()
            $remote.FromHashtable($this.InvokeInPowerShellCore('Get'))
            return $remote
        }

        Write-Verbose -Message "Getting configuration of Security Filter for $($this.FilterName)"

        try
        {
            $null = $this.Connect('SecurityComplianceCenter')

            #Ensure the proper dependencies are installed in the current environment.
            Confirm-M365DSCDependencies

            #region Telemetry
            $this.AddTelemetry('Get')
            #endregion

            $nullReturn = $this.GetBoundParameters()
            $nullReturn.Ensure = 'Absent'

            $secFilter = Get-ComplianceSecurityFilter -FilterName $this.FilterName -ErrorAction SilentlyContinue -WarningAction Ignore -Confirm:$false

            if ($null -eq $secFilter)
            {
                Write-Verbose -Message "Security Filter $($this.FilterName) does not exist."
                return $this.AsResult($nullReturn)
            }
            else
            {
                Write-Verbose "Found existing Security Filter $($this.FilterName)"
                $result = Get-SCSecurityFilterM365DSCSCMapSecurityFilter -Filter $secFilter -Credential $this.Credential -ApplicationId $this.ApplicationId -TenantId $this.TenantId -CertificateThumbprint $this.CertificateThumbprint -CertificatePath $this.CertificatePath -CertificatePassword $this.CertificatePassword

                return $this.AsResult($result)
            }
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

        Write-Verbose -Message "Setting configuration of Security Filter for $($this.FilterName)"

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Set')
        #endregion

        $CurrentFilter = $this.Get().ToHashtable()

        if ($this.Ensure -eq 'Present' -and $CurrentFilter.Ensure -eq 'Absent')
        {
            Write-Verbose "Creating new Security Filter '$($this.FilterName)'."

            $CreationParams = Remove-M365DSCAuthenticationParameter -BoundParameters $this.GetBoundParameters()

            try
            {
                New-ComplianceSecurityFilter @CreationParams -Confirm:$false
            }
            catch
            {
                Write-Warning "New-ComplianceSecurityFilter is not available in tenant $($this.Credential.UserName.Split('@')[1]): $_"
            }
        }
        elseif ($this.Ensure -eq 'Present' -and $CurrentFilter.Ensure -eq 'Present')
        {
            Write-Verbose "Updating existing Security Filter '$($this.FilterName)'."

            $SetParams = Remove-M365DSCAuthenticationParameter -BoundParameters $this.GetBoundParameters()

            try
            {
                Set-ComplianceSecurityFilter @SetParams -Confirm:$false
            }
            catch
            {
                Write-Warning "Set-ComplianceSecurityFilter is not available in tenant $($this.Credential.UserName.Split('@')[1]): $_"
            }
        }
        elseif ($this.Ensure -eq 'Absent' -and $CurrentFilter.Ensure -eq 'Present')
        {
            # If the filter exists and it shouldn't, simply remove it;Need to force deletion
            Write-Verbose -Message "Deleting Security Filter $($this.FilterName)."

            try
            {
                Remove-ComplianceSecurityFilter -FilterName $this.FilterName -Confirm:$false
            }
            catch
            {
                Write-Warning "emove-ComplianceSecurityFilter is not available in tenant $($this.Credential.UserName.Split('@')[1]): $_"
            }
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

        $ConnectionMode = $this.Connect('SecurityComplianceCenter')

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Export')
        #endregion

        try
        {
            [array]$this.filters = Get-ComplianceSecurityFilter -ErrorAction Stop -WarningAction Ignore -Confirm:$false

            $dscContent = [System.Text.StringBuilder]::new()
            $i = 1
            if ($this.filters.Length -eq 0)
            {
                Write-M365DSCHost -Message $Global:M365DSCEmojiGreenCheckMark -CommitWrite
            }
            else
            {
                Write-M365DSCHost -Message "`r`n" -DeferWrite
            }
            foreach ($filter in $this.filters)
            {
                if ($null -ne $Global:M365DSCExportResourceInstancesCount)
                {
                    $Global:M365DSCExportResourceInstancesCount++
                }

                Write-M365DSCHost -Message "    |---[$i/$($this.filters.Count)] $($filter.FilterName)" -DeferWrite

                $Results = Get-SCSecurityFilterM365DSCSCMapSecurityFilter -Filter $filter -Credential $this.Credential -ApplicationId $this.ApplicationId `
                    -TenantId $this.TenantId -CertificateThumbprint $this.CertificateThumbprint -CertificatePath $this.CertificatePath -CertificatePassword $this.CertificatePassword
                $rawResults = $Results.Clone()

                $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $this.GetResourceName() `
                    -ConnectionMode $ConnectionMode `
                    -ModulePath $this.GetModulePath() `
                    -Results $Results `
                    -Credential $this.Credential `
                    -RawResults $rawResults

                Write-M365DSCHost -Message $Global:M365DSCEmojiGreenCheckMark -CommitWrite
                [void]$dscContent.Append($currentDSCBlock)
                Save-M365DSCPartialExport -Content $currentDSCBlock `
                    -FileName $Global:PartialExportFileName
                $i++
            }
        }
        catch
        {
            $this.LogError($_, 'Error during Export:')

            throw
        }
        return $dscContent.ToString()
    }

    # Materialises a Get() result. The script-based body built a hashtable; DSC needs the type.
    hidden [SCSecurityFilter] AsResult([System.Object] $Values)
    {
        if ($Values -is [SCSecurityFilter])
        {
            return $Values
        }

        $result = [SCSecurityFilter]::new()
        if ($Values -is [System.Collections.Hashtable])
        {
            $result.FromHashtable($Values)
        }

        return $result
    }
}

# Was Get-M365DSCSCMapSecurityFilter. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Get-SCSecurityFilterM365DSCSCMapSecurityFilter
{
    param(
        [Parameter(Mandatory = $true)]
        $Filter,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )
    $result = @{
        FilterName            = $Filter.FilterName
        Action                = $Filter.Action
        Users                 = $Filter.Users
        Description           = $Filter.Description
        Filters               = $Filter.Filters
        Region                = $Filter.Region
        Ensure                = 'Present'
        Credential            = $Credential
        ApplicationId         = $ApplicationId
        TenantId              = $TenantId
        CertificateThumbprint = $CertificateThumbprint
        CertificatePath       = $CertificatePath
        CertificatePassword   = $CertificatePassword
        ManagedIdentity       = $ManagedIdentity.IsPresent
        AccessTokens          = $AccessTokens
    }
    return $result
}

