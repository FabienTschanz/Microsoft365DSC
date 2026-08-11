@{
    # DSC engine bundled under Modules/Microsoft365DSC/Dependencies/PSDesiredStateConfiguration/<version>.
    # Release pipelines download this version from the engine repository. Local builds may
    # copy a development checkout instead (see New-M365DSCDscSchemaCache.ps1 resolution order).
    ModuleName      = 'PSDesiredStateConfiguration'
    RequiredVersion = '3.1.0'
    RequiredTag     = 'M365DSCFastHost'
    Repository      = 'https://github.com/Microsoft365DSC/PSDesiredStateConfiguration'
}
