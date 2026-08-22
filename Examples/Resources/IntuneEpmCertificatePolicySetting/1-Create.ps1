<#
This example creates a new Intune Firewall Policy for Windows10.
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
        IntuneEpmCertificatePolicySetting "IntuneEpmCertificatePolicySetting-Example"
        {
            Description           = "";
            DisplayName           = "IntuneEpmCertificatePolicySetting_1";
            Ensure                = "Present";
            CertificateFile       = "<base64-encoded-certificate>";
            ApplicationId         = $ApplicationId;
            TenantId              = $TenantId;
            CertificateThumbprint = $CertificateThumbprint;
        }
    }
}
