# Editor-only: lets this file resolve [M365DSCResourceBase] when parsed on its own.
# Build-Microsoft365DSC.ps1 emits only the class extent, so this line is not shipped.
using module ..\_Base\M365DSCResourceBase.psm1

[DscResource()]
class AADUser : M365DSCResourceBase
{
    [DscProperty(Key)]
    [System.ComponentModel.Description('The login name of the user')]
    [System.String] $UserPrincipalName

    [DscProperty()]
    [System.ComponentModel.Description('Specifies whether the user account is enabled or not. Required when a user is created.')]
    [System.Nullable[System.Boolean]] $AccountEnabled

    [DscProperty()]
    [System.ComponentModel.Description('The display name for the user')]
    [System.String] $DisplayName

    [DscProperty()]
    [System.ComponentModel.Description('The first name of the user')]
    [System.String] $FirstName

    [DscProperty()]
    [System.ComponentModel.Description('The last name of the user')]
    [System.String] $LastName

    [DscProperty()]
    [System.ComponentModel.Description('The list of Azure Active Directory roles assigned to the user.')]
    [System.String[]] $Roles

    [DscProperty()]
    [System.ComponentModel.Description('The country code the user will be assigned to')]
    [System.String] $UsageLocation

    [DscProperty()]
    [System.ComponentModel.Description('The account SKU Id for the license to be assigned to the user')]
    [System.String[]] $LicenseAssignment

    [DscProperty()]
    [System.ComponentModel.Description('The password for the account. The parameter is a PSCredential object, but only the Password component will be used. If Password is not supplied for a new resource a new random password will be generated. Property will only be used when creating the user and not on subsequent updates.')]
    [System.Management.Automation.PSCredential] $Password

    [DscProperty()]
    [System.ComponentModel.Description('The City name of the user')]
    [System.String] $City

    [DscProperty()]
    [System.ComponentModel.Description('The Country name of the user')]
    [System.String] $Country

    [DscProperty()]
    [System.ComponentModel.Description('The Department name of the user')]
    [System.String] $Department

    [DscProperty()]
    [System.ComponentModel.Description('The Fax Number of the user')]
    [System.String] $Fax

    [DscProperty()]
    [System.ComponentModel.Description('The Groups that the user is a direct member of')]
    [System.String[]] $MemberOf

    [DscProperty()]
    [System.ComponentModel.Description('The Mobile Phone Number of the user')]
    [System.String] $MobilePhone

    [DscProperty()]
    [System.ComponentModel.Description('The Office Name of the user')]
    [System.String] $Office

    [DscProperty()]
    [System.ComponentModel.Description('The mail address of the user')]
    [System.String] $Mail

    [DscProperty()]
    [System.ComponentModel.Description('The other mails assigned to the user')]
    [System.String[]] $OtherMails

    [DscProperty()]
    [System.ComponentModel.Description('Specifies whether the user password expires periodically. Default value is false')]
    [System.Nullable[System.Boolean]] $PasswordNeverExpires

    [DscProperty()]
    [System.ComponentModel.Description('Specifies password policies for the user.')]
    [System.String] $PasswordPolicies

    [DscProperty()]
    [System.ComponentModel.Description('The Phone Number of the user')]
    [System.String] $PhoneNumber

    [DscProperty()]
    [System.ComponentModel.Description('The Postal Code of the user')]
    [System.String] $PostalCode

    [DscProperty()]
    [System.ComponentModel.Description('The Preferred Language of the user')]
    [System.String] $PreferredLanguage

    [DscProperty()]
    [System.ComponentModel.Description('Specifies the state or province where the user is located')]
    [System.String] $State

    [DscProperty()]
    [System.ComponentModel.Description('Specifies the street address of the user')]
    [System.String] $StreetAddress

    [DscProperty()]
    [System.ComponentModel.Description('Specifies the title of the user')]
    [System.String] $Title

    [DscProperty()]
    [System.ComponentModel.Description('Specifies the title of the user')]
    [ValidateSet('Guest', 'Member', 'Other', 'Viral')]
    [System.String] $UserType

