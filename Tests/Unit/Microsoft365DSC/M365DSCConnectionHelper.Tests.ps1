BeforeAll {
    Import-Module "$PSScriptRoot/../../../Modules/Microsoft365DSC/Modules/M365DSCDllLoader.psm1" -Force -Global
    Initialize-M365DSCDllLoader

    $Script:AllAuthenticationMethods = @(
        'ApplicationWithSecret'
        'CertificateThumbprint'
        'CertificatePath'
        'Credentials'
        'CredentialsWithTenantId'
        'CredentialsWithApplicationId'
        'ManagedIdentity'
        'AccessTokens'
    )

    $Script:TestResources = @('GraphThing', 'ExoThing', 'SPOThing', 'MinimalThing', 'NotAResource')

    function New-TestResourceModule
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory = $true)]
            [System.String]
            $Path
        )

        $content = @'
[DscResource()]
class GraphThing
{
    [DscProperty(Key)] [System.String] $Id
    [DscProperty()] [System.Management.Automation.PSCredential] $Credential
    [DscProperty()] [System.String] $ApplicationId
    [DscProperty()] [System.String] $TenantId
    [DscProperty()] [System.Management.Automation.PSCredential] $ApplicationSecret
    [DscProperty()] [System.String] $CertificateThumbprint
    [DscProperty()] [System.Management.Automation.PSCredential] $CertificatePassword
    [DscProperty()] [System.String] $CertificatePath
    [DscProperty()] [System.Nullable[System.Boolean]] $ManagedIdentity
    [DscProperty()] [System.String[]] $AccessTokens
    [System.String] $Filter
}

[DscResource()]
class ExoThing
{
    [DscProperty(Key)] [System.String] $Id
    [DscProperty()] [System.Management.Automation.PSCredential] $Credential
    [DscProperty()] [System.String] $ApplicationId
    [DscProperty()] [System.String] $TenantId
    [DscProperty()] [System.String] $CertificateThumbprint
    [DscProperty()] [System.Nullable[System.Boolean]] $ManagedIdentity
    [DscProperty()] [System.String[]] $AccessTokens
}

[DscResource()]
class SPOThing
{
    [DscProperty(Key)] [System.String] $Id
    [DscProperty()] [System.Management.Automation.PSCredential] $Credential
    [DscProperty()] [System.String] $ApplicationId
    [DscProperty()] [System.String] $TenantId
    [DscProperty()] [System.String[]] $AccessTokens
}

[DscResource()]
class MinimalThing
{
    [DscProperty(Key)] [System.String] $Id
    [DscProperty()] [System.String[]] $AccessTokens
}

[DscResource()]
class NotSelected
{
    [DscProperty(Key)] [System.String] $Id
    [DscProperty()] [System.String] $ApplicationId
    [DscProperty()] [System.String] $TenantId
    [DscProperty()] [System.String] $CertificateThumbprint
}

class NotAResource
{
    [DscProperty()] [System.String] $ApplicationId
    [DscProperty()] [System.String] $TenantId
    [DscProperty()] [System.String] $CertificateThumbprint
}
'@

        Set-Content -Path $Path -Value $content -Encoding UTF8
    }

    function Get-TestAuthenticationMethod
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory = $true)]
            [System.String]
            $Path,

            [Parameter(Mandatory = $true)]
            [System.String]
            $ResourceName,

            [Parameter()]
            [System.String[]]
            $AuthenticationMethod = $Script:AllAuthenticationMethods
        )

        $components = [Microsoft365DSC.Connection.ConnectionHelper]::GetComponentsWithMostSecureAuthenticationType(
            $Path,
            $AuthenticationMethod,
            $Script:TestResources
        )

        return ($components | Where-Object -FilterScript { $_.Resource -eq $ResourceName }).AuthMethod
    }
}

Describe 'Utilities.GetDscResourcePropertyNamesByAST' {
    BeforeAll {
        $Script:ModulePath = Join-Path -Path $TestDrive -ChildPath 'Part00.psm1'
        New-TestResourceModule -Path $Script:ModulePath
        $Script:Parsed = [Microsoft365DSC.Utilities.Utilities]::GetDscResourcePropertyNamesByAST($Script:ModulePath)
    }

    It 'Returns every class carrying a DscResource attribute' {
        $Script:Parsed.Keys | Sort-Object | Should -Be @('ExoThing', 'GraphThing', 'MinimalThing', 'NotSelected', 'SPOThing')
    }

    It 'Skips classes without a DscResource attribute' {
        $Script:Parsed.ContainsKey('NotAResource') | Should -BeFalse
    }

    It 'Returns the DscProperty members of a resource' {
        $Script:Parsed['MinimalThing'] | Should -Be @('Id', 'AccessTokens')
    }

    It 'Skips members that are not declared as a DscProperty' {
        $Script:Parsed['GraphThing'] | Should -Not -Contain 'Filter'
    }
}

