# Editor-only: lets this file resolve [M365DSCResourceBase] when parsed on its own.
# Build-Microsoft365DSC.ps1 emits only the class extent, so this line is not shipped.
using module ..\_Base\M365DSCResourceBase.psm1

[DscResource()]
class IntuneDeviceConfigurationSCEPCertificatePolicyWindows10 : M365DSCResourceBase
{
    [DscProperty()]
    [System.ComponentModel.Description('Target store certificate. Possible values are: user, machine.')]
    [ValidateSet('user', 'machine')]
    [System.String] $CertificateStore

    [DscProperty()]
    [System.ComponentModel.Description('SCEP Hash Algorithm. Possible values are: sha1, sha2.')]
    [ValidateSet('sha1', 'sha2', 'sha1,sha2')]
    [System.String] $HashAlgorithm

    [DscProperty()]
    [System.ComponentModel.Description('SCEP Key Size. Possible values are: size1024, size2048, size4096.')]
    [ValidateSet('size1024', 'size2048', 'size4096')]
    [System.String] $KeySize

    [DscProperty()]
    [System.ComponentModel.Description('SCEP Key Usage. Possible values are: keyEncipherment, digitalSignature.')]
    [ValidateSet('keyEncipherment', 'digitalSignature')]
    [System.String[]] $KeyUsage

    [DscProperty()]
    [System.ComponentModel.Description('SCEP Server Url(s).')]
    [System.String[]] $ScepServerUrls

    [DscProperty()]
    [System.ComponentModel.Description('Custom String that defines the AAD Attribute.')]
    [System.String] $SubjectAlternativeNameFormatString

    [DscProperty()]
    [System.ComponentModel.Description('Custom format to use with SubjectNameFormat = Custom. Example: CN={{UserName}},E={{EmailAddress}},OU=Enterprise Users,O=Contoso Corporation,L=Redmond,ST=WA,C=US')]
    [System.String] $SubjectNameFormatString

    [DscProperty()]
    [System.ComponentModel.Description('Custom Subject Alternative Name Settings. This collection can contain a maximum of 500 elements.')]
    [MSFT_MicrosoftGraphcustomSubjectAlternativeName[]] $CustomSubjectAlternativeNames

    [DscProperty()]
    [System.ComponentModel.Description('Extended Key Usage (EKU) settings. This collection can contain a maximum of 500 elements.')]
    [MSFT_MicrosoftGraphextendedKeyUsage[]] $ExtendedKeyUsages

    [DscProperty()]
    [System.ComponentModel.Description('Scale for the Certificate Validity Period. Possible values are: days, months, years.')]
    [ValidateSet('days', 'months', 'years')]
    [System.String] $CertificateValidityPeriodScale

    [DscProperty()]
    [System.ComponentModel.Description('Value for the Certificate Validity Period')]
    [System.Nullable[System.UInt32]] $CertificateValidityPeriodValue

    [DscProperty()]
    [System.ComponentModel.Description('Key Storage Provider (KSP). Possible values are: useTpmKspOtherwiseUseSoftwareKsp, useTpmKspOtherwiseFail, usePassportForWorkKspOtherwiseFail, useSoftwareKsp.')]
    [ValidateSet('useTpmKspOtherwiseUseSoftwareKsp', 'useTpmKspOtherwiseFail', 'usePassportForWorkKspOtherwiseFail', 'useSoftwareKsp')]
    [System.String] $KeyStorageProvider

    [DscProperty()]
    [System.ComponentModel.Description('Certificate renewal threshold percentage. Valid values 1 to 99')]
    [System.Nullable[System.UInt32]] $RenewalThresholdPercentage

    [DscProperty()]
    [System.ComponentModel.Description('Certificate Subject Alternative Name Type. Possible values are: none, emailAddress, userPrincipalName, customAzureADAttribute, domainNameService, universalResourceIdentifier.')]
    [ValidateSet('none', 'emailAddress', 'userPrincipalName', 'customAzureADAttribute', 'domainNameService', 'universalResourceIdentifier')]
    [System.String] $SubjectAlternativeNameType

