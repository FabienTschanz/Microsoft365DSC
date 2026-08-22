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
        ADOPermissionGroup "ADOPermissionGroup-Example"
        {
            ApplicationId         = $ApplicationId;
            CertificateThumbprint = $CertificateThumbprint;
            Description           = "My Description";
            DisplayName           = "ProjectAdministrators";
            Ensure                = "Absent";
            Level                 = "Organization";
            Members               = @("AdeleV@$TenantId");
            OrganizationName      = "Contoso-Dev";
            PrincipalName         = "[CONTOSO-DEV]\ProjectAdministrators";
            TenantId              = $TenantId;
        }
    }
}
