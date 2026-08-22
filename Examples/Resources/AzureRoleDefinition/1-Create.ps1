<#
This example is used to test new resources and showcase the usage of new resources being worked on.
It is not meant to use as a production baseline.
#>

Configuration Example
{
    param
    (
        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Import-DscResource -ModuleName Microsoft365DSC

    Node localhost
    {
        AzureRoleDefinition "AzureRoleDefinition-Example"
        {
            Actions               = @("Microsoft.Compute/virtualMachines/read","Microsoft.Compute/virtualMachines/start/action","Microsoft.Compute/virtualMachines/restart/action");
            ApplicationId         = $ApplicationId;
            AssignableScopes      = @("<subscription-scope>");
            CertificateThumbprint = $CertificateThumbprint;
            CustomRoleName        = "My Custom Role";
            Description           = "A custom role for managing virtual machines.";
            Ensure                = "Present";
            TenantId              = $TenantId;
        }
    }
}
