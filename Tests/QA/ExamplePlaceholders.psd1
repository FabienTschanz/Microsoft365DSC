@{
    Placeholders = @(
        @{
            Name       = '<api-password>'
            Meaning    = 'Password of the account the API connector authenticates with.'
            Sample     = 'S3cur3P@ssw0rd!'
            Properties = @('Password')
        }
        @{
            Name       = '<apple-push-certificate>'
            Meaning    = 'Base64 Apple MDM push notification certificate.'
            Sample     = 'MIIFdjCCBF6gAwIBAgIIMVIk4qQ3QnQwDQYJKoZIhvcNAQELBQAwgYwxQDA+BgNVBAMMN0FwcGxlIEFwcGxpY2F0aW9u...'
            Properties = @('Certificate')
        }
        @{
            Name       = '<apple-push-certificate-updated>'
            Meaning    = 'Renewed Apple MDM push notification certificate.'
            Sample     = 'MIIFdjCCBF6gAwIBAgIIRnE2p1TgVkYwDQYJKoZIhvcNAQELBQAwgYwxQDA+BgNVBAMMN0FwcGxlIEFwcGxpY2F0aW9u...'
            Properties = @('Certificate')
        }
        @{
            Name       = '<application-id>'
            Meaning    = 'Application (client) ID of an Entra application registration.'
            Sample     = 'e35c54ff-bd24-4c52-921a-4b90a35808eb'
            Properties = @('AppId')
        }
        @{
            Name       = '<application-id-updated>'
            Meaning    = 'Application (client) ID the update example switches to.'
            Sample     = 'c1a3d8f2-5b47-4e19-9f0a-2d6b8e4c7a35'
            Properties = @('AppId')
        }
        @{
            Name       = '<base64-encoded-certificate>'
            Meaning    = 'Base64 public certificate.'
            Sample     = 'MIIDPzCCAiegAwIBAgIQPbcHnHzTkKtCj4d0eOR7QDANBgkqhkiG9w0BAQsFADAg...'
            Properties = @('Certificate', 'CertificateFile')
        }
        @{
            Name       = '<base64-encoded-certificate-2>'
            Meaning    = 'Second base64 public certificate, where a property takes more than one.'
            Sample     = 'MIIDQzCCAiugAwIBAgIRAJkLmW2sVqT8Xh1FbN4pRc0wDQYJKoZIhvcNAQELBQAw...'
            Properties = @('Certificate')
        }
        @{
            Name       = '<base64-encoded-signing-certificate>'
            Meaning    = 'Base64 token-signing certificate of the federated identity provider.'
            Sample     = 'MIIDdzCCAl+gAwIBAgIQXWWjEQHsCgAAAABBAgAAYDANBgkqhkiG9w0BAQsFADA3...'
            Properties = @('SigningCertificate')
        }
        @{
            Name       = '<base64-encoded-next-signing-certificate>'
            Meaning    = 'Base64 signing certificate staged for the next rollover.'
            Sample     = 'MIIDdzCCAl+gAwIBAgIQYZZkFRHsCgAAAABBAgAAYDANBgkqhkiG9w0BAQsFADA3...'
            Properties = @('NextSigningCertificate')
        }
        @{
            Name       = '<base64-encoded-root-certificate>'
            Meaning    = 'Base64 trusted root certificate.'
            Sample     = 'MIIEEjCCAvqgAwIBAgIPAMEAizw8iBHRPvZj7N9AMA0GCSqGSIb3DQEBBAUAMHAx...'
            Properties = @('TrustedRootCertificate')
        }
        @{
            Name       = '<certificate-thumbprint>'
            Meaning    = 'Thumbprint of a certificate installed on the machine running the configuration.'
            Sample     = 'ABCDEF1234567890ABCDEF1234567890ABCDEF12'
            Properties = @('CertificateThumbprint')
        }
        @{
            Name       = '<client-id>'
            Meaning    = 'Client ID issued by an external identity provider.'
            Sample     = '7698a352-4939-486e-9974-4ea5aff93f74'
            Properties = @('clientId')
        }
        @{
            Name       = '<client-secret>'
            Meaning    = 'Client secret issued by an external identity provider.'
            Sample     = 'aBc8Q~vR2pLmXaHt9_ZyXwVu1TsRqPoN3MlKjIhG'
            Properties = @('ClientSecret')
        }
        @{
            Name       = '<client-secret-updated>'
            Meaning    = 'Rotated client secret, so the update example differs from the create example.'
            Sample     = 'dEf4W~kTn7QbYcRz2_XvUtSrQpOnMlKjIhGfEdCb'
            Properties = @('ClientSecret')
        }
        @{
            Name       = '<event-hub-authorization-rule-id>'
            Meaning    = 'Resource ID of the Event Hub authorization rule that receives the diagnostic stream.'
            Sample     = '/subscriptions/63e62ab2-fd92-46ce-a393-2cb338039cc7/resourceGroups/monitoring/providers/Microsoft.EventHub/namespaces/contoso-hub/authorizationRules/RootManageSharedAccessKey'
            Properties = @('EventHubAuthorizationRuleId')
        }
        @{
            Name       = '<key-vault-key-uri>'
            Meaning    = 'Full URI of a key in Azure Key Vault, including the key version.'
            Sample     = 'https://contoso-eastus-kv.vault.azure.net/keys/MailboxKey01/4a1e9c8b7d6f4a2b9c3d5e7f1a2b3c4d'
            Properties = @('AzureKeyIDs')
        }
        @{
            Name       = '<key-vault-uri>'
            Meaning    = 'Base URI of an Azure Key Vault.'
            Sample     = 'https://contoso-eastus-kv.vault.azure.net/'
            Properties = @('ResourceUrl')
        }
        @{
            Name       = '<log-analytics-workspace-resource-id>'
            Meaning    = 'Resource ID of the Log Analytics workspace that receives the diagnostic stream.'
            Sample     = '/subscriptions/63e62ab2-fd92-46ce-a393-2cb338039cc7/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/contoso-logs'
            Properties = @('WorkspaceId')
        }
        @{
            Name       = '<mobile-app-id>'
            Meaning    = 'ID of a mobile app already published in the tenant.'
            Sample     = '2f8b6f0a-1c3d-4e5f-9a8b-7c6d5e4f3a2b'
            Properties = @('TargetedMobileApps')
        }
        @{
            Name       = '<onboarding-blob>'
            Meaning    = 'Defender for Endpoint onboarding blob, taken from the Defender portal.'
            Sample     = '<EncryptedMessage xmlns="http://schemas.datacontract.org/2004/07/Microsoft.Management.Services.Common.Cryptography">...</EncryptedMessage>'
            Properties = @('AdvancedThreatProtectionOnboardingBlob')
        }
        @{
            Name       = '<storage-account-resource-id>'
            Meaning    = 'Resource ID of the storage account that receives the diagnostic stream.'
            Sample     = '/subscriptions/63e62ab2-fd92-46ce-a393-2cb338039cc7/resourceGroups/monitoring/providers/Microsoft.Storage/storageAccounts/contosodiagnostics'
            Properties = @('StorageAccountId')
        }
        @{
            Name       = '<subscription-id>'
            Meaning    = 'ID of the Azure subscription the resource lives in.'
            Sample     = '63e62ab2-fd92-46ce-a393-2cb338039cc7'
            Properties = @('SubscriptionId')
        }
        @{
            Name       = '<subscription-scope>'
            Meaning    = 'Scope a role definition is assignable at.'
            Sample     = '/subscriptions/63e62ab2-fd92-46ce-a393-2cb338039cc7'
            Properties = @('AssignableScopes')
        }
    )
}