    [DscProperty()]
    [System.ComponentModel.Description('Present ensures the user exists, absent ensures it is removed')]
    [ValidateSet('Present', 'Absent')]
    [System.String] $Ensure

    [DscProperty()]
    [System.ComponentModel.Description('Credentials of the Exchange Global Admin')]
    [System.Management.Automation.PSCredential] $Credential

    [DscProperty()]
    [System.ComponentModel.Description('Id of the Azure Active Directory application to authenticate with.')]
    [System.String] $ApplicationId

    [DscProperty()]
    [System.ComponentModel.Description('Name of the Azure Active Directory tenant used for authentication. Format contoso.onmicrosoft.com')]
    [System.String] $TenantId

    [DscProperty()]
    [System.ComponentModel.Description('Secret of the Azure Active Directory application used for authentication.')]
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

    AADUser() : base()
    {
        $this.ResourceCache['propertiesToRetrieve'] = @('Id', 'AccountEnabled', 'UserPrincipalName', 'DisplayName', 'GivenName', 'Surname', 'UsageLocation', 'City', 'Country', 'Department', 'FaxNumber', 'MobilePhone', 'OfficeLocation', 'Mail', 'OtherMails', 'BusinessPhones', 'PostalCode', 'PreferredLanguage', 'State', 'StreetAddress', 'JobTitle', 'UserType', 'PasswordPolicies')
        $this.ResourceCache['creationParamsMap'] = @{AccountEnabled = 'AccountEnabled'; City = 'City'; Country = 'Country'; Department = 'Department'; DisplayName = 'DisplayName'; FaxNumber = 'Fax'; GivenName = 'FirstName'; JobTitle = 'Title'; MobilePhone = 'MobilePhone'; OfficeLocation = 'Office'; Mail = 'Mail'; OtherMails = 'OtherMails'; PostalCode = 'PostalCode'; PreferredLanguage = 'PreferredLanguage'; State = 'State'; StreetAddress = 'StreetAddress'; Surname = 'LastName'; BusinessPhones = 'PhoneNumber'; UsageLocation = 'UsageLocation'; UserPrincipalName = 'UserPrincipalName'; UserType = 'UserType'; PasswordPolicies = 'PasswordPolicies'}
    }

