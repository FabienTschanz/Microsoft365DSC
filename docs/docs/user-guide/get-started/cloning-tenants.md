This feature of Microsoft365DSC is not a true standalone feature. It is a combination of existing features to unlock a new scenario for users.

## Clone = Export/Deploy

Since Microsoft365DSC is able to take a snapshot of any Microsoft 365 tenant and can deploy a Microsoft365DSC configuration onto any tenant, we can easily clone the configuration of any tenant over another one (or another set of tenants).

When you take a snapshot of an existing tenant, the extracted configuration file doesn’t contain any information that is specific to the source tenant. It abstracts it all into variables, which make the configuration generic instead of unique for a particular tenant. It is then at compilation time that you provide information about the environment onto which this configuration will be applied to.

<figure markdown>
  ![Flow of the clone process](../../Images/SyncFlow.png)
  <figcaption>Flow of the clone process</figcaption>
</figure>

***For example:***

Let's assume you are trying to clone the configuration of Tenant A onto Tenant B. You would start by capturing the existing configuration of tenant A using credentials or a Service Principal that exists and has rights on Tenant A. This will generate the configuration file containing all the configuration settings for Tenant A. Then at compilation time, when trying to compile the extracted configuration into a MOF file, you will need to provide credentials or a Service Principal that has access to Tenant B. Then all that is left to do is to deploy the configuration onto Tenant B to have all the configurations settings from tenant A applied onto it.

### Full example script for cloning one resource

```PowerShell
Install-Module Microsoft365Dsc

Update-M365DSCDependencies

$SourceCredential = Get-Credential

Update-M365DSCAllowedGraphScopes -ResourceNameList @("AADGroupsNamingPolicy") -Type Read

Export-M365DSCConfiguration -Components @("AADGroupsNamingPolicy") -Credential $SourceCredential -Path C:\Dsc
```

Now browse to the specified export folder and open the generated ConfigurationData.psd1 file. Update all tenant specific information in this file with the correct information for the target tenant. For example, a UPN suffix (tenantname.onmicrosoft.com) or the SharePoint URL (tenantname.sharepoint.com).

Then open the M365TenantConfig.ps1 file and replace all instances of tenant specific information in this file.

If you already know the information beforehand, you can use the parameter `TokenReplacement` of the `Export-M365DSCConfiguration` command. For more information on how to use this parameter, please refer to the [Export-M365DSCConfiguration](../cmdlets/Export-M365DSCConfiguration.md) cmdlet documentation.

```PowerShell
$TargetCredential = Get-Credential

Update-M365DSCAllowedGraphScopes -ResourceNameList @("AADGroupsNamingPolicy") -Type Update

C:\Dsc\M365TenantConfig.ps1 -Credential $TargetCredential

Start-DscConfiguration -Path C:\Dsc -Wait -Verbose
```

## Managing Resource Dependencies

When cloning tenant configurations, it's important to understand that some resources can have dependencies on other resources. This means that certain resources may need to be deployed in a specific order, or their behavior needs to be adjusted during the cloning process to avoid conflicts.

### Understanding Resource Dependencies

A common example of resource dependencies occurs with Entra (AAD) resources:

- **AADUser** resources represent user accounts
- **AADGroup** resources represent groups
- Users can be members of groups, creating a dependency relationship

When exporting a configuration, the AADUser resource by default includes group membership information (MemberOf property). However, during a cloning operation to a new tenant, this can create challenges:

1. The groups referenced in the MemberOf property may not exist yet in the target tenant
2. Group object IDs will be different between source and target tenants
3. The deployment may fail if it tries to assign users to non-existent groups

### Using M365DSC_RESOURCE_SETTINGS Environment Variable

Microsoft365DSC provides the `M365DSC_RESOURCE_SETTINGS` environment variable to control resource-specific behaviors during export and deployment operations. This allows you to customize how certain resources handle dependencies.

#### Configuring Resource Settings

The `M365DSC_RESOURCE_SETTINGS` environment variable accepts a JSON array of key-value pairs:

```PowerShell
# Example: Configure AADUser to skip group membership management
$resourceSettings = @(
    @{ AADUserApplyMemberOf = $false }
) | ConvertTo-Json -Compress

[System.Environment]::SetEnvironmentVariable('M365DSC_RESOURCE_SETTINGS', $resourceSettings, 'Machine')
```

#### AADUserApplyMemberOf

The **AADUserApplyMemberOf** setting controls whether the AADUser resource should manage group memberships during export and deployment:

- **AADUserApplyMemberOf = $true** (default): The AADUser resource will include and manage the MemberOf property, making group memberships part of the user configuration
- **AADUserApplyMemberOf = $false**: The AADUser resource will ignore group memberships, allowing groups to be deployed separately

**Recommended approach for cloning tenants:**

```PowerShell
# Step 1: Configure the setting to skip group memberships in AADUser
$resourceSettings = @(
    @{ AADUserApplyMemberOf = $false }
) | ConvertTo-Json -Compress

[System.Environment]::SetEnvironmentVariable('M365DSC_RESOURCE_SETTINGS', $resourceSettings, 'Machine')

# Step 2: Export the source tenant configuration
$SourceCredential = Get-Credential
Export-M365DSCConfiguration -Components "AADUser" -Credential $SourceCredential -Path C:\Dsc -FileName M365TenantConfig_Users.ps1
Export-M365DSCConfiguration -Components "AADGroup" -Credential $SourceCredential -Path C:\Dsc -FileName M365TenantConfig_Groups.ps1

# Step 3: Deploy to target tenant
# Users will be created first without attempting to manage memberships via AADUser
$TargetCredential = Get-Credential
C:\Dsc\M365TenantConfig_Users.ps1 -Credential $TargetCredential
Start-DscConfiguration -Path C:\Dsc\M365TenantConfig_Users -Wait -Verbose

# Afterwards, we deploy the AADGroups, which will then manage the members
C:\Dsc\M365TenantConfig_Groups.ps1 -Credential $TargetCredential
Start-DscConfiguration -Path C:\Dsc\M365TenantConfig_Groups -Wait -Verbose
```

#### Retrieving Current Resource Settings

The cmdlet to get the current resource settings is intended for internal use only, but you can still check the configured settings for your session like the following:

```PowerShell
# Import the Microsoft365DSC module
Import-Module Microsoft365DSC

# Get current resource settings
Get-M365DSCResourceSettings
```

This will return a hashtable with all configured settings, including their current values. Be aware that since it's an internal cmdlet, it's usage and handling may change.

#### Best Practices for Managing Dependencies

1. **Plan your deployment order**: Export and deploy resources in logical groups (e.g., users before groups (or rather members before their groups), policies before assignments)
2. **Use resource settings**: Configure appropriate settings to avoid circular dependencies during cloning
3. **Test incrementally**: When cloning complex configurations, test with small subsets of resources first
4. **Review exported configurations**: Check the generated configuration files to ensure dependencies are properly handled
