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
        TeamsFilesPolicy 'TeamsFilesPolicy-Example'
        {
            Credential                          = $Credscredential;
            DefaultFileUploadAppId              = "<teams-app-id>";
            Ensure                              = "Present";
            FileSharingInChatswithExternalUsers = "Enabled";
            Identity                            = "Retail Store Files";
            NativeFileEntryPoints               = "Enabled";
            SPChannelFilesTab                   = "Enabled";
        }
    }
}
