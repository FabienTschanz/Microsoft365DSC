<#
This example creates a new Intune Device Features Configuration Policy for IOS.
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
        IntuneDeviceFeaturesConfigurationPolicyIOS "IntuneDeviceFeaturesConfigurationPolicyIOS-Example"
        {
            ApplicationId            = $ApplicationId;
            TenantId                 = $TenantId;
            CertificateThumbprint    = $CertificateThumbprint;
            AirPrintDestinations     = @(
                MSFT_airPrintDestination{
                    port         = 0
                    resourcePath = 'printers/xerox_Phase'
                    forceTls     = $False
                    ipAddress    = '1.0.0.1'
                }
            );
            Assignments              = @();
            ContentFilterSettings    = @(
                MSFT_iosWebContentFilterSpecificWebsitesAccess{
                    allowedUrls = @('www.allowed.com')
                    dataType    = '#microsoft.graph.iosWebContentFilterAutoFilter'
                    blockedUrls = @('www.blocked.com')
                }
            );
            Description              = "Corporate iOS device features";
            DisplayName              = "Corporate iOS Device Features";
            Ensure                   = "Present";
            HomeScreenDockIcons      = @(
                MSFT_iosHomeScreenApp{
                    bundleID    = 'com.apple.store.Jolly'
                    displayName = 'Apple Store'
                    isWebClip   = $False
                }
            );
            HomeScreenPages          = @(
                MSFT_iosHomeScreenItem{
                    icons = @(
                        MSFT_iosHomeScreenApp{
                            bundleID    = 'com.apple.AppStore'
                            displayName = 'App Store'
                            isWebClip   = $False
                        }
                    )

                }
            );
            Id                       = "ab915bca-1234-4b11-8acb-719a771139bc";
            IosSingleSignOnExtension = @(
                MSFT_iosSingleSignOnExtension{
                    extensionIdentifier = 'com.example.sso.credential'
                    dataType            = '#microsoft.graph.iosCredentialSingleSignOnExtension'
                    domains             = @('example.com')
                    teamIdentifier      = '4HMSJJRMAD'
                    realm               = 'EXAMPLE.COM'
                }
            );
            NotificationSettings     = @(
                MSFT_iosNotificationSettings{
                    alertType                = 'banner'
                    enabled                  = $True
                    showOnLockScreen         = $True
                    badgesEnabled            = $True
                    soundsEnabled            = $True
                    publisher                = 'fakepublisher'
                    bundleID                 = 'app.id'
                    showInNotificationCenter = $True
                    previewVisibility        = 'hideWhenLocked'
                    appName                  = 'fakeapp'
                }
            );
            SingleSignOnSettings     = @(
                MSFT_iosSingleSignOnSettings{
                    allowedAppsList       = @(
                        MSFT_appListItem{
                            appId = 'com.microsoft.companyportal'
                            name  = 'Intune Company Portal'
                        }
                    )
                    allowedUrls           = @('https://sso.contoso.com')
                    kerberosRealm         = 'CONTOSO.COM'
                    displayName           = 'Contoso Single Sign-On'
                    kerberosPrincipalName = 'userPrincipalName'
                }
            );
            WallpaperDisplayLocation = "notConfigured";
        }
    }
}
