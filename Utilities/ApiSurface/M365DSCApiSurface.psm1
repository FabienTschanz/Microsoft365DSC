<#
    Loader for the Microsoft365DSC API surface module.

    All logic lives in Public/ and Private/. This file only dot-sources those scripts so that
    every function shares the module's session state. Only the public functions are exported
    (see the manifest). Everything under Private/ is an implementation detail.
#>

$scriptFiles = @(
    Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private') -Filter '*.ps1' -Recurse -File
    Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Filter '*.ps1' -File
)

foreach ($scriptFile in $scriptFiles)
{
    . $scriptFile.FullName
}

Export-ModuleMember -Function 'Get-M365DSCApiSurface'
