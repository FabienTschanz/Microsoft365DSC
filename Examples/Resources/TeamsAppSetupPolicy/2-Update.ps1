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
        TeamsAppSetupPolicy "TeamsAppSetupPolicy-Example"
        {
            AllowSideLoading = $True;
            AllowUserPinning = $True;
            AppPresetList    = "com.microsoft.teamspace.tab.vsts";
            Credential       = $Credscredential;
            Description      = "Pins the core apps for frontline staff";
            Ensure           = "Present";
            Identity         = "Frontline App Setup";
            PinnedAppBarApps = @("2a84919f-59d8-4441-a975-2a8c2643b741"); # Updated property
        }
    }
}