Describe 'ConnectionHelper.GetComponentsWithMostSecureAuthenticationType' {
    BeforeAll {
        $Script:ResourcePath = Join-Path -Path $TestDrive -ChildPath 'Resources'
        New-Item -Path $Script:ResourcePath -ItemType Directory | Out-Null
        New-TestResourceModule -Path (Join-Path -Path $Script:ResourcePath -ChildPath 'Part00.psm1')
    }

    It 'Prefers the certificate thumbprint over every other method' {
        Get-TestAuthenticationMethod -Path $Script:ResourcePath -ResourceName 'GraphThing' | Should -Be 'CertificateThumbprint'
    }

    It 'Falls back to the application secret when no certificate method is requested' {
        Get-TestAuthenticationMethod -Path $Script:ResourcePath -ResourceName 'GraphThing' `
            -AuthenticationMethod @('ApplicationWithSecret', 'Credentials') | Should -Be 'ApplicationSecret'
    }

    It 'Skips the application secret for a resource that does not declare one' {
        Get-TestAuthenticationMethod -Path $Script:ResourcePath -ResourceName 'ExoThing' `
            -AuthenticationMethod @('ApplicationWithSecret', 'Credentials') | Should -Be 'Credentials'
    }

    It 'Excludes SPO resources from CredentialsWithTenantId' {
        Get-TestAuthenticationMethod -Path $Script:ResourcePath -ResourceName 'SPOThing' `
            -AuthenticationMethod @('CredentialsWithTenantId', 'Credentials') | Should -Be 'Credentials'
    }

    It 'Returns CredentialsWithTenantId for a resource without an SPO, OD or PP prefix' {
        Get-TestAuthenticationMethod -Path $Script:ResourcePath -ResourceName 'ExoThing' `
            -AuthenticationMethod @('CredentialsWithTenantId', 'Credentials') | Should -Be 'CredentialsWithTenantId'
    }

    It 'Returns the access tokens when the resource declares nothing else' {
        Get-TestAuthenticationMethod -Path $Script:ResourcePath -ResourceName 'MinimalThing' | Should -Be 'AccessTokens'
    }

    It 'Ignores resources that were not requested' {
        $components = [Microsoft365DSC.Connection.ConnectionHelper]::GetComponentsWithMostSecureAuthenticationType(
            $Script:ResourcePath,
            $Script:AllAuthenticationMethods,
            $Script:TestResources
        )
        $components.Resource | Should -Not -Contain 'NotSelected'
    }

    It 'Ignores classes without a DscResource attribute' {
        $components = [Microsoft365DSC.Connection.ConnectionHelper]::GetComponentsWithMostSecureAuthenticationType(
            $Script:ResourcePath,
            $Script:AllAuthenticationMethods,
            $Script:TestResources
        )
        $components.Resource | Should -Not -Contain 'NotAResource'
    }

    It 'Finds resources declared across several module files' {
        $multiPath = Join-Path -Path $TestDrive -ChildPath 'MultiFile'
        New-Item -Path $multiPath -ItemType Directory | Out-Null
        Set-Content -Path (Join-Path -Path $multiPath -ChildPath 'Part00.psm1') -Encoding UTF8 -Value @'
[DscResource()]
class GraphThing
{
    [DscProperty(Key)] [System.String] $Id
    [DscProperty()] [System.String] $ApplicationId
    [DscProperty()] [System.String] $TenantId
    [DscProperty()] [System.String] $CertificateThumbprint
}
'@
        Set-Content -Path (Join-Path -Path $multiPath -ChildPath 'Part01.psm1') -Encoding UTF8 -Value @'
[DscResource()]
class MinimalThing
{
    [DscProperty(Key)] [System.String] $Id
    [DscProperty()] [System.String[]] $AccessTokens
}
'@
        $components = [Microsoft365DSC.Connection.ConnectionHelper]::GetComponentsWithMostSecureAuthenticationType(
            $multiPath,
            $Script:AllAuthenticationMethods,
            $Script:TestResources
        )
        $components.Count | Should -Be 2
        ($components | Where-Object -FilterScript { $_.Resource -eq 'GraphThing' }).AuthMethod | Should -Be 'CertificateThumbprint'
        ($components | Where-Object -FilterScript { $_.Resource -eq 'MinimalThing' }).AuthMethod | Should -Be 'AccessTokens'
    }

    It 'Throws when the resource modules folder does not exist' {
        {
            [Microsoft365DSC.Connection.ConnectionHelper]::GetComponentsWithMostSecureAuthenticationType(
                (Join-Path -Path $TestDrive -ChildPath 'DoesNotExist'),
                $Script:AllAuthenticationMethods,
                $Script:TestResources
            )
        } | Should -Throw -ExceptionType ([System.Management.Automation.MethodInvocationException])
    }
}
