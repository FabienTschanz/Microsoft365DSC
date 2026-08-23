<#
This examples sets the Teams Federation Configuration.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $Credscredential
    )

    Import-DscResource -ModuleName Microsoft365DSC

    Node localhost
    {
        TeamsFederationConfiguration 'TeamsFederationConfiguration-Example'
        {
            IsSingleInstance                            = 'Yes';
            AllowedDomains                              = @();
            AllowedTrialTenantDomains                   = @("northwindtraders.onmicrosoft.com");
            BlockedDomains                              = @();
            BlockAllSubdomains                          = $false;
            AllowFederatedUsers                         = $true;
            AllowTeamsConsumer                          = $true;
            AllowTeamsConsumerInbound                   = $true;
            DomainBlockingForMDOAdminsInTeams           = "Enabled";
            ExternalAccessWithTrialTenants              = "Blocked";
            RestrictTeamsConsumerToExternalUserProfiles = $false;
            SharedSipAddressSpace                       = $false;
            TreatDiscoveredPartnersAsUnverified         = $false;
            Credential                                  = $Credscredential
        }
    }
}
