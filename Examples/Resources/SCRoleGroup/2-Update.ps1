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
        SCRoleGroup 'SCRoleGroup-Example'
        {
            Name        = "Contoso Role Group"
            Description = "Address Lists Role for Purview Administrators - Modified"
            Roles       = @("Address Lists")
            Ensure      = "Present"
            Credential  = $Credscredential
        }
    }
}