    [AADUser] Get()
    {
        if ($this.RequiresPowerShellCore())
        {
            $remote = [AADUser]::new()
            $remote.FromHashtable($this.InvokeInPowerShellCore('Get'))
            return $remote
        }

        Write-Verbose -Message "Getting configuration of Office 365 User $($this.UserPrincipalName)"

        # TODO: Remove property 'PasswordNeverExpires' in next breaking change
        if ($this.GetBoundParameters().ContainsKey('PasswordNeverExpires'))
        {
            $this.GetBoundParameters().Remove('PasswordNeverExpires') | Out-Null
            Write-Warning "Property 'PasswordNeverExpires' is deprecated and will be removed, please use 'PasswordPolicies' instead with 'DisablePasswordExpiration'"
        }

        try
        {
            if (-not $this.ExportedInstance -or $this.ExportedInstance.UserPrincipalName -ne $this.UserPrincipalName)
            {
                $null = $this.Connect('MicrosoftGraph')

                #Ensure the proper dependencies are installed in the current environment.
                Confirm-M365DSCDependencies

                #region Telemetry
                $this.AddTelemetry('Get')
                #endregion

                $nullReturn = @{
                    UserPrincipalName     = $null
                    AccountEnabled        = $null
                    DisplayName           = $null
                    FirstName             = $null
                    LastName              = $null
                    UsageLocation         = $null
                    LicenseAssignment     = $null
                    MemberOf              = $null
                    Mail                  = $null
                    OtherMails            = $null
                    Password              = $null
                    Credential            = $this.Credential
                    ApplicationId         = $this.ApplicationId
                    TenantId              = $this.TenantId
                    CertificateThumbprint = $this.CertificateThumbprint
                    CertificatePath       = $this.CertificatePath
                    CertificatePassword   = $this.CertificatePassword
                    ManagedIdentity       = $this.ManagedIdentity.IsPresent
                    ApplicationSecret     = $this.ApplicationSecret
                    Ensure                = 'Absent'
                    AccessTokens          = $this.AccessTokens
                }

                Write-Verbose -Message "Getting Office 365 User $($this.UserPrincipalName)"
                $user = Get-MgUser -UserId $this.UserPrincipalName -Property $this.ResourceCache['propertiesToRetrieve'] -ErrorAction SilentlyContinue
                if ($null -eq $user)
                {
                    Write-Verbose -Message "The specified User doesn't already exist."
                    return $this.AsResult($nullReturn)
                }
            }
            else
            {
                Write-Verbose -Message 'Retrieving user from the exported instances'
                $user = $this.ExportedInstance
            }

            $batchRequests = @(
                @{
                    id     = 'License'
                    method = 'GET'
                    url    = "/users/$($this.UserPrincipalName)/licenseDetails"
                }
                @{
                    id      = 'MemberOf'
                    method  = 'GET'
                    url     = "/users/$($this.UserPrincipalName)/memberOf/microsoft.graph.group?`$select=displayName&`$filter=not(groupTypes/any(c:c eq 'DynamicMembership'))"
                    headers = @{
                        'ConsistencyLevel' = 'eventual'
                    }
                }
            )
            $batchResponse = Invoke-M365DSCGraphBatchRequest -Requests $batchRequests

            # If the user was deleted in the meantime, then return an empty hashtable
            # This only happens during Export because we cache the user objects
            # During normal Get or Test, we would have already returned $nullReturn above
            if ($null -ne $this.ExportedInstance -and $batchResponse.status -contains '404')
            {
                Write-Verbose -Message 'The specified user was deleted in the meantime.'
                return $this.AsResult(@{})
            }

            Write-Verbose -Message "Found User $($this.UserPrincipalName)"
            $currentLicenseAssignment = @()
            $skus = ($batchResponse | Where-Object -FilterScript { $_.id -eq 'License' }).body.value
            foreach ($sku in $skus)
            {
                $currentLicenseAssignment += $sku.SkuPartNumber
            }

            # return membership of static groups only
            [array]$currentMemberOf = ($batchResponse | Where-Object -FilterScript { $_.id -eq 'MemberOf' }).body.value.DisplayName

            if ($null -eq $this.ResourceCache['allDirectoryRoleAssignment'])
            {
                $this.ResourceCache['allDirectoryRoleAssignment'] = Get-MgBetaRoleManagementDirectoryRoleAssignment -All
            }
            $assignedRoles = $this.ResourceCache['allDirectoryRoleAssignment'] | Where-Object -FilterScript { $_.PrincipalId -eq $user.Id }

            $rolesValue = @()
            if ($null -eq $this.ResourceCache['allAssignedRoles'] -and $assignedRoles.Length -gt 0)
            {
                $this.ResourceCache['allAssignedRoles'] = Get-MgBetaRoleManagementDirectoryRoleDefinition -All
            }
            foreach ($assignedRole in $assignedRoles)
            {
                $currentRoleInfo = $this.ResourceCache['allAssignedRoles'] | Where-Object -FilterScript { $_.Id -eq $assignedRole.RoleDefinitionId }
                $rolesValue += $currentRoleInfo.DisplayName
            }

            $results = @{
                UserPrincipalName     = $this.UserPrincipalName
                AccountEnabled        = $user.AccountEnabled
                DisplayName           = $user.DisplayName
                FirstName             = $user.GivenName
                LastName              = $user.Surname
                UsageLocation         = $user.UsageLocation
                LicenseAssignment     = $currentLicenseAssignment
                MemberOf              = $currentMemberOf
                Password              = $this.Password
                City                  = $user.City
                Country               = $user.Country
                Department            = $user.Department
                Fax                   = $user.FaxNumber
                MobilePhone           = $user.MobilePhone
                Office                = $user.OfficeLocation
                Mail                  = $user.Mail
                OtherMails            = $user.OtherMails
                PasswordPolicies      = $user.PasswordPolicies
                PhoneNumber           = $user.BusinessPhones | Select-Object -First 1
                PostalCode            = $user.PostalCode
                PreferredLanguage     = $user.PreferredLanguage
                State                 = $user.State
                StreetAddress         = $user.StreetAddress
                Title                 = $user.JobTitle
                UserType              = $user.UserType
                Roles                 = $rolesValue
                Credential            = $this.Credential
                ApplicationId         = $this.ApplicationId
                TenantId              = $this.TenantId
                ApplicationSecret     = $this.ApplicationSecret
                CertificateThumbprint = $this.CertificateThumbprint
                Ensure                = 'Present'
                AccessTokens          = $this.AccessTokens
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
        $licenses = $null
        # Declared up front: assigned conditionally below, which class methods reject.
        $licenseDifferences = $null
        if ($this.RequiresPowerShellCore())
        {
            $null = $this.InvokeInPowerShellCore('Set')
            return
        }

        Write-Verbose -Message "Setting configuration of Office 365 User $($this.UserPrincipalName)"

        # TODO: Remove property 'PasswordNeverExpires' in next breaking change
        if ($this.GetBoundParameters().ContainsKey('PasswordNeverExpires'))
        {
            $this.GetBoundParameters().Remove('PasswordNeverExpires') | Out-Null
            Write-Warning "Property 'PasswordNeverExpires' is deprecated and will be removed, please use 'PasswordPolicies' instead with 'DisablePasswordExpiration'"
        }

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Set')
        #endregion

        $user = $this.Get().ToHashtable()
        if ($user.Ensure -eq 'Present' -and $this.Ensure -eq 'Absent')
        {
            Write-Verbose -Message "Removing User {$($this.UserPrincipalName)}"
            Remove-MgUser -UserId $this.UserPrincipalName
        }
        elseif ($this.Ensure -eq 'Present')
        {
            $creationParams = @{}
            foreach ($kvp in $this.ResourceCache['creationParamsMap'].GetEnumerator())
            {
                if ($this.GetBoundParameters().ContainsKey($($kvp.Value)))
                {
                    $creationParams.Add($kvp.Key, $this.GetBoundParameters().$($kvp.Value))
                }
            }
            $creationParams = Remove-NullEntriesFromHashtable -Hash $CreationParams
            $creationParams = Rename-M365DSCCimInstanceParameter -Properties $creationParams
            if ($creationParams.ContainsKey("BusinessPhones"))
            {
                $BusinessPhones = Get-M365DSCArrayFromProperty -PropertyValue $this.PhoneNumber -ElementType ([System.String])
                $creationParams["BusinessPhones"] = $BusinessPhones
            }

            #region Licenses
            if ($null -ne $this.LicenseAssignment)
            {
                [Array] $currentLicenses = $user.LicenseAssignment
                if ($null -eq $currentLicenses)
                {
                    $currentLicenses = @()
                }
                [Array]$licenseDifferences = Compare-Object -ReferenceObject $this.LicenseAssignment -DifferenceObject $currentLicenses
                if ($licenseDifferences.Length -gt 0)
                {
                    $licenses = @{addLicenses = @(); removeLicenses = @(); }

                    $SubscribedSku = Get-MgBetaSubscribedSku
                    foreach ($licenseSkuPart in $this.LicenseAssignment)
                    {
                        Write-Verbose -Message "Adding License {$licenseSkuPart} to the Queue"
                        $license = @{
                            skuId = ($SubscribedSku | Where-Object -Property SkuPartNumber -Value $licenseSkuPart -EQ).SkuID
                        }

                        # Set the Office license as the license we want to add in the $licenses object
                        $licenses.addLicenses += $license
                    }

                    foreach ($currentLicense in $user.LicenseAssignment)
                    {
                        if ($this.LicenseAssignment -and -not $this.LicenseAssignment.Contains($currentLicense))
                        {
                            Write-Verbose -Message "Removing {$currentLicense} from user {$($this.UserPrincipalName)}"
                            $license = @{
                                skuId = ($SubscribedSku | Where-Object -Property SkuPartNumber -Value $currentLicense -EQ).SkuID
                            }
                            $licenses.removeLicenses += $license
                        }
                    }
                }
            }
            #endregion

            if ($null -ne $user.UserPrincipalName)
            {
                Write-Verbose -Message "Updating Office 365 User $($this.UserPrincipalName) Information"

                if ($null -ne $this.Password)
                {
                    Write-Verbose -Message 'PasswordProfile property will not be updated'
                }

                Update-MgUser -UserId $this.UserPrincipalName -BodyParameter $creationParams
                $userId = (Get-MgUser -UserId $this.UserPrincipalName).Id
            }
            else
            {
                if ($null -ne $this.Password)
                {
                    $passwordValue = $this.Password.GetNetworkCredential().Password
                }
                else
                {
                    # [System.Web.Security.Membership] does not exist on .NET Core
                    $TokenSet = @{
                        U = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                        L = [Char[]]'abcdefghijklmnopqrstuvwxyz'
                        N = [Char[]]'0123456789'
                        S = [Char[]]'!"#$%&''()*+,-./:;<=>?@[\]^_`{|}~'
                    }

                    $Upper = Get-Random -Count 8 -InputObject $TokenSet.U
                    $Lower = Get-Random -Count 8 -InputObject $TokenSet.L
                    $Number = Get-Random -Count 8 -InputObject $TokenSet.N
                    $Special = Get-Random -Count 8 -InputObject $TokenSet.S

                    $StringSet = $Upper + $Lower + $Number + $Special

                    $stringPassword = (Get-Random -Count 30 -InputObject $StringSet) -join ''
                    $passwordValue = ConvertTo-SecureString $stringPassword -AsPlainText -Force
                }

                $PasswordProfile = @{
                    password = $passwordValue
                }
                $creationParams.Add('passwordProfile', $PasswordProfile)

                Write-Verbose -Message "Creating Office 365 User $($this.UserPrincipalName)"
                if (-not $creationParams.ContainsKey('accountEnabled') -or $null -eq $creationParams.accountEnabled)
                {
                    $creationParams.accountEnabled = $true
                }
                $creationParams.Add('mailNickName', $this.UserPrincipalName.Split('@')[0])
                Write-Verbose -Message "Creating new user with values: $(Convert-M365DscHashtableToString -Hashtable $creationParams)"
                $user = New-MgUser -BodyParameter $creationParams
                $userId = $user.Id
            }

            #region Assign Licenses
            try
            {
                if ($licenseDifferences.Length -gt 0)
                {
                    Write-Verbose -Message "Updating License assignments with values: $(Convert-M365DscHashtableToString -Hashtable $licenses)"
                    Invoke-M365DSCCommand -ScriptBlock {
                        Set-MgUserLicense -UserId $user.UserPrincipalName -AddLicenses $licenses.addLicenses -RemoveLicenses $licenses.removeLicenses
                    } -RetryOnNotFoundError
                }
            }
            catch
            {
                $this.LogError($_, 'Error updating data:')

                return
            }
            #endregion

            #region Update MemberOf groups - if specified
            if ($null -ne $this.MemberOf)
            {
                if ($null -eq $user.MemberOf)
                {
                    # user is not currently a member of any groups, add user to groups listed in MemberOf
                    foreach ($memberOfGroup in $this.MemberOf)
                    {
                        $group = Get-MgGroup -Filter "DisplayName eq '$($memberOfGroup -replace "'", "''")'" -Property Id, GroupTypes
                        if ($null -eq $group)
                        {
                            $this.LogError($_, 'Error updating data:')

                            throw "Group '$memberOfGroup' does not exist in tenant"
                        }
                        if ($group.GroupTypes -contains 'DynamicMembership')
                        {
                            $this.LogError($_, 'Error updating data:')

                            throw "Cannot add user $($this.UserPrincipalName) to group '$memberOfGroup' because it is a dynamic group"
                        }
                        Invoke-M365DSCCommand -ScriptBlock {
                            New-MgGroupMemberByRef -GroupId $group.Id -BodyParameter @{
                                '@odata.id' = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + "v1.0/directoryObjects/$userId"
                            }
                        } -RetryOnNotFoundError
                    }
                }
                else
                {
                    # user is a member of some groups, ensure that user is only a member of groups listed in MemberOf
                    Compare-Object -ReferenceObject $this.MemberOf -DifferenceObject $user.MemberOf | ForEach-Object {
                        $group = Get-MgGroup -Filter "DisplayName eq '$($_.InputObject -replace "'", "''")'" -Property Id, GroupTypes
                        if ($_.SideIndicator -eq '<=')
                        {
                            # Group in MemberOf not present in groups that user is a member of, add user to group
                            if ($null -eq $group)
                            {
                                $this.LogError($_, 'Error updating data:')

                                throw "Group '$($_.InputObject)' does not exist in tenant"
                            }
                            if ($group.GroupTypes -contains 'DynamicMembership')
                            {
                                $this.LogError($_, 'Error updating data:')

                                throw "Cannot add user $($this.UserPrincipalName) to group '$($_.InputObject)' because it is a dynamic group"
                            }
                            New-MgGroupMemberByRef -GroupId $group.Id -BodyParameter @{
                                '@odata.id' = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + "v1.0/directoryObjects/$userId"
                            } | Out-Null
                        }
                        else
                        {
                            # Group that user is a member of is not present in MemberOf, remove user from group
                            # (no need to test for dynamic groups as they are ignored in Get-TargetResource)
                            if ($null -eq $group)
                            {
                                $this.LogError($_, 'Error updating data:')

                                throw "Group '$($_.InputObject)' does not exist in tenant"
                            }
                            Remove-MgGroupMemberDirectoryObjectByRef -GroupId $group.Id -DirectoryObjectId $userId
                        }
                    }
                }
            }
            #endregion

            #region Roles
            if ($null -ne $this.Roles)
            {
                [Array] $currentRoles = $user.Roles
                if ($null -eq $currentRoles -or $currentRoles.Length -eq 0)
                {
                    $currentRoles = @()
                }

                [Array]$diffRoles = Compare-Object -ReferenceObject $this.Roles -DifferenceObject $currentRoles

                if ($diffRoles.Length -gt 0)
                {
                    Write-Verbose -Message "Current Roles: $($currentRoles -join ',')"
                    Write-Verbose -Message "Desired Roles: $($this.Roles -join ',')"
                }

                foreach ($roleDifference in $diffRoles)
                {
                    $roleDefinitionId = (Get-MgBetaRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq '$($roleDifference.InputObject -replace "'", "''")'").Id

                    # Roles to remove
                    if ($roleDifference.SideIndicator -eq '=>')
                    {
                        $currentAssignment = Get-MgBetaRoleManagementDirectoryRoleAssignment -Filter "PrincipalId eq '$userId' and RoleDefinitionId eq '$roleDefinitionId'"

                        Write-Verbose -Message "Removing role assignment for user {$($user.UserPrincipalName)} for role {$($roleDifference.InputObject)}"
                        Remove-MgBetaRoleManagementDirectoryRoleAssignment -UnifiedRoleAssignmentId $currentAssignment.Id | Out-Null
                    }
                    # Roles to add
                    elseif ($roleDifference.SideIndicator -eq '<=')
                    {
                        Write-Verbose -Message "Creating role assignment for user {$($user.UserPrincipalName) for role {$($roleDifference.InputObject)}"
                        Invoke-M365DSCCommand -ScriptBlock {
                            New-MgBetaRoleManagementDirectoryRoleAssignment -PrincipalId $userId `
                                -RoleDefinitionId $roleDefinitionId `
                                -DirectoryScopeId '/' | Out-Null
                        } -RetryOnNotFoundError
                    }
                }
            }
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

        $ConnectionMode = $this.Connect('MicrosoftGraph')

        #Ensure the proper dependencies are installed in the current environment.
        Confirm-M365DSCDependencies

        #region Telemetry
        $this.AddTelemetry('Export')
        #endregion

        try
        {
            $ExportParameters = @{
                Filter      = $this.Filter
                All         = [switch]$true
                Property    = $this.ResourceCache['propertiesToRetrieve']
                ErrorAction = 'Stop'
                Sort        = 'UserPrincipalName'
            }
            $queryTypes = @{
                'eq'         = @('assignedPlans/any(a:a/capabilityStatus)',
                    'assignedPlans/any(a:a/service)',
                    'assignedPlans/any(a:a/servicePlanId)',
                    'authorizationInfo/certificateUserIds/any(p:p)',
                    'businessPhones/any(p:p)',
                    'companyName',
                    'createdObjects/any(c:c/id)',
                    'employeeHireDate',
                    'employeeOrgData/costCenter',
                    'employeeOrgData/division',
                    'employeeType',
                    'faxNumber',
                    'mobilePhone',
                    'officeLocation',
                    'onPremisesExtensionAttributes/extensionAttribute1',
                    'onPremisesExtensionAttributes/extensionAttribute10',
                    'onPremisesExtensionAttributes/extensionAttribute11',
                    'onPremisesExtensionAttributes/extensionAttribute12',
                    'onPremisesExtensionAttributes/extensionAttribute13',
                    'onPremisesExtensionAttributes/extensionAttribute14',
                    'onPremisesExtensionAttributes/extensionAttribute15',
                    'onPremisesExtensionAttributes/extensionAttribute2',
                    'onPremisesExtensionAttributes/extensionAttribute3',
                    'onPremisesExtensionAttributes/extensionAttribute4',
                    'onPremisesExtensionAttributes/extensionAttribute5',
                    'onPremisesExtensionAttributes/extensionAttribute6',
                    'onPremisesExtensionAttributes/extensionAttribute7',
                    'onPremisesExtensionAttributes/extensionAttribute8',
                    'onPremisesExtensionAttributes/extensionAttribute9',
                    'onPremisesSamAccountName',
                    'passwordProfile/forceChangePasswordNextSignIn',
                    'passwordProfile/forceChangePasswordNextSignInWithMfa',
                    'postalCode',
                    'preferredLanguage',
                    'provisionedPlans/any(p:p/provisioningStatus)',
                    'provisionedPlans/any(p:p/service)',
                    'showInAddressList',
                    'streetAddress')

                'startsWith' = @(
                    'assignedPlans/any(a:a/service)',
                    'businessPhones/any(p:p)',
                    'companyName',
                    'faxNumber',
                    'mobilePhone',
                    'officeLocation',
                    'onPremisesSamAccountName',
                    'postalCode',
                    'preferredLanguage',
                    'provisionedPlans/any(p:p/service)',
                    'streetAddress'
                )
                'ge'         = @('employeeHireDate')
                'le'         = @('employeeHireDate')
                'eq Null'    = @(
                    'city',
                    'companyName',
                    'country',
                    'createdDateTime',
                    'department',
                    'displayName',
                    'employeeId',
                    'faxNumber',
                    'givenName',
                    'jobTitle',
                    'mail',
                    'mailNickname',
                    'mobilePhone',
                    'officeLocation',
                    'onPremisesExtensionAttributes/extensionAttribute1',
                    'onPremisesExtensionAttributes/extensionAttribute10',
                    'onPremisesExtensionAttributes/extensionAttribute11',
                    'onPremisesExtensionAttributes/extensionAttribute12',
                    'onPremisesExtensionAttributes/extensionAttribute13',
                    'onPremisesExtensionAttributes/extensionAttribute14',
                    'onPremisesExtensionAttributes/extensionAttribute15',
                    'onPremisesExtensionAttributes/extensionAttribute2',
                    'onPremisesExtensionAttributes/extensionAttribute3',
                    'onPremisesExtensionAttributes/extensionAttribute4',
                    'onPremisesExtensionAttributes/extensionAttribute5',
                    'onPremisesExtensionAttributes/extensionAttribute6',
                    'onPremisesExtensionAttributes/extensionAttribute7',
                    'onPremisesExtensionAttributes/extensionAttribute8',
                    'onPremisesExtensionAttributes/extensionAttribute9',
                    'onPremisesSecurityIdentifier',
                    'onPremisesSyncEnabled',
                    'passwordPolicies',
                    'passwordProfile/forceChangePasswordNextSignIn',
                    'passwordProfile/forceChangePasswordNextSignInWithMfa',
                    'postalCode',
                    'preferredLanguage',
                    'state',
                    'streetAddress',
                    'surname',
                    'usageLocation',
                    'userType'
                )
            }

            # Initialize a flag to indicate whether the filter conditions match the attribute support
            $allConditionsMatched = $true

            # Check each condition in the filter against the support list
            # Assuming the provided PowerShell script is part of a larger context and the variable $Filter is defined elsewhere

            # Check if $Filter is not null
            if ($this.Filter)
            {
                # Check each condition in the filter against the support list
                foreach ($condition in $this.Filter.Split(' '))
                {
                    if ($condition -match '(\w+)/(\w+):(\w+)')
                    {
                        $attribute, $operation, $value = $matches[1], $matches[2], $matches[3]
                        if (-not $queryTypes.ContainsKey($operation) -or -not $queryTypes[$operation].Contains($attribute))
                        {
                            $allConditionsMatched = $false
                            break
                        }
                    }
                }
            }

            # If all conditions match the support, add parameters to $ExportParameters
            if ($allConditionsMatched -or ($this.Filter -like '*endsWith*') -or ($this.Filter -like '*not*'))
            {
                $ExportParameters.Add('CountVariable', 'count')
                $ExportParameters.Add('ConsistencyLevel', 'eventual')
            }
            $this.ResourceCache['M365DSCExportInstances'] = Get-MgUser @ExportParameters

            $dscContent = [System.Text.StringBuilder]::new()
            $i = 1
            Write-M365DSCHost -Message "`r`n" -DeferWrite
            foreach ($user in $this.ResourceCache['M365DSCExportInstances'])
            {
                if ($null -ne $Global:M365DSCExportResourceInstancesCount)
                {
                    $Global:M365DSCExportResourceInstancesCount++
                }

                Write-M365DSCHost -Message "    |---[$i/$($this.ResourceCache['M365DSCExportInstances'].Length)] $($user.UserPrincipalName)" -DeferWrite
                $userUPN = $user.UserPrincipalName
                if (-not [System.String]::IsNullOrEmpty($userUPN))
                {
                    $Params = @{
                        UserPrincipalName     = $userUPN
                        Credential            = $this.Credential
                        ApplicationId         = $this.ApplicationId
                        TenantId              = $this.TenantId
                        CertificateThumbprint = $this.CertificateThumbprint
                        ManagedIdentity       = $this.ManagedIdentity.IsPresent
                        ApplicationSecret     = $this.ApplicationSecret
                        AccessTokens          = $this.AccessTokens
                    }

                    $this.ExportedInstance = $user
                    $Results = $this.GetForExport($Params)
                    $rawResults = $Results.Clone()
                    $Results.Password = "New-Object System.Management.Automation.PSCredential('Password', (ConvertTo-SecureString ((New-Guid).ToString()) -AsPlainText -Force))"
                    if ($null -ne $Results.UserPrincipalName)
                    {
                        $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $this.GetResourceName() `
                            -ConnectionMode $ConnectionMode `
                            -ModulePath $this.GetModulePath() `
                            -Results $Results `
                            -Credential $this.Credential `
                            -NoEscape @('Password') `
                            -RawResults $rawResults

                        [void]$dscContent.Append($currentDSCBlock)
                        Save-M365DSCPartialExport -Content $currentDSCBlock `
                            -FileName $Global:PartialExportFileName
                    }
                }
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
            ExcludedProperties = @('PasswordNeverExpires')
        }
    }

    # Materialises a Get() result. The script-based body built a hashtable; DSC needs the type.
    hidden [AADUser] AsResult([System.Object] $Values)
    {
        if ($Values -is [AADUser])
        {
            return $Values
        }

        $result = [AADUser]::new()
        if ($Values -is [System.Collections.Hashtable])
        {
            $result.FromHashtable($Values)
        }

        return $result
    }
}
