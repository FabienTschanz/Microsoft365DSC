# Editor-only: lets this file resolve [M365DSCResourceBase] when parsed on its own.
# Build-Microsoft365DSC.ps1 emits only the class extent, so this line is not shipped.
using module ..\_Base\M365DSCResourceBase.psm1

[DscResource()]
class IntuneDeviceConfigurationWiredNetworkPolicyWindows10 : M365DSCResourceBase
{
    [DscProperty()]
    [System.ComponentModel.Description('Specify the duration for which automatic authentication attempts will be blocked from occurring after a failed authentication attempt.')]
    [System.Nullable[System.UInt32]] $AuthenticationBlockPeriodInMinutes

    [DscProperty()]
    [System.ComponentModel.Description('Specify the authentication method. Possible values are: certificate, usernameAndPassword, derivedCredential. Possible values are: certificate, usernameAndPassword, derivedCredential, unknownFutureValue.')]
    [ValidateSet('certificate', 'usernameAndPassword', 'derivedCredential', 'unknownFutureValue')]
    [System.String] $AuthenticationMethod

    [DscProperty()]
    [System.ComponentModel.Description('Specify the number of seconds for the client to wait after an authentication attempt before failing. Valid range 1-3600.')]
    [System.Nullable[System.UInt32]] $AuthenticationPeriodInSeconds

    [DscProperty()]
    [System.ComponentModel.Description('Specify the number of seconds between a failed authentication and the next authentication attempt. Valid range 1-3600.')]
    [System.Nullable[System.UInt32]] $AuthenticationRetryDelayPeriodInSeconds

    [DscProperty()]
    [System.ComponentModel.Description('Specify whether to authenticate the user, the device, either, or to use guest authentication (none). If you''re using certificate authentication, make sure the certificate type matches the authentication type. Possible values are: none, user, machine, machineOrUser, guest. Possible values are: none, user, machine, machineOrUser, guest, unknownFutureValue.')]
    [ValidateSet('none', 'user', 'machine', 'machineOrUser', 'guest', 'unknownFutureValue')]
    [System.String] $AuthenticationType

    [DscProperty()]
    [System.ComponentModel.Description('When TRUE, caches user credentials on the device so that users don''t need to keep entering them each time they connect. When FALSE, do not cache credentials. Default value is FALSE.')]
    [System.Nullable[System.Boolean]] $CacheCredentials

    [DscProperty()]
    [System.ComponentModel.Description('When TRUE, prevents the user from being prompted to authorize new servers for trusted certification authorities when EAP type is selected as PEAP. When FALSE, does not prevent the user from being prompted. Default value is FALSE.')]
    [System.Nullable[System.Boolean]] $DisableUserPromptForServerValidation

    [DscProperty()]
    [System.ComponentModel.Description('Specify the number of seconds to wait before sending an EAPOL (Extensible Authentication Protocol over LAN) Start message. Valid range 1-3600.')]
    [System.Nullable[System.UInt32]] $EapolStartPeriodInSeconds

    [DscProperty()]
    [System.ComponentModel.Description('Extensible Authentication Protocol (EAP). Indicates the type of EAP protocol set on the Wi-Fi endpoint (router). Possible values are: eapTls, leap, eapSim, eapTtls, peap, eapFast, teap. Possible values are: eapTls, leap, eapSim, eapTtls, peap, eapFast, teap.')]
    [ValidateSet('eapTls', 'leap', 'eapSim', 'eapTtls', 'peap', 'eapFast', 'teap')]
    [System.String] $EapType

    [DscProperty()]
    [System.ComponentModel.Description('When TRUE, the automatic configuration service for wired networks requires the use of 802.1X for port authentication. When FALSE, 802.1X is not required. Default value is FALSE.')]
    [System.Nullable[System.Boolean]] $Enforce8021X

    [DscProperty()]
    [System.ComponentModel.Description('When TRUE, forces FIPS compliance. When FALSE, does not enable FIPS compliance. Default value is FALSE.')]
    [System.Nullable[System.Boolean]] $ForceFIPSCompliance

    [DscProperty()]
    [System.ComponentModel.Description('Specify inner authentication protocol for EAP TTLS. Possible values are: unencryptedPassword, challengeHandshakeAuthenticationProtocol, microsoftChap, microsoftChapVersionTwo. Possible values are: unencryptedPassword, challengeHandshakeAuthenticationProtocol, microsoftChap, microsoftChapVersionTwo.')]
    [ValidateSet('unencryptedPassword', 'challengeHandshakeAuthenticationProtocol', 'microsoftChap', 'microsoftChapVersionTwo')]
    [System.String] $InnerAuthenticationProtocolForEAPTTLS

