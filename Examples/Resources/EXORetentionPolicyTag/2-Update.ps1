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
        EXORetentionPolicyTag "EXORetentionPolicyTag-Example"
        {
            ApplicationId             = $ApplicationId;
            CertificateThumbprint     = $CertificateThumbprint;
            Comment                   = "This is my modified tag"; #Drift
            Ensure                    = "Present";
            Identity                  = "MyTag";
            MessageClass              = "*";
            MustDisplayCommentEnabled = $False;
            RetentionAction           = "MoveToArchive";
            RetentionEnabled          = $False;
            TenantId                  = $TenantId;
            Type                      = "Personal";
        }
    }
}
