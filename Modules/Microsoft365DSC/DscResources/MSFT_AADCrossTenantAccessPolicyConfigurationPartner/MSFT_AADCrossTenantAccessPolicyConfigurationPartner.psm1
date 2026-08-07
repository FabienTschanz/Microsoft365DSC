# Editor-only: lets this file resolve [M365DSCResourceBase] when parsed on its own.
# Build-Microsoft365DSC.ps1 emits only the class extent, so this line is not shipped.
using module ..\_Base\M365DSCResourceBase.psm1

[DscResource()]
class AADCrossTenantAccessPolicyConfigurationPartner : M365DSCResourceBase
{
    [DscProperty(Key)]
    [System.ComponentModel.Description('The tenant identifier for the partner Azure Active Directory (Azure AD) organization.')]
    [System.String] $PartnerTenantId

    [DscProperty()]
    [System.ComponentModel.Description('Defines your partner-specific configuration for users from other organizations accessing your resources via Azure AD B2B collaboration.')]
    [MSFT_AADCrossTenantAccessPolicyB2BSetting] $B2BCollaborationInbound

    [DscProperty()]
    [System.ComponentModel.Description('Defines your partner-specific configuration for users in your organization going outbound to access resources in another organization via Azure AD B2B collaboration.')]
    [MSFT_AADCrossTenantAccessPolicyB2BSetting] $B2BCollaborationOutbound

    [DscProperty()]
    [System.ComponentModel.Description('Defines your partner-specific configuration for users from other organizations accessing your resources via Azure AD B2B direct connect.')]
    [MSFT_AADCrossTenantAccessPolicyB2BSetting] $B2BDirectConnectInbound

    [DscProperty()]
    [System.ComponentModel.Description('Defines your partner-specific configuration for users in your organization going outbound to access resources in another organization via Azure AD B2B direct connect.')]
    [MSFT_AADCrossTenantAccessPolicyB2BSetting] $B2BDirectConnectOutbound

    [DscProperty()]
    [System.ComponentModel.Description('Determines the partner-specific configuration for accepting trust claims from other tenant invitations.')]
    [MSFT_AADCrossTenantAccessPolicyAutomaticUserConsentSettings] $AutomaticUserConsentSettings

    [DscProperty()]
    [System.ComponentModel.Description('Defines the identity synchronization settings.')]
    [MSFT_AADCrossTenantIdentitySyncPolicyPartnerInbound] $IdentitySynchronization

    [DscProperty()]
    [System.ComponentModel.Description('Determines the partner-specific configuration for trusting other Conditional Access claims from external Azure AD organizations.')]
    [MSFT_AADCrossTenantAccessPolicyInboundTrust] $InboundTrust

    [DscProperty()]
    [System.ComponentModel.Description('Specify if the policy should exist or not.')]
    [ValidateSet('Present', 'Absent')]
    [System.String] $Ensure

    [DscProperty()]
    [System.ComponentModel.Description('Credentials of the Admin')]
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

    # Export-only. Not part of the resource schema.
    [System.String] $Filter