    [DscProperty()]
    [System.ComponentModel.Description('Certificate Subject Name Format. Possible values are: commonName, commonNameIncludingEmail, commonNameAsEmail, custom, commonNameAsIMEI, commonNameAsSerialNumber, commonNameAsAadDeviceId, commonNameAsIntuneDeviceId, commonNameAsDurableDeviceId.')]
    [ValidateSet('commonName', 'commonNameIncludingEmail', 'commonNameAsEmail', 'custom', 'commonNameAsIMEI', 'commonNameAsSerialNumber', 'commonNameAsAadDeviceId', 'commonNameAsIntuneDeviceId', 'commonNameAsDurableDeviceId')]
    [System.String] $SubjectNameFormat

    [DscProperty()]
    [System.ComponentModel.Description('Trusted Root Certificate DisplayName')]
    [System.String] $RootCertificateDisplayName

    [DscProperty()]
    [System.ComponentModel.Description('Trusted Root Certificate Id')]
    [System.String] $RootCertificateId

    [DscProperty()]
    [System.ComponentModel.Description('Admin provided description of the Device Configuration.')]
    [System.String] $Description

    [DscProperty(Key)]
    [System.ComponentModel.Description('Admin provided name of the device configuration.')]
    [System.String] $DisplayName

    [DscProperty()]
    [System.ComponentModel.Description('The unique identifier for an entity. Read-only.')]
    [System.String] $Id

    [DscProperty()]
    [System.ComponentModel.Description('List of Scope Tags for this Entity instance.')]
    [System.String[]] $RoleScopeTagIds

    [DscProperty()]
    [System.ComponentModel.Description('Represents the assignment to the Intune policy.')]
    [MSFT_DeviceManagementConfigurationPolicyAssignments[]] $Assignments

    [DscProperty()]
    [System.ComponentModel.Description('Present ensures the policy exists, absent ensures it is removed.')]
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

