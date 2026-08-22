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
        SentinelAlertRule "SentinelAlertRule-Example"
        {
            AlertDetailsOverride  = MSFT_SentinelAlertRuleAlertDetailsOverride{
                alertDescriptionFormat = 'A cloud application was accessed from an unrecognised location.'
                alertDisplayNameFormat = 'Alert from {{{TimeGenerated}} '
            };
            ApplicationId         = $ApplicationId;
            CertificateThumbprint = $CertificateThumbprint;
            CustomDetails         = @(
                MSFT_SentinelAlertRuleCustomDetails{
                    DetailKey   = 'Color'
                    DetailValue = 'TenantId'
                }
            );
            Description           = "Raises an incident when a cloud application is accessed from an unrecognised location";
            DisplayName           = "MyNRTRule";
            Enabled               = $True;
            Ensure                = "Present";
            EntityMappings        = @(
                MSFT_SentinelAlertRuleEntityMapping{
                    fieldMappings = @(
                        MSFT_SentinelAlertRuleEntityMappingFieldMapping{
                            identifier = 'AppId'
                            columnName = 'Id'
                        }
                    )
                    entityType    = 'CloudApplication'
                }
            );
            IncidentConfiguration = MSFT_SentinelAlertRuleIncidentConfiguration{
                groupingConfiguration = MSFT_SentinelAlertRuleIncidentConfigurationGroupingConfiguration{
                    lookbackDuration     = 'PT5H'
                    matchingMethod       = 'Selected'
                    groupByCustomDetails = @('Color')
                    groupByEntities      = @('CloudApplication')
                    reopenClosedIncident = $True
                    enabled              = $True
                }
                            createIncident        = $True
            };
            Query                 = "ThreatIntelIndicators";
            ResourceGroupName     = "ResourceGroupName";
            Severity              = "Medium";
            SubscriptionId        = "<subscription-id>";
            SuppressionDuration   = "PT5H";
            Tactics               = @();
            Techniques            = @();
            TenantId              = $TenantId;
            WorkspaceName         = "SentinelWorkspace";
        }
    }
}
