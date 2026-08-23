<#
This example is used to test new resources and showcase the usage of new resources being worked on.
It is not meant to use as a production baseline.
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
        SCAutoSensitivityLabelPolicy 'SCAutoSensitivityLabelPolicy-Example'
        {
            ApplySensitivityLabel           = "Confidential";
            Comment                         = "Applies the Top Secret label to finance content and is reviewed quarterly by the compliance team"; # Updated Property
            Credential                      = $Credscredential;
            Ensure                          = "Present";
            ExchangeLocation                = @("All");
            ExchangeSender                  = @("finance.director@contoso.com");
            ExchangeSenderException         = @("newsletters@contoso.com");
            ExchangeSenderMemberOf          = @("finance-team@contoso.com");
            ExchangeSenderMemberOfException = @("finance-contractors@contoso.com");
            Mode                            = "TestWithoutNotifications";
            Name                            = "Top Secret Auto-labeling";
            OneDriveLocation                = @("All");
            OneDriveLocationException       = @("https://contoso-my.sharepoint.com/personal/reporting_service_contoso_com");
            Priority                        = 0;
            SharePointLocation              = @("All");
            SharePointLocationException     = @("https://contoso.sharepoint.com/sites/PublicRelations");
        }
    }
}