    [DscProperty()]
    [System.ComponentModel.Description('Specify the maximum authentication failures allowed for a set of credentials. Valid range 1-100.')]
    [System.Nullable[System.UInt32]] $MaximumAuthenticationFailures

    [DscProperty()]
    [System.ComponentModel.Description('Specify the maximum number of EAPOL (Extensible Authentication Protocol over LAN) Start messages to be sent before returning failure. Valid range 1-100.')]
    [System.Nullable[System.UInt32]] $MaximumEAPOLStartMessages

    [DscProperty()]
    [System.ComponentModel.Description('Specify the string to replace usernames for privacy when using EAP TTLS or PEAP.')]
    [System.String] $OuterIdentityPrivacyTemporaryValue

    [DscProperty()]
    [System.ComponentModel.Description('When TRUE, enables verification of server''s identity by validating the certificate when EAP type is selected as PEAP. When FALSE, the certificate is not validated. Default value is TRUE.')]
    [System.Nullable[System.Boolean]] $PerformServerValidation

    [DscProperty()]
    [System.ComponentModel.Description('When TRUE, enables cryptographic binding when EAP type is selected as PEAP. When FALSE, does not enable cryptogrpahic binding. Default value is TRUE.')]
    [System.Nullable[System.Boolean]] $RequireCryptographicBinding

    [DscProperty()]
    [System.ComponentModel.Description('Specify the secondary authentication method. Possible values are: certificate, usernameAndPassword, derivedCredential. Possible values are: certificate, usernameAndPassword, derivedCredential, unknownFutureValue.')]
    [ValidateSet('certificate', 'usernameAndPassword', 'derivedCredential', 'unknownFutureValue')]
    [System.String] $SecondaryAuthenticationMethod

    [DscProperty()]
    [System.ComponentModel.Description('Specify trusted server certificate names.')]
    [System.String[]] $TrustedServerCertificateNames

    [DscProperty()]
    [System.ComponentModel.Description('Specify root certificates for server validation. This collection can contain a maximum of 500 elements.')]
    [System.String[]] $RootCertificatesForServerValidationIds

    [DscProperty()]
    [System.ComponentModel.Description('Specify root certificate display names for server validation. This collection can contain a maximum of 500 elements.')]
    [System.String[]] $RootCertificatesForServerValidationDisplayNames

    [DscProperty()]
    [System.ComponentModel.Description('Specify identity certificate for client authentication.')]
    [System.String] $IdentityCertificateForClientAuthenticationId

    [DscProperty()]
    [System.ComponentModel.Description('Specify identity certificate display name for client authentication.')]
    [System.String] $IdentityCertificateForClientAuthenticationDisplayName

    [DscProperty()]
    [System.ComponentModel.Description('Specify root certificate for client validation')]
    [System.String] $SecondaryIdentityCertificateForClientAuthenticationId

    [DscProperty()]
    [System.ComponentModel.Description('Specify root certificate display name for client validation')]
    [System.String] $SecondaryIdentityCertificateForClientAuthenticationDisplayName

    [DscProperty()]
    [System.ComponentModel.Description('Specify root certificate for client validation.')]
    [System.String] $RootCertificateForClientValidationId

    [DscProperty()]
    [System.ComponentModel.Description('Specify root certificate display name for client validation.')]
    [System.String] $RootCertificateForClientValidationDisplayName

    [DscProperty()]
    [System.ComponentModel.Description('Specify secondary root certificate for client validation.')]
    [System.String] $SecondaryRootCertificateForClientValidationId

    [DscProperty()]
    [System.ComponentModel.Description('Specify secondary root certificate display name for client validation.')]
    [System.String] $SecondaryRootCertificateForClientValidationDisplayName

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