    [AADCrossTenantAccessPolicyConfigurationPartner] Get()
    {
        # Declared up front: assigned conditionally below, which class methods reject.
        $AutomaticUserConsentSettingsValue = $null
        # Declared up front: assigned conditionally below, which class methods reject.
        $B2BDirectConnectInboundValue = $null
        # Declared up front: assigned conditionally below, which class methods reject.
        $B2BCollaborationOutboundValue = $null
        # Declared up front: assigned conditionally below, which class methods reject.
        $IdentitySynchronizationValue = $null
        # Declared up front: assigned conditionally below, which class methods reject.
        $B2BDirectConnectOutboundValue = $null
        # Declared up front: assigned conditionally below, which class methods reject.
        $InboundTrustValue = $null
        if ($this.RequiresPowerShellCore())
        {
            $remote = [AADCrossTenantAccessPolicyConfigurationPartner]::new()
            $remote.FromHashtable($this.InvokeInPowerShellCore('Get'))
            return $remote
        }

        Write-Verbose -Message "Getting configuration of AzureAD Cross Tenant Access Policy Configuration Partner for TenantId {$($this.PartnerTenantId)}"

        try
        {
            if (-not $this.ExportedInstance -or $this.ExportedInstance.TenantId -ne $this.PartnerTenantId)
            {
                $null = $this.Connect('MicrosoftGraph')

                #Ensure the proper dependencies are installed in the current environment.
                Confirm-M365DSCDependencies

                #region Telemetry
                $this.AddTelemetry('Get')
                #endregion

                $nullResult = $this.GetBoundParameters()
                $nullResult.Ensure = 'Absent'

                $getValue = Get-MgBetaPolicyCrossTenantAccessPolicyPartner -CrossTenantAccessPolicyConfigurationPartnerTenantId $this.PartnerTenantId `
                    -ExpandProperty "IdentitySynchronization" `
                    -ErrorAction SilentlyContinue

                if ($null -eq $getValue)
                {
                    Write-Verbose -Message "Could not find an Azure AD Cross Tenant Access Configuration Partner with TenantId {$($this.PartnerTenantId)}"
                    return $this.AsResult($nullResult)
                }
            }
            else
            {
                $getValue = $this.ExportedInstance
            }

            $B2BCollaborationInboundValue = $null
            if ($null -ne $getValue.B2BCollaborationInbound -and (Test-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCB2BIsDefault -B2BSetting $getValue.B2BCollaborationInbound) -eq $false)
            {
                $B2BCollaborationInboundValue = $getValue.B2BCollaborationInbound
            }
            if ($null -ne $getValue.B2BCollaborationOutbound -and (Test-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCB2BIsDefault -B2BSetting $getValue.B2BCollaborationOutbound) -eq $false)
            {
                $B2BCollaborationOutboundValue = $getValue.B2BCollaborationOutbound
            }
            if ($null -ne $getValue.B2BDirectConnectInbound -and (Test-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCB2BIsDefault -B2BSetting $getValue.B2BDirectConnectInbound) -eq $false)
            {
                $B2BDirectConnectInboundValue = $getValue.B2BDirectConnectInbound
            }
            if ($null -ne $getValue.B2BDirectConnectOutbound -and (Test-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCB2BIsDefault -B2BSetting $getValue.B2BDirectConnectOutbound) -eq $false)
            {
                $B2BDirectConnectOutboundValue = $getValue.B2BDirectConnectOutbound
            }
            if ($null -ne $getValue.AutomaticUserConsentSettings)
            {
                $AutomaticUserConsentSettingsValue = $getValue.AutomaticUserConsentSettings
            }
            if ($null -ne $getValue.InboundTrust)
            {
                $InboundTrustValue = $getValue.InboundTrust
            }
            if ($null -ne $getValue.IdentitySynchronization)
            {
                $IdentitySynchronizationValue = [ordered]@{
                    GroupSyncInbound = @{
                        IsSyncAllowed = $getValue.IdentitySynchronization.GroupSyncInbound.IsSyncAllowed
                    }
                    UserSyncInbound = @{
                        IsSyncAllowed = $getValue.IdentitySynchronization.UserSyncInbound.IsSyncAllowed
                    }
                }
                if ($null -eq $getValue.IdentitySynchronization.GroupSyncInbound.IsSyncAllowed)
                {
                    $IdentitySynchronizationValue.Remove('GroupSyncInbound') | Out-Null
                }
                if ($null -eq $getValue.IdentitySynchronization.UserSyncInbound.IsSyncAllowed)
                {
                    $IdentitySynchronizationValue.Remove('UserSyncInbound') | Out-Null
                }
            }
            $results = @{
                PartnerTenantId              = $getValue.TenantId
                B2BCollaborationInbound      = $B2BCollaborationInboundValue
                B2BCollaborationOutbound     = $B2BCollaborationOutboundValue
                B2BDirectConnectInbound      = $B2BDirectConnectInboundValue
                B2BDirectConnectOutbound     = $B2BDirectConnectOutboundValue
                AutomaticUserConsentSettings = $AutomaticUserConsentSettingsValue
                IdentitySynchronization      = $IdentitySynchronizationValue
                InboundTrust                 = $InboundTrustValue
                Ensure                       = 'Present'
                Credential                   = $this.Credential
                ApplicationId                = $this.ApplicationId
                TenantId                     = $this.TenantId
                ApplicationSecret            = $this.ApplicationSecret
                CertificateThumbprint        = $this.CertificateThumbprint
                CertificatePath              = $this.CertificatePath
                CertificatePassword          = $this.CertificatePassword
                ManagedIdentity              = $this.ManagedIdentity.IsPresent
                AccessTokens                 = $this.AccessTokens
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
        $identitySynchronizationValue = $null
        if ($this.RequiresPowerShellCore())
        {
            $null = $this.InvokeInPowerShellCore('Set')
            return
        }

        Write-Verbose -Message "Setting configuration of AzureAD Cross Tenant Access Policy Configuration Partner for TenantId {$($this.PartnerTenantId)}"

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Set')
        #endregion

        $currentInstance = $this.Get().ToHashtable()
        $OperationParams = Remove-M365DSCAuthenticationParameter -BoundParameters $this.GetBoundParameters()

        if ($null -ne $OperationParams.B2BCollaborationInbound)
        {
            $OperationParams.B2BCollaborationInbound = (Get-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCAADCrossTenantAccessPolicyB2BSetting -Setting $OperationParams.B2BCollaborationInbound)
            $OperationParams.B2BCollaborationInbound = (Update-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCSettingUserIdFromUPN -Setting $OperationParams.B2BCollaborationInbound)
        }
        if ($null -ne $OperationParams.B2BCollaborationOutbound)
        {
            $OperationParams.B2BCollaborationOutbound = (Get-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCAADCrossTenantAccessPolicyB2BSetting -Setting $OperationParams.B2BCollaborationOutbound)
            $OperationParams.B2BCollaborationOutbound = (Update-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCSettingUserIdFromUPN -Setting $OperationParams.B2BCollaborationOutbound)
        }
        if ($null -ne $OperationParams.B2BDirectConnectInbound)
        {
            $OperationParams.B2BDirectConnectInbound = (Get-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCAADCrossTenantAccessPolicyB2BSetting -Setting $OperationParams.B2BDirectConnectInbound)
            $OperationParams.B2BDirectConnectInbound = (Update-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCSettingUserIdFromUPN -Setting $OperationParams.B2BDirectConnectInbound)
        }
        if ($null -ne $OperationParams.B2BDirectConnectOutbound)
        {
            $OperationParams.B2BDirectConnectOutbound = (Get-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCAADCrossTenantAccessPolicyB2BSetting -Setting $OperationParams.B2BDirectConnectOutbound)
            $OperationParams.B2BDirectConnectOutbound = (Update-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCSettingUserIdFromUPN -Setting $OperationParams.B2BDirectConnectOutbound)
        }
        if ($null -ne $OperationParams.AutomaticUserConsentSettings)
        {
            $OperationParams.AutomaticUserConsentSettings = (Get-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCAADCrossTenantAccessPolicyAutomaticUserConsentSettings -Setting $OperationParams.AutomaticUserConsentSettings)
        }
        if ($null -ne $OperationParams.InboundTrust)
        {
            $OperationParams.InboundTrust = (Get-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCAADCrossTenantAccessPolicyInboundTrust -Setting $OperationParams.InboundTrust)
        }
        if ($null -ne $OperationParams.IdentitySynchronization)
        {
            $identitySynchronizationValue = (Get-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCAADCrossTenantAccessPolicyIdentitySynchronization -Setting $OperationParams.IdentitySynchronization)
            $OperationParams.Remove('IdentitySynchronization') | Out-Null
        }

        $OperationParams = Rename-M365DSCCimInstanceParameter -Properties $OperationParams -KeyMapping @{
            B2BCollaborationInbound  = 'b2bCollaborationInbound'
            B2BCollaborationOutbound = 'b2bCollaborationOutbound'
            B2BDirectConnectInbound  = 'b2bDirectConnectInbound'
            B2BDirectConnectOutbound = 'b2bDirectConnectOutbound'
        }

        if ($this.Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Absent')
        {
            Write-Verbose -Message "Creating new Cross Tenant Access Policy Configuration Partner entry for TenantId {$($this.PartnerTenantId)}"
            $OperationParams.Add('tenantId', $this.PartnerTenantId)
            $OperationParams.Remove('PartnerTenantId') | Out-Null
            $newPartner = New-MgBetaPolicyCrossTenantAccessPolicyPartner -BodyParameter $OperationParams
            Start-Sleep -Seconds 2
            if ($newPartner.TenantId -and $null -ne $identitySynchronizationValue)
            {
                try
                {
                    Invoke-MgGraphRequest -Uri "/beta/policies/crossTenantAccessPolicy/partners/$($newPartner.TenantId)/identitySynchronization" -Method PUT -Body $identitySynchronizationValue
                }
                catch
                {
                    if ($_.ErrorDetails.Message -notlike '*Conflict*')
                    {
                        throw
                    }
                    Invoke-MgGraphRequest -Uri "/beta/policies/crossTenantAccessPolicy/partners/$($newPartner.TenantId)/identitySynchronization" -Method PATCH -Body $identitySynchronizationValue
                }
            }
        }
        elseif ($this.Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Present')
        {
            Write-Verbose -Message "Updating Cross Tenant Access Policy Configuration Partner entry with TenantId {$($this.PartnerTenantId)}"
            $OperationParams.Remove('PartnerTenantId') | Out-Null
            Update-MgBetaPolicyCrossTenantAccessPolicyPartner -CrossTenantAccessPolicyConfigurationPartnerTenantId $this.PartnerTenantId -BodyParameter $OperationParams
            if ($null -ne $identitySynchronizationValue)
            {
                try
                {
                    Invoke-MgGraphRequest -Uri "/beta/policies/crossTenantAccessPolicy/partners/$($this.PartnerTenantId)/identitySynchronization" -Method PATCH -Body $identitySynchronizationValue
                }
                catch
                {
                    if ($_.ErrorDetails.Message -notlike '*Not Found*')
                    {
                        throw
                    }
                    Invoke-MgGraphRequest -Uri "/beta/policies/crossTenantAccessPolicy/partners/$($this.PartnerTenantId)/identitySynchronization" -Method PUT -Body $identitySynchronizationValue
                }
            }
        }
        elseif ($this.Ensure -eq 'Absent' -and $currentInstance.Ensure -eq 'Present')
        {
            Write-Verbose -Message "Removing Cross Tenant Access Policy Configuration Partner entry with TenantId {$($this.PartnerTenantId)}"
            Remove-MgBetaPolicyCrossTenantAccessPolicyPartner -CrossTenantAccessPolicyConfigurationPartnerTenantId $this.PartnerTenantId
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

        try
        {
            [array]$getValue = Get-MgBetaPolicyCrossTenantAccessPolicyPartner `
                -All `
                -Filter $this.Filter `
                -ExpandProperty "IdentitySynchronization" `
                -ErrorAction Stop

            $i = 1
            $dscContent = [System.Text.StringBuilder]::new()
            Write-M365DSCHost -Message "`r`n" -DeferWrite
            foreach ($entry in $getValue)
            {
                if ($null -ne $Global:M365DSCExportResourceInstancesCount)
                {
                    $Global:M365DSCExportResourceInstancesCount++
                }

                Write-M365DSCHost -Message "    |---[$i/$($getValue.Count)] $($entry.TenantId)" -DeferWrite
                $Params = @{
                    PartnerTenantId       = $entry.TenantId
                    ApplicationSecret     = $this.ApplicationSecret
                    ApplicationId         = $this.ApplicationId
                    TenantId              = $this.TenantId
                    CertificateThumbprint = $this.CertificateThumbprint
                    Credential            = $this.Credential
                    CertificatePath       = $this.CertificatePath
                    CertificatePassword   = $this.CertificatePassword
                    ManagedIdentity       = $this.ManagedIdentity.IsPresent
                    AccessTokens          = $this.AccessTokens
                }

                $this.ExportedInstance = $entry
                $Results = $this.GetForExport($Params)

                if ($null -ne $Results.B2BCollaborationInbound)
                {
                    $complexMapping = @(
                        @{
                            Name            = 'B2BCollaborationInbound'
                            CimInstanceName = 'AADCrossTenantAccessPolicyB2BSetting'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'Applications'
                            CimInstanceName = 'AADCrossTenantAccessPolicyTargetConfiguration'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'UsersAndGroups'
                            CimInstanceName = 'AADCrossTenantAccessPolicyTargetConfiguration'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'Targets'
                            CimInstanceName = 'AADCrossTenantAccessPolicyTarget'
                            IsRequired      = $False
                        }
                    )
                    $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                        -ComplexObject $Results.B2BCollaborationInbound `
                        -CIMInstanceName 'AADCrossTenantAccessPolicyB2BSetting' `
                        -ComplexTypeMapping $complexMapping

                    if (-not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                    {
                        $Results.B2BCollaborationInbound = $complexTypeStringResult
                    }
                    else
                    {
                        $Results.Remove('B2BCollaborationInbound') | Out-Null
                    }
                }

                if ($null -ne $Results.AutomaticUserConsentSettings)
                {
                    $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                        -ComplexObject $Results.AutomaticUserConsentSettings `
                        -CIMInstanceName 'AADCrossTenantAccessPolicyAutomaticUserConsentSettings'

                    if (-not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                    {
                        $Results.AutomaticUserConsentSettings = $complexTypeStringResult
                    }
                    else
                    {
                        $Results.Remove('AutomaticUserConsentSettings') | Out-Null
                    }
                }

                if ($null -ne $Results.B2BCollaborationOutbound)
                {
                    $complexMapping = @(
                        @{
                            Name            = 'B2BCollaborationOutbound'
                            CimInstanceName = 'AADCrossTenantAccessPolicyB2BSetting'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'Applications'
                            CimInstanceName = 'AADCrossTenantAccessPolicyTargetConfiguration'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'UsersAndGroups'
                            CimInstanceName = 'AADCrossTenantAccessPolicyTargetConfiguration'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'Targets'
                            CimInstanceName = 'AADCrossTenantAccessPolicyTarget'
                            IsRequired      = $False
                        }
                    )
                    $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                        -ComplexObject $Results.B2BCollaborationOutbound `
                        -CIMInstanceName 'AADCrossTenantAccessPolicyB2BSetting' `
                        -ComplexTypeMapping $complexMapping

                    if (-not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                    {
                        $Results.B2BCollaborationOutbound = $complexTypeStringResult
                    }
                    else
                    {
                        $Results.Remove('B2BCollaborationOutbound') | Out-Null
                    }
                }

                if ($null -ne $Results.B2BDirectConnectInbound)
                {
                    $complexMapping = @(
                        @{
                            Name            = 'B2BDirectConnectInbound'
                            CimInstanceName = 'AADCrossTenantAccessPolicyB2BSetting'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'Applications'
                            CimInstanceName = 'AADCrossTenantAccessPolicyTargetConfiguration'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'UsersAndGroups'
                            CimInstanceName = 'AADCrossTenantAccessPolicyTargetConfiguration'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'Targets'
                            CimInstanceName = 'AADCrossTenantAccessPolicyTarget'
                            IsRequired      = $False
                        }
                    )
                    $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                        -ComplexObject $Results.B2BDirectConnectInbound `
                        -CIMInstanceName 'AADCrossTenantAccessPolicyB2BSetting' `
                        -ComplexTypeMapping $complexMapping

                    if (-not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                    {
                        $Results.B2BDirectConnectInbound = $complexTypeStringResult
                    }
                    else
                    {
                        $Results.Remove('B2BDirectConnectInbound') | Out-Null
                    }
                }

                if ($null -ne $Results.B2BDirectConnectOutbound)
                {
                    $complexMapping = @(
                        @{
                            Name            = 'B2BDirectConnectOutbound'
                            CimInstanceName = 'AADCrossTenantAccessPolicyB2BSetting'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'Applications'
                            CimInstanceName = 'AADCrossTenantAccessPolicyTargetConfiguration'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'UsersAndGroups'
                            CimInstanceName = 'AADCrossTenantAccessPolicyTargetConfiguration'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'Targets'
                            CimInstanceName = 'AADCrossTenantAccessPolicyTarget'
                            IsRequired      = $False
                        }
                    )
                    $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                        -ComplexObject $Results.B2BDirectConnectOutbound `
                        -CIMInstanceName 'AADCrossTenantAccessPolicyB2BSetting' `
                        -ComplexTypeMapping $complexMapping

                    if (-not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                    {
                        $Results.B2BDirectConnectOutbound = $complexTypeStringResult
                    }
                    else
                    {
                        $Results.Remove('B2BDirectConnectOutbound') | Out-Null
                    }
                }

                if ($null -ne $Results.InboundTrust)
                {
                    $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                        -ComplexObject $Results.InboundTrust `
                        -CIMInstanceName 'AADCrossTenantAccessPolicyInboundTrust'

                    if (-not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                    {
                        $Results.InboundTrust = $complexTypeStringResult
                    }
                    else
                    {
                        $Results.Remove('InboundTrust') | Out-Null
                    }
                }

                if ($null -ne $Results.IdentitySynchronization)
                {
                    $complexMapping = @(
                        @{
                            Name            = 'IdentitySynchronization'
                            CimInstanceName = 'AADCrossTenantIdentitySyncPolicyPartnerInbound'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'GroupSyncInbound'
                            CimInstanceName = 'AADCrossTenantGroupSyncInbound'
                            IsRequired      = $False
                        },
                        @{
                            Name            = 'UserSyncInbound'
                            CimInstanceName = 'AADCrossTenantUserSyncInbound'
                            IsRequired      = $False
                        }
                    )
                    $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                        -ComplexObject $Results.IdentitySynchronization `
                        -CIMInstanceName 'AADCrossTenantIdentitySyncPolicyPartnerInbound' `
                        -ComplexTypeMapping $complexMapping

                    if (-not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                    {
                        $Results.IdentitySynchronization = $complexTypeStringResult
                    }
                    else
                    {
                        $Results.Remove('IdentitySynchronization') | Out-Null
                    }
                }

                $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $this.GetResourceName() `
                    -ConnectionMode $ConnectionMode `
                    -ModulePath $this.GetModulePath() `
                    -Results $Results `
                    -Credential $this.Credential `
                    -NoEscape @('B2BCollaborationInbound', 'B2BCollaborationOutbound', 'B2BDirectConnectInbound', 'B2BDirectConnectOutbound', 'InboundTrust', 'AutomaticUserConsentSettings', 'IdentitySynchronization')

                # Fix OrganizationName variable in CIMInstance
                $currentDSCBlock = $currentDSCBlock.Replace('@$OrganizationName''', "@' + `$OrganizationName")

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

    # Materialises a Get() result. The script-based body built a hashtable; DSC needs the type.
    hidden [AADCrossTenantAccessPolicyConfigurationPartner] AsResult([System.Object] $Values)
    {
        if ($Values -is [AADCrossTenantAccessPolicyConfigurationPartner])
        {
            return $Values
        }

        $result = [AADCrossTenantAccessPolicyConfigurationPartner]::new()
        if ($Values -is [System.Collections.Hashtable])
        {
            $result.FromHashtable($Values)
        }

        return $result
    }
}

class MSFT_AADCrossTenantAccessPolicyB2BSetting
{
    [DscProperty()]
    [System.ComponentModel.Description('The list of applications targeted with your cross-tenant access policy.')]
    [MSFT_AADCrossTenantAccessPolicyTargetConfiguration] $Applications

    [DscProperty()]
    [System.ComponentModel.Description('The list of users and groups targeted with your cross-tenant access policy.')]
    [MSFT_AADCrossTenantAccessPolicyTargetConfiguration] $UsersAndGroups
}

class MSFT_AADCrossTenantAccessPolicyAutomaticUserConsentSettings
{
    [DscProperty()]
    [System.ComponentModel.Description('Specifies whether you want to automatically trust Inbound invitations.')]
    [System.Nullable[System.Boolean]] $InboundAllowed

    [DscProperty()]
    [System.ComponentModel.Description('Specifies whether you want to automatically trust Outbound invitations.')]
    [System.Nullable[System.Boolean]] $OutboundAllowed
}

class MSFT_AADCrossTenantIdentitySyncPolicyPartnerInbound
{
    [DscProperty()]
    [System.ComponentModel.Description('Defines whether groups can be synchronized from a partner tenant. Key.')]
    [MSFT_AADCrossTenantGroupSyncInbound] $GroupSyncInbound

    [DscProperty()]
    [System.ComponentModel.Description('Specifies whether you want to automatically trust Outbound invitations.')]
    [MSFT_AADCrossTenantUserSyncInbound] $UserSyncInbound
}

class MSFT_AADCrossTenantAccessPolicyInboundTrust
{
    [DscProperty()]
    [System.ComponentModel.Description('Specifies whether compliant devices from external Azure AD organizations are trusted.')]
    [System.Nullable[System.Boolean]] $IsCompliantDeviceAccepted

    [DscProperty()]
    [System.ComponentModel.Description('Specifies whether hybrid Azure AD joined devices from external Azure AD organizations are trusted.')]
    [System.Nullable[System.Boolean]] $IsHybridAzureADJoinedDeviceAccepted

    [DscProperty()]
    [System.ComponentModel.Description('Specifies whether MFA from external Azure AD organizations is trusted.')]
    [System.Nullable[System.Boolean]] $IsMfaAccepted
}

class MSFT_AADCrossTenantAccessPolicyTargetConfiguration
{
    [DscProperty()]
    [System.ComponentModel.Description('Defines whether access is allowed or blocked. The possible values are: allowed, blocked, unknownFutureValue.')]
    [ValidateSet('allowed', 'blocked', 'unknownFutureValue')]
    [System.String] $AccessType

    [DscProperty()]
    [System.ComponentModel.Description('Specifies whether to target users, groups, or applications with this rule.')]
    [MSFT_AADCrossTenantAccessPolicyTarget[]] $Targets
}

class MSFT_AADCrossTenantGroupSyncInbound
{
    [DscProperty()]
    [System.ComponentModel.Description('Defines whether group objects should be synchronized from the partner tenant. false stops any current group synchronization from the source tenant to the target tenant. This property has no impact on existing groups that were synchronized.')]
    [System.Nullable[System.Boolean]] $IsSyncAllowed
}

class MSFT_AADCrossTenantUserSyncInbound
{
    [DscProperty()]
    [System.ComponentModel.Description('Defines whether user objects should be synchronized from the partner tenant. false causes any current user synchronization from the source tenant to the target tenant to stop. This property has no impact on existing users who have already been synchronized.')]
    [System.Nullable[System.Boolean]] $IsSyncAllowed
}

class MSFT_AADCrossTenantAccessPolicyTarget
{
    [DscProperty(Mandatory)]
    [System.ComponentModel.Description('The unique identifier of the user, group, or application; one of the following keywords: AllUsers and AllApplications; or for targets that are applications, you may use reserved values.')]
    [System.String] $Target

    [DscProperty(Mandatory)]
    [System.ComponentModel.Description('The type of resource that you want to target. The possible values are: user, group, application, unknownFutureValue.')]
    [ValidateSet('user', 'group', 'application', 'unknownFutureValue')]
    [System.String] $TargetType
}

# Was Get-M365DSCAADCrossTenantAccessPolicyAutomaticUserConsentSettings. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Get-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCAADCrossTenantAccessPolicyAutomaticUserConsentSettings
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Setting
    )

    $result = @{
        InboundAllowed  = $Setting.InboundAllowed
        OutboundAllowed = $Setting.OutboundAllowed
    }

    return $result
}

# Was Test-M365DSCB2BIsDefault. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Test-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCB2BIsDefault
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $B2BSetting
    )

    if ($null -eq $B2BSetting.Applications.AccessType -and `
        $null -eq $B2BSetting.Applications.Target -and `
        $null -eq $B2BSetting.UsersAndGroups.AccessType -and `
        $null -eq $B2BSetting.UsersAndGroups.Target)
    {
        return $true
    }

    return $false
}

# Was Get-M365DSCAADCrossTenantAccessPolicyB2BSetting. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Get-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCAADCrossTenantAccessPolicyB2BSetting
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Setting
    )

    #region Applications
    $applications = @{
        AccessType = $Setting.applications.accessType
    }

    if ($null -ne $Setting.applications.targets)
    {
        $targets = @()
        foreach ($currentTarget in $Setting.applications.targets)
        {
            $targets += @{
                Target     = $currentTarget.target
                TargetType = $currentTarget.targetType
            }
        }
        $applications.Add('Targets', $targets)
    }
    #endregion

    #region UsersAndGroups
    $usersAndGroups = @{
        AccessType = $Setting.usersAndGroups.accessType
    }

    if ($null -ne $Setting.usersAndGroups.targets)
    {
        $targets = @()
        foreach ($currentTarget in $Setting.usersAndGroups.targets)
        {
            if ($currentTarget.targetType -eq 'User')
            {
                $user = Get-MgUser -UserId $currentTarget.target -ErrorAction SilentlyContinue
            }
            elseif ($currentTarget.targetType -eq 'Group')
            {
                $group = Get-MgGroup -GroupId $currentTarget.target -ErrorAction SilentlyContinue
            }

            $targetValue = $currentTarget.target
            if ($null -ne $user)
            {
                $targetValue = $user.UserPrincipalName
            }
            elseif ($null -ne $group)
            {
                $targetValue = $group.DisplayName
            }
            $targets += @{
                Target     = $targetValue
                TargetType = $currentTarget.targetType
            }
        }
        $usersAndGroups.Add('Targets', $targets)
    }
    #endregion
    $results = @{
        Applications   = $applications
        UsersAndGroups = $usersAndGroups
    }

    return $results
}

# Was Get-M365DSCAADCrossTenantAccessPolicyIdentitySynchronization. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Get-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCAADCrossTenantAccessPolicyIdentitySynchronization
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Setting
    )

    @{
        groupSyncInbound = @{
            isSyncAllowed = $Setting.GroupSyncInbound.IsSyncAllowed
        }
        userSyncInbound = @{
            isSyncAllowed = $Setting.UserSyncInbound.IsSyncAllowed
        }
    }
}

# Was Update-M365DSCSettingUserIdFromUPN. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Update-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCSettingUserIdFromUPN
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Setting
    )

    if ($null -ne $Setting.UsersAndGroups -and $null -ne $Setting.UsersAndGroups.Targets)
    {
        for ($i = 0; $i -le $Setting.UsersAndGroups.Targets.Length; $i++)
        {
            $user = $Setting.UsersAndGroups.Targets[$i]
            $userValue = $user.Target
            if ($null -ne $userValue)
            {
                if ($user.TargetType -eq 'User')
                {
                    Write-Verbose -Message "Detected User type with UPN {$($user.Target)}"
                    $user = Get-MgUser -UserId $user.Target -ErrorAction SilentlyContinue
                    if ($null -ne $user)
                    {
                        $userValue = $user.Id
                    }
                }
                elseif ($user.TargetType -eq 'Group')
                {
                    Write-Verbose -Message "Detected Group type with Name {$($user.Target)}"
                    $group = Get-MgGroup -Filter "DisplayName eq  '$($user.Target)'" -ErrorAction SilentlyContinue
                    if ($null -ne $group)
                    {
                        $userValue = $group.Id
                    }
                }
            }
            if ($null -ne $userValue)
            {
                Write-Verbose -Message "Updating principal to Id {$userValue}"
            }
            if ($null -ne $Setting.UsersAndGroups.Targets[$i].Target)
            {
                $Setting.UsersAndGroups.Targets[$i].Target = $userValue
            }
        }
    }
    return $Setting
}

# Was Get-M365DSCAADCrossTenantAccessPolicyInboundTrust. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Get-AADCrossTenantAccessPolicyConfigurationPartnerM365DSCAADCrossTenantAccessPolicyInboundTrust
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Setting
    )

    $result = @{
        IsCompliantDeviceAccepted           = $Setting.isCompliantDeviceAccepted
        IsHybridAzureADJoinedDeviceAccepted = $Setting.isHybridAzureADJoinedDeviceAccepted
        IsMfaAccepted                       = $Setting.isMfaAccepted
    }

    return $result
}

