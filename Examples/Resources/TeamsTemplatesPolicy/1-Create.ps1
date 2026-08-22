<#
This example adds a new Teams Calling Policy.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $credsTeamsAdmin
    )

    Import-DscResource -ModuleName Microsoft365DSC

    Node localhost
    {
        TeamsTemplatesPolicy "TeamsTemplatesPolicy-Example"
        {
            Credential      = $credsTeamsAdmin;
            Description     = "Hides the templates that are not approved for use";
            Ensure          = "Present";
            HiddenTemplates = @("Manage a Project","Manage an Event","Adopt Office 365","Organize Help Desk");
            Identity        = "Approved Templates";
        }
    }
}