    [IntuneDeviceConfigurationWiredNetworkPolicyWindows10] Get()
    {
        if ($this.RequiresPowerShellCore())
        {
            $remote = [IntuneDeviceConfigurationWiredNetworkPolicyWindows10]::new()
            $remote.FromHashtable($this.InvokeInPowerShellCore('Get'))
            return $remote
        }

        Write-Verbose -Message "Getting configuration of the Intune Device Configuration Wired Network Policy for Windows10 with Id {$($this.Id)} and DisplayName {$($this.DisplayName)}"

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
                    Write-Verbose -Message "Could not find an Intune Device Configuration Wired Network Policy for Windows10 with Id {$($this.Id)}"

                    if (-not [string]::IsNullOrEmpty($this.DisplayName))
                    {
                        $getValue = Get-MgBetaDeviceManagementDeviceConfiguration `
                            -All `
                            -Filter "DisplayName eq '$($this.DisplayName -replace "'", "''")' and isof('microsoft.graph.windowsWiredNetworkConfiguration')" `
                            -ErrorAction SilentlyContinue
                    }
                }
                #endregion
                if ($null -eq $getValue)
                {
                    Write-Verbose -Message "Could not find an Intune Device Configuration Wired Network Policy for Windows10 with DisplayName {$($this.DisplayName)}"
                    return $this.AsResult($nullResult)
                }
            }
            else
            {
                $getValue = $this.ExportedInstance
            }
            $this.Id = $getValue.Id
            Write-Verbose -Message "An Intune Device Configuration Wired Network Policy for Windows10 with Id {$($this.Id)} and DisplayName {$($this.DisplayName)} was found."

            #region resource generator code
            $enumAuthenticationMethod = $null
            if ($null -ne $getValue.authenticationMethod)
            {
                $enumAuthenticationMethod = $getValue.authenticationMethod.ToString()
            }

            $enumAuthenticationType = $null
            if ($null -ne $getValue.authenticationType)
            {
                $enumAuthenticationType = $getValue.authenticationType.ToString()
            }

            $enumEapType = $null
            if ($null -ne $getValue.eapType)
            {
                $enumEapType = $getValue.eapType.ToString()
            }

            $enumInnerAuthenticationProtocolForEAPTTLS = $null
            if ($null -ne $getValue.innerAuthenticationProtocolForEAPTTLS)
            {
                $enumInnerAuthenticationProtocolForEAPTTLS = $getValue.innerAuthenticationProtocolForEAPTTLS.ToString()
            }

            $enumSecondaryAuthenticationMethod = $null
            if ($null -ne $getValue.secondaryAuthenticationMethod)
            {
                $enumSecondaryAuthenticationMethod = $getValue.secondaryAuthenticationMethod.ToString()
            }
            #endregion

            $rootCertificateForClientValidation = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificate -DeviceConfigurationPolicyId $getValue.Id -CertificateName rootCertificateForClientValidation
            $rootCertificatesForServerValidation = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificate -DeviceConfigurationPolicyId $getValue.Id -CertificateName rootCertificatesForServerValidation
            $identityCertificateForClientAuthentication = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificate -DeviceConfigurationPolicyId $getValue.Id -CertificateName identityCertificateForClientAuthentication
            $secondaryIdentityCertificateForClientAuthentication = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificate -DeviceConfigurationPolicyId $getValue.Id -CertificateName secondaryIdentityCertificateForClientAuthentication
            $secondaryRootCertificateForClientValidation = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificate -DeviceConfigurationPolicyId $getValue.Id -CertificateName secondaryRootCertificateForClientValidation

            $results = @{
                #region resource generator code
                AuthenticationBlockPeriodInMinutes                             = $getValue.authenticationBlockPeriodInMinutes
                AuthenticationMethod                                           = $enumAuthenticationMethod
                AuthenticationPeriodInSeconds                                  = $getValue.authenticationPeriodInSeconds
                AuthenticationRetryDelayPeriodInSeconds                        = $getValue.authenticationRetryDelayPeriodInSeconds
                AuthenticationType                                             = $enumAuthenticationType
                CacheCredentials                                               = $getValue.cacheCredentials
                DisableUserPromptForServerValidation                           = $getValue.disableUserPromptForServerValidation
                EapolStartPeriodInSeconds                                      = $getValue.eapolStartPeriodInSeconds
                EapType                                                        = $enumEapType
                Enforce8021X                                                   = $getValue.enforce8021X
                ForceFIPSCompliance                                            = $getValue.forceFIPSCompliance
                InnerAuthenticationProtocolForEAPTTLS                          = $enumInnerAuthenticationProtocolForEAPTTLS
                MaximumAuthenticationFailures                                  = $getValue.maximumAuthenticationFailures
                MaximumEAPOLStartMessages                                      = $getValue.maximumEAPOLStartMessages
                OuterIdentityPrivacyTemporaryValue                             = $getValue.outerIdentityPrivacyTemporaryValue
                PerformServerValidation                                        = $getValue.performServerValidation
                RequireCryptographicBinding                                    = $getValue.requireCryptographicBinding
                SecondaryAuthenticationMethod                                  = $enumSecondaryAuthenticationMethod
                TrustedServerCertificateNames                                  = $getValue.trustedServerCertificateNames
                RootCertificatesForServerValidationIds                         = Get-M365DSCArrayFromProperty -PropertyValue $rootCertificatesForServerValidation.Id -ElementType ([System.String])
                RootCertificatesForServerValidationDisplayNames                = Get-M365DSCArrayFromProperty -PropertyValue $rootCertificatesForServerValidation.DisplayName -ElementType ([System.String])
                IdentityCertificateForClientAuthenticationId                   = $identityCertificateForClientAuthentication.Id
                IdentityCertificateForClientAuthenticationDisplayName          = $identityCertificateForClientAuthentication.DisplayName
                SecondaryIdentityCertificateForClientAuthenticationId          = $secondaryIdentityCertificateForClientAuthentication.Id
                SecondaryIdentityCertificateForClientAuthenticationDisplayName = $secondaryIdentityCertificateForClientAuthentication.DisplayName
                RootCertificateForClientValidationId                           = $rootCertificateForClientValidation.Id
                RootCertificateForClientValidationDisplayName                  = $rootCertificateForClientValidation.DisplayName
                SecondaryRootCertificateForClientValidationId                  = $secondaryRootCertificateForClientValidation.Id
                SecondaryRootCertificateForClientValidationDisplayName         = $secondaryRootCertificateForClientValidation.DisplayName
                Description                                                    = $getValue.Description
                DisplayName                                                    = $getValue.DisplayName
                Id                                                             = $getValue.Id
                RoleScopeTagIds                                                = $getValue.RoleScopeTagIds
                Ensure                                                         = 'Present'
                Credential                                                     = $this.Credential
                ApplicationId                                                  = $this.ApplicationId
                TenantId                                                       = $this.TenantId
                ApplicationSecret                                              = $this.ApplicationSecret
                CertificateThumbprint                                          = $this.CertificateThumbprint
                CertificatePath                                                = $this.CertificatePath
                CertificatePassword                                            = $this.CertificatePassword
                ManagedIdentity                                                = $this.ManagedIdentity.IsPresent
                AccessTokens                                                   = $this.AccessTokens
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
            Write-Verbose -Message "Creating an Intune Device Configuration Wired Network Policy for Windows10 with DisplayName {$($this.DisplayName)}"
            $BoundParameters.Remove('Assignments') | Out-Null
            $BoundParameters.Remove('RootCertificatesForServerValidationIds') | Out-Null
            $BoundParameters.Remove('RootCertificatesForServerValidationDisplayNames') | Out-Null
            $BoundParameters.Remove('IdentityCertificateForClientAuthenticationId') | Out-Null
            $BoundParameters.Remove('IdentityCertificateForClientAuthenticationDisplayName') | Out-Null
            $BoundParameters.Remove('SecondaryIdentityCertificateForClientAuthenticationId') | Out-Null
            $BoundParameters.Remove('SecondaryIdentityCertificateForClientAuthenticationDisplayName') | Out-Null
            $BoundParameters.Remove('RootCertificateForClientValidationId') | Out-Null
            $BoundParameters.Remove('RootCertificateForClientValidationDisplayName') | Out-Null
            $BoundParameters.Remove('SecondaryRootCertificateForClientValidationId') | Out-Null
            $BoundParameters.Remove('SecondaryRootCertificateForClientValidationDisplayName') | Out-Null

            $CreateParameters = ([Hashtable]$BoundParameters).Clone()
            $createParameters = Rename-M365DSCCimInstanceParameter -Properties $createParameters
            $createParameters.Remove('Id') | Out-Null

            #region resource generator code

            if ($null -ne $this.RootCertificatesForServerValidationIds -and $this.RootCertificatesForServerValidationIds.Count -gt 0 )
            {
                $rootCertificatesForServerValidation = @()
                for ($i = 0; $i -lt $this.RootCertificatesForServerValidationIds.Length; $i++)
                {
                    $checkedCertId = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10IntuneDeviceConfigurationCertificateId `
                        -CertificateId $this.RootCertificatesForServerValidationIds[$i] `
                        -CertificateDisplayName $this.RootCertificatesForServerValidationDisplayNames[$i] `
                        -OdataTypes @('#microsoft.graph.windows81TrustedRootCertificate')
                    $rootCertificatesForServerValidation += "$((Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl)beta/deviceManagement/deviceConfigurations('$checkedCertId')"
                }
                $CreateParameters.Add('rootCertificatesForServerValidation@odata.bind', $rootCertificatesForServerValidation)
            }

            if (-not [String]::IsNullOrWhiteSpace($this.IdentityCertificateForClientAuthenticationId))
            {
                $checkedCertId = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10IntuneDeviceConfigurationCertificateId `
                    -CertificateId $this.IdentityCertificateForClientAuthenticationId `
                    -CertificateDisplayName $this.IdentityCertificateForClientAuthenticationDisplayName `
                    -OdataTypes @( `
                        '#microsoft.graph.windows81SCEPCertificateProfile', `
                        '#microsoft.graph.windows81TrustedRootCertificate', `
                        '#microsoft.graph.windows10PkcsCertificateProfile' `
                )
                $ref = "$((Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl)beta/deviceManagement/deviceConfigurations('$checkedCertId')"
                $CreateParameters.Add('identityCertificateForClientAuthentication@odata.bind', $ref)
            }

            if (-not [String]::IsNullOrWhiteSpace($this.SecondaryIdentityCertificateForClientAuthenticationId))
            {
                $checkedCertId = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10IntuneDeviceConfigurationCertificateId `
                    -CertificateId $this.SecondaryIdentityCertificateForClientAuthenticationId `
                    -CertificateDisplayName $this.SecondaryIdentityCertificateForClientAuthenticationDisplayName `
                    -OdataTypes @( `
                        '#microsoft.graph.windows81SCEPCertificateProfile', `
                        '#microsoft.graph.windows81TrustedRootCertificate', `
                        '#microsoft.graph.windows10PkcsCertificateProfile' `
                )
                $ref = "$((Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl)beta/deviceManagement/deviceConfigurations('$checkedCertId')"
                $CreateParameters.Add('secondaryIdentityCertificateForClientAuthentication@odata.bind', $ref)
            }

            if (-not [String]::IsNullOrWhiteSpace($this.RootCertificateForClientValidationId))
            {
                $checkedCertId = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10IntuneDeviceConfigurationCertificateId `
                    -CertificateId $this.RootCertificateForClientValidationId `
                    -CertificateDisplayName $this.RootCertificateForClientValidationDisplayName `
                    -OdataTypes @('#microsoft.graph.windows81TrustedRootCertificate')
                $ref = "$((Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl)beta/deviceManagement/deviceConfigurations('$checkedCertId')"
                $CreateParameters.Add('rootCertificateForClientValidation@odata.bind', $ref)
            }

            if (-not [String]::IsNullOrWhiteSpace($this.SecondaryRootCertificateForClientValidationId))
            {
                $checkedCertId = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10IntuneDeviceConfigurationCertificateId `
                    -CertificateId $this.SecondaryRootCertificateForClientValidationId `
                    -CertificateDisplayName $this.SecondaryRootCertificateForClientValidationDisplayName `
                    -OdataTypes @('#microsoft.graph.windows81TrustedRootCertificate')
                $ref = "$((Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl)beta/deviceManagement/deviceConfigurations('$checkedCertId')"
                $CreateParameters.Add('secondaryRootCertificateForClientValidation@odata.bind', $ref)
            }

            $CreateParameters.Add('@odata.type', '#microsoft.graph.windowsWiredNetworkConfiguration')
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
            Write-Verbose -Message "Updating the Intune Device Configuration Wired Network Policy for Windows10 with Id {$($currentInstance.Id)}"
            $BoundParameters.Remove('Assignments') | Out-Null
            $BoundParameters.Remove('RootCertificatesForServerValidationIds') | Out-Null
            $BoundParameters.Remove('RootCertificatesForServerValidationDisplayNames') | Out-Null
            $BoundParameters.Remove('IdentityCertificateForClientAuthenticationId') | Out-Null
            $BoundParameters.Remove('IdentityCertificateForClientAuthenticationDisplayName') | Out-Null
            $BoundParameters.Remove('SecondaryIdentityCertificateForClientAuthenticationId') | Out-Null
            $BoundParameters.Remove('SecondaryIdentityCertificateForClientAuthenticationDisplayName') | Out-Null
            $BoundParameters.Remove('RootCertificateForClientValidationId') | Out-Null
            $BoundParameters.Remove('RootCertificateForClientValidationDisplayName') | Out-Null
            $BoundParameters.Remove('SecondaryRootCertificateForClientValidationId') | Out-Null
            $BoundParameters.Remove('SecondaryRootCertificateForClientValidationDisplayName') | Out-Null

            $updateParameters = ([Hashtable]$boundParameters).Clone()
            $updateParameters = Rename-M365DSCCimInstanceParameter -Properties $updateParameters
            $updateParameters.Remove('Id') | Out-Null

            #region resource generator code
            $UpdateParameters.Add('@odata.type', '#microsoft.graph.windowsWiredNetworkConfiguration')
            Update-MgBetaDeviceManagementDeviceConfiguration `
                -DeviceConfigurationId $currentInstance.Id `
                -BodyParameter $UpdateParameters
            $assignmentsHash = ConvertTo-IntunePolicyAssignment -IncludeDeviceFilter:$true -Assignments $this.Assignments
            Update-DeviceConfigurationPolicyAssignment `
                -DeviceConfigurationPolicyId $currentInstance.Id `
                -Targets $assignmentsHash `
                -Repository 'deviceManagement/deviceConfigurations'
            #endregion

            if ($null -ne $this.RootCertificatesForServerValidationIds -and $this.RootCertificatesForServerValidationIds.Count -gt 0 )
            {
                [Array]$rootCertificatesForServerValidationChecked = @()
                for ($i = 0; $i -lt $this.RootCertificatesForServerValidationIds.Count; $i++)
                {
                    $certId = $this.RootCertificatesForServerValidationIds[$i]
                    $certName = $this.RootCertificatesForServerValidationDisplayNames[$i]
                    $checkedCertId = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10IntuneDeviceConfigurationCertificateId -CertificateId $certId -CertificateDisplayName $certName -OdataTypes @('#microsoft.graph.windows81TrustedRootCertificate')
                    $rootCertificatesForServerValidationChecked += $checkedCertId
                }
                $this.RootCertificatesForServerValidationIds = $rootCertificatesForServerValidationChecked
                $compareResult = Compare-Object -ReferenceObject $currentInstance.RootCertificatesForServerValidationIds `
                    -DifferenceObject $this.RootCertificatesForServerValidationIds

                [Array]$certsToAdd = ($compareResult | Where-Object { $_.SideIndicator -eq '=>' }).InputObject
                [Array]$certsToRemove = ($compareResult | Where-Object { $_.SideIndicator -eq '<=' }).InputObject

                if ($certsToAdd.Count -gt 0)
                {
                    Update-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificateId -DeviceConfigurationPolicyId $currentInstance.Id `
                        -CertificateIds $certsToAdd `
                        -CertificateName rootCertificatesForServerValidation
                }

                if ($certsToRemove.Count -gt 0)
                {
                    Remove-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificateId -DeviceConfigurationPolicyId $currentInstance.Id `
                        -CertificateIds $certsToRemove `
                        -CertificateName rootCertificatesForServerValidation
                }
            }

            if (-not [String]::IsNullOrWhiteSpace($this.IdentityCertificateForClientAuthenticationId))
            {
                if ($this.IdentityCertificateForClientAuthenticationId -ne $currentInstance.IdentityCertificateForClientAuthenticationId)
                {
                    $this.IdentityCertificateForClientAuthenticationId = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10IntuneDeviceConfigurationCertificateId `
                        -CertificateId $this.IdentityCertificateForClientAuthenticationId `
                        -CertificateDisplayName $this.IdentityCertificateForClientAuthenticationDisplayName `
                        -OdataTypes @( `
                            '#microsoft.graph.windows81SCEPCertificateProfile', `
                            '#microsoft.graph.windows81TrustedRootCertificate', `
                            '#microsoft.graph.windows10PkcsCertificateProfile' `
                    )
                    Update-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificateId -DeviceConfigurationPolicyId $currentInstance.Id `
                        -CertificateIds $this.IdentityCertificateForClientAuthenticationId `
                        -CertificateName identityCertificateForClientAuthentication
                }
            }

            if (-not [String]::IsNullOrWhiteSpace($this.SecondaryIdentityCertificateForClientAuthenticationId))
            {
                if ($this.SecondaryIdentityCertificateForClientAuthenticationId -ne $currentInstance.SecondaryIdentityCertificateForClientAuthenticationId)
                {
                    $this.SecondaryIdentityCertificateForClientAuthenticationId = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10IntuneDeviceConfigurationCertificateId `
                        -CertificateId $this.SecondaryIdentityCertificateForClientAuthenticationId `
                        -CertificateDisplayName $this.SecondaryIdentityCertificateForClientAuthenticationDisplayName `
                        -OdataTypes @( `
                            '#microsoft.graph.windows81SCEPCertificateProfile', `
                            '#microsoft.graph.windows81TrustedRootCertificate', `
                            '#microsoft.graph.windows10PkcsCertificateProfile' `
                    )
                    Update-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificateId -DeviceConfigurationPolicyId $currentInstance.Id `
                        -CertificateIds $this.SecondaryIdentityCertificateForClientAuthenticationId `
                        -CertificateName secondaryIdentityCertificateForClientAuthentication
                }
            }

            if (-not [String]::IsNullOrWhiteSpace($this.RootCertificateForClientValidationId))
            {
                if ($this.RootCertificateForClientValidationId -ne $currentInstance.RootCertificateForClientValidationId)
                {
                    $this.RootCertificateForClientValidationId = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10IntuneDeviceConfigurationCertificateId `
                        -CertificateId $this.RootCertificateForClientValidationId `
                        -CertificateDisplayName $this.RootCertificateForClientValidationDisplayName `
                        -OdataTypes @('#microsoft.graph.windows81TrustedRootCertificate')
                    Update-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificateId -DeviceConfigurationPolicyId $currentInstance.Id `
                        -CertificateIds $this.RootCertificateForClientValidationId `
                        -CertificateName rootCertificateForClientValidation
                }
            }

            if (-not [String]::IsNullOrWhiteSpace($this.SecondaryRootCertificateForClientValidationId))
            {
                if ($this.SecondaryRootCertificateForClientValidationId -ne $currentInstance.SecondaryRootCertificateForClientValidationId)
                {
                    $this.SecondaryRootCertificateForClientValidationId = Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10IntuneDeviceConfigurationCertificateId `
                        -CertificateId $this.SecondaryRootCertificateForClientValidationId `
                        -CertificateDisplayName $this.SecondaryRootCertificateForClientValidationDisplayName `
                        -OdataTypes @('#microsoft.graph.windows81TrustedRootCertificate')
                    Update-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificateId -DeviceConfigurationPolicyId $currentInstance.Id `
                        -CertificateIds $this.SecondaryRootCertificateForClientValidationId `
                        -CertificateName secondaryRootCertificateForClientValidation
                }
            }
        }
        elseif ($this.Ensure -eq 'Absent' -and $currentInstance.Ensure -eq 'Present')
        {
            Write-Verbose -Message "Removing the Intune Device Configuration Wired Network Policy for Windows10 with Id {$($currentInstance.Id)}"
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

        $boundParameters = $this.GetBoundParameters()
        $excludedProperties = @()
        if ($boundParameters.ContainsKey('RootCertificatesForServerValidationDisplayNames'))
        {
            $excludedProperties += 'RootCertificatesForServerValidationIds'
        }

        if ($boundParameters.ContainsKey('IdentityCertificateForClientAuthenticationDisplayName'))
        {
            $excludedProperties += 'IdentityCertificateForClientAuthenticationId'
        }

        if ($boundParameters.ContainsKey('SecondaryIdentityCertificateForClientAuthenticationDisplayName'))
        {
            $excludedProperties += 'SecondaryIdentityCertificateForClientAuthenticationId'
        }

        if ($boundParameters.ContainsKey('RootCertificateForClientValidationDisplayName'))
        {
            $excludedProperties += 'RootCertificateForClientValidationId'
        }

        if ($boundParameters.ContainsKey('SecondaryRootCertificateForClientValidationDisplayName'))
        {
            $excludedProperties += 'SecondaryRootCertificateForClientValidationId'
        }

        $result = Test-M365DSCTargetResource -DesiredValues $boundParameters `
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
            $baseFilter = "isof('microsoft.graph.windowsWiredNetworkConfiguration')"
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
                    -NoEscape @('Assignments') `
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
                    $_.Exception -like '*Message: Location header not present in redirection response.*' -or `
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
    hidden [IntuneDeviceConfigurationWiredNetworkPolicyWindows10] AsResult([System.Object] $Values)
    {
        if ($Values -is [IntuneDeviceConfigurationWiredNetworkPolicyWindows10])
        {
            return $Values
        }

        $result = [IntuneDeviceConfigurationWiredNetworkPolicyWindows10]::new()
        if ($Values -is [System.Collections.Hashtable])
        {
            $result.FromHashtable($Values)
        }

        return $result
    }
}

class MSFT_DeviceManagementConfigurationPolicyAssignments
{
    [DscProperty(Mandatory)]
    [System.ComponentModel.Description('The type of the target assignment.')]
    [ValidateSet('#microsoft.graph.cloudPcManagementGroupAssignmentTarget', '#microsoft.graph.groupAssignmentTarget', '#microsoft.graph.allLicensedUsersAssignmentTarget', '#microsoft.graph.allDevicesAssignmentTarget', '#microsoft.graph.exclusionGroupAssignmentTarget', '#microsoft.graph.configurationManagerCollectionAssignmentTarget')]
    [System.String] $dataType

    [DscProperty()]
    [System.ComponentModel.Description('The type of filter of the target assignment i.e. Exclude or Include. Possible values are:none, include, exclude.')]
    [ValidateSet('none', 'include', 'exclude')]
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

# Was Get-IntuneDeviceConfigurationCertificateId. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10IntuneDeviceConfigurationCertificateId
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $CertificateId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $CertificateDisplayName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $OdataTypes
    )
    $Certificate = Get-MgBetaDeviceManagementDeviceConfiguration `
        -DeviceConfigurationId $CertificateId `
        -ErrorAction SilentlyContinue | `
            Where-Object -FilterScript {
            $_.'@odata.type' -in $OdataTypes
        }

    if ($null -eq $Certificate)
    {
        Write-Verbose -Message "Could not find certificate with Id {$CertificateId}, searching by display name {$CertificateDisplayName}"

        $Certificate = Get-MgBetaDeviceManagementDeviceConfiguration `
            -Filter "DisplayName eq '$($CertificateDisplayName -replace "'", "''")'" `
            -ErrorAction SilentlyContinue | `
                Where-Object -FilterScript {
                $_.'@odata.type' -in $OdataTypes
            }

        if ($null -eq $Certificate)
        {
            throw "Could not find certificate with Id {$CertificateId} or display name {$CertificateDisplayName}"
        }

        $CertificateId = $Certificate.Id
        Write-Verbose -Message "Found certificate with Id {$($CertificateId)} and DisplayName {$($Certificate.DisplayName)}"
    }
    else
    {
        Write-Verbose -Message "Found certificate with Id {$CertificateId}"
    }

    return $CertificateId
}

# Was Get-DeviceConfigurationPolicyCertificate. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Get-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificate
{
    [CmdletBinding()]
    [OutputType([System.String], [System.String[]])]
    param
    (
        [Parameter(Mandatory = 'true')]
        [System.String]
        $DeviceConfigurationPolicyId,

        [Parameter(Mandatory = 'true')]
        [ValidateSet('rootCertificatesForServerValidation', 'identityCertificateForClientAuthentication', 'secondaryIdentityCertificateForClientAuthentication', 'rootCertificateForClientValidation', 'secondaryRootCertificateForClientValidation')]
        [System.String]
        $CertificateName
    )
    $Uri = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + "beta/deviceManagement/deviceConfigurations('$DeviceConfigurationPolicyId')/microsoft.graph.windowsWiredNetworkConfiguration/$CertificateName"
    try
    {
        $result = Invoke-MgGraphRequest -Method Get -Uri $Uri 4>$null

        return $(if ($result.value)
            {
                $result.value
            }
            else
            {
                $result
            })
    }
    catch
    {
        return $null
    }

}

# Was Remove-DeviceConfigurationPolicyCertificateId. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Remove-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificateId
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = 'true')]
        [System.String]
        $DeviceConfigurationPolicyId,

        [Parameter(Mandatory = 'true')]
        [System.String[]]
        $CertificateIds,

        [Parameter(Mandatory = 'true')]
        [ValidateSet('rootCertificatesForServerValidation', 'identityCertificateForClientAuthentication', 'secondaryIdentityCertificateForClientAuthentication', 'rootCertificateForClientValidation', 'secondaryRootCertificateForClientValidation')]
        [System.String]
        $CertificateName
    )

    foreach ($certificateId in $CertificateIds)
    {
        $Uri = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + "beta/deviceManagement/deviceConfigurations('$DeviceConfigurationPolicyId')/microsoft.graph.windowsWiredNetworkConfiguration/$CertificateName/$certificateId/`$ref"
        Invoke-MgGraphRequest -Method DELETE -Uri $Uri -Body ($ref | ConvertTo-Json) -ErrorAction Stop 4>$null
    }
}

# Was Update-DeviceConfigurationPolicyCertificateId. Renamed because helper names recur across resources and the
# generated part file holds several of them.
function Update-IntuneDeviceConfigurationWiredNetworkPolicyWindows10DeviceConfigurationPolicyCertificateId
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = 'true')]
        [System.String]
        $DeviceConfigurationPolicyId,

        [Parameter(Mandatory = 'true')]
        [System.String[]]
        $CertificateIds,

        [Parameter(Mandatory = 'true')]
        [ValidateSet('rootCertificatesForServerValidation', 'identityCertificateForClientAuthentication', 'secondaryIdentityCertificateForClientAuthentication', 'rootCertificateForClientValidation', 'secondaryRootCertificateForClientValidation')]
        [System.String]
        $CertificateName
    )
    $Uri = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + "beta/deviceManagement/deviceConfigurations('$DeviceConfigurationPolicyId')/microsoft.graph.windowsWiredNetworkConfiguration/$CertificateName/`$ref"

    if ($CertificateName -eq 'rootCertificatesForServerValidation')
    {
        $method = 'POST'
    }
    else
    {
        $method = 'PUT'
    }

    foreach ($certificateId in $CertificateIds)
    {
        $ref = @{
            '@odata.id' = "$((Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl)beta/deviceManagement/deviceConfigurations('$certificateId')"
        }

        Invoke-MgGraphRequest -Method $method -Uri $Uri -Body ($ref | ConvertTo-Json) -ErrorAction Stop 4>$null
    }
}

