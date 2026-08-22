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
        AADUser 'ConfigureJohnSMith'
        {
            UserPrincipalName  = "John.Smith@$TenantId"
            FirstName          = "John"
            LastName           = "Smith"
            DisplayName        = "John J. Smith"
            City               = "Gatineau"
            Country            = "Canada"
            Office             = "Ottawa - Queen"
            UsageLocation      = "US"
            AccountEnabled     = $true
            Department         = "Human Resources"
            Title              = "Senior Program Manager"
            StreetAddress      = "100 Rue Principale"
            State              = "Quebec"
            PostalCode         = "K1A 0B1"
            PhoneNumber        = "+1 613 555 0100"
            MobilePhone        = "+1 613 555 0177"
            Fax                = "+1 613 555 0143"
            OtherMails         = @("john.smith.contoso@outlook.com")
            PreferredLanguage  = "en-US"
            PasswordPolicies   = "DisablePasswordExpiration"
            UserType           = "Member"
            Ensure             = "Present"
            ApplicationId         = $ApplicationId
            TenantId              = $TenantId
            CertificateThumbprint = $CertificateThumbprint
        }
    }
}