    [IntuneDeviceConfigurationSCEPCertificatePolicyWindows10] Get()
    {
        if ($this.RequiresPowerShellCore())
        {
            $remote = [IntuneDeviceConfigurationSCEPCertificatePolicyWindows10]::new()
            $remote.FromHashtable($this.InvokeInPowerShellCore('Get'))
            return $remote
        }

        Write-Verbose -Message "Getting configuration of the Intune Device Configuration Scep Certificate Policy for Windows10 with Id {$($this.Id)} and DisplayName {$($this.DisplayName)}"

        try
        {
            if (-not $this.ExportedInstance -or $this.ExportedInstance.DisplayName -ne $this.DisplayName)
            {
                $null = $this.Connect('MicrosoftGraph')

                #Ensure the proper dependencies are installed in the current environment.
                Confirm-M365DSCDependencies

                #region Telemetry
                $this.AddTelemetry('Get')
                #endregion

                $nullResult = $this.GetBoundParameters()
                $nullResult.Ensure = 'Absent'

                $getValue = $null
                #region resource generator code
                if (-not [string]::IsNullOrEmpty($this.Id))
                {
                    $getValue = Get-MgBetaDeviceManagementDeviceConfiguration -All -Filter "Id eq '$($this.Id)'" -ErrorAction SilentlyContinue
                }

                if ($null -eq $getValue)
                {
                    Write-Verbose -Message "Could not find an Intune Device Configuration Scep Certificate Policy for Windows10 with Id {$($this.Id)}"

                    if (-not [string]::IsNullOrEmpty($this.DisplayName))
                    {
                        $getValue = Get-MgBetaDeviceManagementDeviceConfiguration `
                            -All `
                            -Filter "DisplayName eq '$($this.DisplayName -replace "'", "''")' and isof('microsoft.graph.windows81SCEPCertificateProfile')" `
                            -ErrorAction SilentlyContinue
                    }
                }
                #endregion
                if ($null -eq $getValue)
                {
                    Write-Verbose -Message "Could not find an Intune Device Configuration Scep Certificate Policy for Windows10 with DisplayName {$($this.DisplayName)}"
                    return $this.AsResult($nullResult)
                }
            }
            else
            {
                $getValue = $this.ExportedInstance
            }
            $this.Id = $getValue.Id
            Write-Verbose -Message "An Intune Device Configuration Scep Certificate Policy for Windows10 with Id {$($this.Id)} and DisplayName {$($this.DisplayName)} was found."

            #region resource generator code
            $complexCustomSubjectAlternativeNames = @()
            foreach ($currentcustomSubjectAlternativeNames in $getValue.customSubjectAlternativeNames)
            {
                $mycustomSubjectAlternativeNames = [ordered]@{}
                $mycustomSubjectAlternativeNames.Add('Name', $currentcustomSubjectAlternativeNames.name)
                if ($null -ne $currentcustomSubjectAlternativeNames.sanType)
                {
                    $mycustomSubjectAlternativeNames.Add('SanType', $currentcustomSubjectAlternativeNames.sanType.ToString())
                }
                if ($mycustomSubjectAlternativeNames.values.Where({ $null -ne $_ }).Count -gt 0)
                {
                    $complexCustomSubjectAlternativeNames += $mycustomSubjectAlternativeNames
                }
            }

            $complexExtendedKeyUsages = @()
            foreach ($currentextendedKeyUsages in $getValue.extendedKeyUsages)
            {
                $myextendedKeyUsages = [ordered]@{}
                $myextendedKeyUsages.Add('Name', $currentextendedKeyUsages.name)
                $myextendedKeyUsages.Add('ObjectIdentifier', $currentextendedKeyUsages.objectIdentifier)
                if ($myextendedKeyUsages.values.Where({ $null -ne $_ }).Count -gt 0)
                {
                    $complexExtendedKeyUsages += $myextendedKeyUsages
                }
            }
            #endregion

            #region resource generator code
            $enumCertificateStore = $null
            if ($null -ne $getValue.certificateStore)
            {
                $enumCertificateStore = $getValue.certificateStore.ToString()
            }

            $enumHashAlgorithm = $null
            if ($null -ne $getValue.hashAlgorithm)
            {
                $enumHashAlgorithm = $getValue.hashAlgorithm.ToString()
            }

            $enumKeySize = $null
            if ($null -ne $getValue.keySize)
            {
                $enumKeySize = $getValue.keySize.ToString()
            }

            $enumKeyUsage = $null
            if ($null -ne $getValue.keyUsage)
            {
                $enumKeyUsage = $getValue.keyUsage.ToString()
            }

            $enumCertificateValidityPeriodScale = $null
            if ($null -ne $getValue.certificateValidityPeriodScale)
            {
                $enumCertificateValidityPeriodScale = $getValue.certificateValidityPeriodScale.ToString()
            }

            $enumKeyStorageProvider = $null
            if ($null -ne $getValue.keyStorageProvider)
            {
                $enumKeyStorageProvider = $getValue.keyStorageProvider.ToString()
            }

            $enumSubjectAlternativeNameType = $null
            if ($null -ne $getValue.subjectAlternativeNameType)
            {
                $enumSubjectAlternativeNameType = $getValue.subjectAlternativeNameType.ToString()
            }

            $enumSubjectNameFormat = $null
            if ($null -ne $getValue.subjectNameFormat)
            {
                $enumSubjectNameFormat = $getValue.subjectNameFormat.ToString()
            }
            #endregion

            $RootCertificate = Get-IntuneDeviceConfigurationSCEPCertificatePolicyWindows10DeviceConfigurationPolicyRootCertificate -DeviceConfigurationPolicyId $getValue.Id
            $this.RootCertificateId = $RootCertificate.Id
            $this.RootCertificateDisplayName = $RootCertificate.DisplayName

            $results = @{
                #region resource generator code
                CertificateStore                   = $enumCertificateStore
                HashAlgorithm                      = $enumHashAlgorithm
                KeySize                            = $enumKeySize
                KeyUsage                           = $enumKeyUsage.Split(',')
                ScepServerUrls                     = $getValue.scepServerUrls
                SubjectAlternativeNameFormatString = $getValue.subjectAlternativeNameFormatString
                SubjectNameFormatString            = $getValue.subjectNameFormatString
                CustomSubjectAlternativeNames      = $complexCustomSubjectAlternativeNames
                ExtendedKeyUsages                  = $complexExtendedKeyUsages
                CertificateValidityPeriodScale     = $enumCertificateValidityPeriodScale
                CertificateValidityPeriodValue     = $getValue.certificateValidityPeriodValue
                KeyStorageProvider                 = $enumKeyStorageProvider
                RenewalThresholdPercentage         = $getValue.renewalThresholdPercentage
                SubjectAlternativeNameType         = $enumSubjectAlternativeNameType
                SubjectNameFormat                  = $enumSubjectNameFormat
                RootCertificateId                  = $this.RootCertificateId
                RootCertificateDisplayName         = $this.RootCertificateDisplayName
                Description                        = $getValue.Description
                DisplayName                        = $getValue.DisplayName
                Id                                 = $getValue.Id
                RoleScopeTagIds                    = $getValue.RoleScopeTagIds
                Ensure                             = 'Present'
                Credential                         = $this.Credential
                ApplicationId                      = $this.ApplicationId
                TenantId                           = $this.TenantId
                ApplicationSecret                  = $this.ApplicationSecret
                CertificateThumbprint              = $this.CertificateThumbprint
                CertificatePath                    = $this.CertificatePath
                CertificatePassword                = $this.CertificatePassword
                ManagedIdentity                    = $this.ManagedIdentity.IsPresent
                AccessTokens                       = $this.AccessTokens
                #endregion
            }

            $assignmentsValues = Get-MgBetaDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $this.Id
            $assignmentResult = @()
            if ($assignmentsValues.Count -gt 0)
            {
                $assignmentResult += ConvertFrom-IntunePolicyAssignment `
                    -IncludeDeviceFilter:$true `
                    -Assignments ($assignmentsValues)
            }
            $results.Add('Assignments', $assignmentResult)

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
        $BoundParameters = Remove-M365DSCAuthenticationParameter -BoundParameters $this.GetBoundParameters()

        if ($this.Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Absent')
        {
            Write-Verbose -Message "Creating an Intune Device Configuration Scep Certificate Policy for Windows10 with DisplayName {$($this.DisplayName)}"
            $BoundParameters.Remove('Assignments') | Out-Null
            $BoundParameters.Remove('RootCertificateId') | Out-Null

            $CreateParameters = ([Hashtable]$BoundParameters).Clone()
            $CreateParameters = Rename-M365DSCCimInstanceParameter -Properties $CreateParameters
            $CreateParameters.Remove('Id') | Out-Null
            $CreateParameters['keyUsage'] = $CreateParameters['keyUsage'] -join ','

            $RootCertificate = Get-MgBetaDeviceManagementDeviceConfiguration `
                -DeviceConfigurationId $this.RootCertificateId `
                -ErrorAction SilentlyContinue

            if ($null -eq $RootCertificate)
            {
                Write-Verbose -Message "Could not find trusted root certificate with Id {$($this.RootCertificateId)}, searching by display name {$($this.RootCertificateDisplayName)}"

                $RootCertificate = Get-MgBetaDeviceManagementDeviceConfiguration `
                    -Filter "DisplayName eq '$($this.RootCertificateDisplayName -replace "'", "''")' and isof('microsoft.graph.windows81TrustedRootCertificate')" `
                    -ErrorAction SilentlyContinue
                $this.RootCertificateId = $RootCertificate.Id

                if ($null -eq $RootCertificate)
                {
                    throw "Could not find trusted root certificate with Id {$($this.RootCertificateId)} or display name {$($this.RootCertificateDisplayName)}"
                }

                Write-Verbose -Message "Found trusted root certificate with Id {$($RootCertificate.Id)} and DisplayName {$($RootCertificate.DisplayName)}"
            }
            else
            {
                Write-Verbose -Message "Found trusted root certificate with Id {$($this.RootCertificateId)}"
            }

            #region resource generator code
            $CreateParameters.Add('rootCertificate@odata.bind', "$((Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl)beta/deviceManagement/deviceConfigurations('$($this.RootCertificateId)')")
            $CreateParameters.Add('@odata.type', '#microsoft.graph.windows81SCEPCertificateProfile')
            $policy = New-MgBetaDeviceManagementDeviceConfiguration -BodyParameter $CreateParameters
            $assignmentsHash = ConvertTo-IntunePolicyAssignment -IncludeDeviceFilter:$true -Assignments $this.Assignments

            if ($policy.id)
            {
                Update-DeviceConfigurationPolicyAssignment -DeviceConfigurationPolicyId $policy.id `
                    -Targets $assignmentsHash `
                    -Repository 'deviceManagement/deviceConfigurations'
            }
            #endregion
        }
        elseif ($this.Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Present')
        {
            Write-Verbose -Message "Updating the Intune Device Configuration Scep Certificate Policy for Windows10 with Id {$($currentInstance.Id)}"
            $BoundParameters.Remove('Assignments') | Out-Null
            $BoundParameters.Remove('RootCertificateId') | Out-Null
            $BoundParameters.Remove('RootCertificateDisplayName') | Out-Null

            $UpdateParameters = ([Hashtable]$BoundParameters).Clone()
            $UpdateParameters = Rename-M365DSCCimInstanceParameter -Properties $UpdateParameters

            $UpdateParameters.Remove('Id') | Out-Null
            $UpdateParameters['keyUsage'] = $UpdateParameters['keyUsage'] -join ','

            #region resource generator code
            $UpdateParameters.Add('@odata.type', '#microsoft.graph.windows81SCEPCertificateProfile')
            Update-MgBetaDeviceManagementDeviceConfiguration `
                -DeviceConfigurationId $currentInstance.Id `
                -BodyParameter $UpdateParameters
            $assignmentsHash = ConvertTo-IntunePolicyAssignment -IncludeDeviceFilter:$true -Assignments $this.Assignments
            Update-DeviceConfigurationPolicyAssignment `
                -DeviceConfigurationPolicyId $currentInstance.id `
                -Targets $assignmentsHash `
                -Repository 'deviceManagement/deviceConfigurations'
            #endregion

            $RootCertificate = Get-MgBetaDeviceManagementDeviceConfiguration `
                -DeviceConfigurationId $this.RootCertificateId `
                -ErrorAction SilentlyContinue | `
                    Where-Object -FilterScript {
                    $_.'@odata.type' -eq '#microsoft.graph.windows81TrustedRootCertificate'
                }

            if ($null -eq $RootCertificate)
            {
                Write-Verbose -Message "Could not find trusted root certificate with Id {$($this.RootCertificateId)}, searching by display name {$($this.RootCertificateDisplayName)}"

                $RootCertificate = Get-MgBetaDeviceManagementDeviceConfiguration `
                    -Filter "DisplayName eq '$($this.RootCertificateDisplayName -replace "'", "''")'" `
                    -ErrorAction SilentlyContinue | `
                        Where-Object -FilterScript {
                        $_.'@odata.type' -eq '#microsoft.graph.windows81TrustedRootCertificate'
                    }
                $this.RootCertificateId = $RootCertificate.Id

                if ($null -eq $RootCertificate)
                {
                    throw "Could not find trusted root certificate with Id {$($this.RootCertificateId)} or display name {$($this.RootCertificateDisplayName)}"
                }

                Write-Verbose -Message "Found trusted root certificate with Id {$($RootCertificate.Id)} and DisplayName {$($RootCertificate.DisplayName)}"
            }
            else
            {
                Write-Verbose -Message "Found trusted root certificate with Id {$($this.RootCertificateId)}"
            }

            Update-IntuneDeviceConfigurationSCEPCertificatePolicyWindows10DeviceConfigurationPolicyRootCertificateId `
                -DeviceConfigurationPolicyId $currentInstance.id `
                -RootCertificateId $this.RootCertificateId
        }
        elseif ($this.Ensure -eq 'Absent' -and $currentInstance.Ensure -eq 'Present')
        {
            Write-Verbose -Message "Removing the Intune Device Configuration Scep Certificate Policy for Windows10 with Id {$($currentInstance.Id)}"
            #region resource generator code
            Remove-MgBetaDeviceManagementDeviceConfiguration -DeviceConfigurationId $currentInstance.Id
            #endregion
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

        $excludedProperties = @()
        if (-not [System.String]::IsNullOrEmpty($this.RootCertificateDisplayName))
        {
            $excludedProperties += 'RootCertificateId'
        }

        $result = Test-M365DSCTargetResource -DesiredValues $this.GetBoundParameters() `
            -ResourceName $this.GetResourceName() `
            -ExcludedProperties $excludedProperties `
            -CurrentValues $this.Get().ToHashtable()
        return $result
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
            #region resource generator code
            $baseFilter = "isof('microsoft.graph.windows81SCEPCertificateProfile')"
            if (-not [string]::IsNullOrEmpty($this.Filter))
            {
                $this.Filter = "($baseFilter) and ($($this.Filter))"
            }
            else
            {
                $this.Filter = $baseFilter
            }
            [array]$getValue = Get-MgBetaDeviceManagementDeviceConfiguration -Filter $this.Filter -All -ErrorAction Stop
            #endregion

            $i = 1
            $dscContent = [System.Text.StringBuilder]::new()
            if ($getValue.Length -eq 0)
            {
                Write-M365DSCHost -Message $Global:M365DSCEmojiGreenCheckMark -CommitWrite
            }
            else
            {
                Write-M365DSCHost -Message "`r`n" -DeferWrite
            }
            foreach ($config in $getValue)
            {
                if ($null -ne $Global:M365DSCExportResourceInstancesCount)
                {
                    $Global:M365DSCExportResourceInstancesCount++
                }

                $displayedKey = $config.Id
                if (-not [String]::IsNullOrEmpty($config.displayName))
                {
                    $displayedKey = $config.displayName
                }
                Write-M365DSCHost -Message "    |---[$i/$($getValue.Count)] $displayedKey" -DeferWrite
                $params = @{
                    Id                    = $config.Id
                    DisplayName           = $config.DisplayName
                    Ensure                = 'Present'
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
                $rawResults = $Results.Clone()

                if ($null -ne $Results.CustomSubjectAlternativeNames)
                {
                    $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                        -ComplexObject $Results.CustomSubjectAlternativeNames `
                        -CIMInstanceName 'MicrosoftGraphcustomSubjectAlternativeName'
                    if (-not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                    {
                        $Results.CustomSubjectAlternativeNames = $complexTypeStringResult
                    }
                    else
                    {
                        $Results.Remove('CustomSubjectAlternativeNames') | Out-Null
                    }
                }
                if ($null -ne $Results.ExtendedKeyUsages)
                {
                    $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                        -ComplexObject $Results.ExtendedKeyUsages `
                        -CIMInstanceName 'MicrosoftGraphextendedKeyUsage'
                    if (-not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                    {
                        $Results.ExtendedKeyUsages = $complexTypeStringResult
                    }
                    else
                    {
                        $Results.Remove('ExtendedKeyUsages') | Out-Null
                    }
                }
                if ($Results.Assignments)
                {
                    $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString -ComplexObject $Results.Assignments -CIMInstanceName DeviceManagementConfigurationPolicyAssignments
                    if ($complexTypeStringResult)
                    {
                        $Results.Assignments = $complexTypeStringResult
                    }
                    else
                    {
                        $Results.Remove('Assignments') | Out-Null
                    }
                }
                $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $this.GetResourceName() `
                    -ConnectionMode $ConnectionMode `
                    -ModulePath $this.GetModulePath() `
                    -Results $Results `
                    -Credential $this.Credential `
                    -NoEscape @('CustomSubjectAlternativeNames', 'ExtendedKeyUsages', 'Assignments') `
                    -RawResults $rawResults

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
            if ($_.Exception -like '*401*' -or $_.ErrorDetails.Message -like "*`"ErrorCode`":`"Forbidden`"*" -or `
                    $_.Exception -like '*Request not applicable to target tenant*')
            {
                Write-M365DSCHost -Message "`r`n    $($Global:M365DSCEmojiYellowCircle) The current tenant is not registered for Intune."
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
    hidden [IntuneDeviceConfigurationSCEPCertificatePolicyWindows10] AsResult([System.Object] $Values)
    {
        if ($Values -is [IntuneDeviceConfigurationSCEPCertificatePolicyWindows10])
        {
            return $Values
        }

        $result = [IntuneDeviceConfigurationSCEPCertificatePolicyWindows10]::new()
        if ($Values -is [System.Collections.Hashtable])
        {
            $result.FromHashtable($Values)
        }

        return $result
    }
}

class MSFT_MicrosoftGraphcustomSubjectAlternativeName
{
    [DscProperty(Mandatory)]
    [System.ComponentModel.Description('Custom SAN Name')]
    [System.String] $Name
    [DscProperty(Mandatory)]
    [System.ComponentModel.Description('Custom SAN Type. Possible values are: none, emailAddress, userPrincipalName, customAzureADAttribute, domainNameService, universalResourceIdentifier.')]
    [System.String] $SanType
}

class MSFT_MicrosoftGraphextendedKeyUsage
{
    [DscProperty(Mandatory)]
    [System.ComponentModel.Description('Extended Key Usage Name')]
    [System.String] $Name
    [DscProperty(Mandatory)]
    [System.ComponentModel.Description('Extended Key Usage Object Identifier')]
    [System.String] $ObjectIdentifier
}

class MSFT_DeviceManagementConfigurationPolicyAssignments
{
    [DscProperty(Mandatory)]
    [System.ComponentModel.Description('The type of the target assignment.')]
    [System.String] $dataType
    [DscProperty()]
    [System.ComponentModel.Description('The type of filter of the target assignment i.e. Exclude or Include. Possible values are:none, include, exclude.')]
    [System.String] $deviceAndAppManagementAssignmentFilterType
    [DscProperty()]
    [System.ComponentModel.Description('The Id of the filter for the target assignment.')]
    [System.String] $deviceAndAppManagementAssignmentFilterId
    [DscProperty()]
    [System.ComponentModel.Description('The display name of the filter for the target assignment.')]
    [System.String] $deviceAndAppManagementAssignmentFilterDisplayName
    [DscProperty()]
    [System.ComponentModel.Description('The group Id that is the target of the assignment.')]
    [System.String] $groupId
    [DscProperty()]
    [System.ComponentModel.Description('The group Display Name that is the target of the assignment.')]
    [System.String] $groupDisplayName
    [DscProperty()]
    [System.ComponentModel.Description('The collection Id that is the target of the assignment.(ConfigMgr)')]
    [System.String] $collectionId
}

# Was Update-DeviceConfigurationPolicyRootCertificateId. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Update-IntuneDeviceConfigurationSCEPCertificatePolicyWindows10DeviceConfigurationPolicyRootCertificateId
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = 'true')]
        [System.String]
        $DeviceConfigurationPolicyId,

        [Parameter(Mandatory = 'true')]
        [System.String]
        $RootCertificateId
    )

    $Uri = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + "beta/deviceManagement/deviceConfigurations('$DeviceConfigurationPolicyId')/microsoft.graph.windows81SCEPCertificateProfile/rootCertificate/`$ref"
    $ref = @{
        '@odata.id' = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + "beta/deviceManagement/deviceConfigurations('$RootCertificateId')"
    }

    Invoke-MgGraphRequest -Method PUT -Uri $Uri -Body ($ref | ConvertTo-Json) -ErrorAction Stop
}

# Was Get-DeviceConfigurationPolicyRootCertificate. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Get-IntuneDeviceConfigurationSCEPCertificatePolicyWindows10DeviceConfigurationPolicyRootCertificate
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = 'true')]
        [System.String]
        $DeviceConfigurationPolicyId
    )
    $Uri = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + "beta/deviceManagement/deviceConfigurations('$DeviceConfigurationPolicyId')/microsoft.graph.windows81SCEPCertificateProfile/rootCertificate"
    $result = Invoke-MgGraphRequest -Method Get -Uri $Uri -ErrorAction Stop

    return $result
}

