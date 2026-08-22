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
            ApplySensitivityLabel = "TopSecret";
            Comment               = "Applies the Top Secret label to Exchange and SharePoint content automatically"; # Updated property
            Credential            = $Credscredential;
            Ensure                = "Present";
            ExchangeLocation      = @("All");
            Mode                  = "Enable";
            Name                  = "Top Secret Auto-labeling";
            Priority              = 0;
        }
    }
}
