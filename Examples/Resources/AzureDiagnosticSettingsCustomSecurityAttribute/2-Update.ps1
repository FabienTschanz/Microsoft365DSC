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
        AzureDiagnosticSettingsCustomSecurityAttribute "AzureDiagnosticSettingsCustomSecurityAttribute-Example"
        {
            ApplicationId               = $ApplicationId;
            Categories                  = @(
                MSFT_AzureDiagnosticSettingsCustomSecurityAttributeCategory{
                    category = 'CustomSecurityAttributeAuditLogs'
                    enabled  = $False # Updated Property
                }
            );
            CertificateThumbprint       = $CertificateThumbprint;
            Ensure                      = "Present";
            EventHubAuthorizationRuleId = "<event-hub-authorization-rule-id>";
            EventHubName                = "";
            Name                        = "MyAttribute";
            StorageAccountId            = "<storage-account-resource-id>";
            TenantId                    = $TenantId;
            WorkspaceId                 = "<log-analytics-workspace-resource-id>";
        }
    }
}
