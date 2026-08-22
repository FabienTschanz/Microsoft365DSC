<#
This example creates a new Intune Device Features Configuration Policy for IOS.
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
        IntuneDeviceFeaturesConfigurationPolicyIOS "IntuneDeviceFeaturesConfigurationPolicyIOS-FakeStringValue"
        {
            DisplayName              = "FakeStringValue";
            ApplicationId            = $ApplicationId;
            TenantId                 = $TenantId;
            CertificateThumbprint    = $CertificateThumbprint;
            Ensure                   = 'Absent'
        }
    }
}
