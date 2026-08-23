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
        SCInsiderRiskEntityList "SCInsiderRiskEntityList-Example"
        {
            ApplicationId         = $ApplicationId;
            CertificateThumbprint = $CertificateThumbprint;
            Description           = "Executable file types monitored for insider risk";
            DisplayName           = "MyFileType";
            Ensure                = "Present";
            FileTypes             = @(".exe",".txt",".bat"); # Updated Property
            Keywords              = @();
            ListType              = "CustomFileTypeLists";
            Name                  = "MyFileTypeList";
            TenantId              = $OrganizationName;
        }
    }
}
