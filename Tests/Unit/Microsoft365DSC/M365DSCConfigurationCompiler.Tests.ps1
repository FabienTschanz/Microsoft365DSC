BeforeAll {
    $script:ModulesRoot = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) 'Modules\Microsoft365DSC\Modules' -Resolve
    $script:CompilerText = [System.IO.File]::ReadAllText((Join-Path $script:ModulesRoot 'M365DSCConfigurationCompiler.psm1'))
    $script:ReverseText = [System.IO.File]::ReadAllText((Join-Path $script:ModulesRoot 'M365DSCReverse.psm1'))
}

Describe 'Fast compile host contract' {
    It 'the compiler wrapper uses the PSDscFastCompileActive recursion guard' {
        $script:CompilerText | Should -Match '\$Global:PSDscFastCompileActive'
    }

    It 'the export trailer emits the PSDscFastCompileActive recursion guard' {
        $script:ReverseText | Should -Match 'PSDscFastCompileActive'
    }

    It 'the export trailer emits a fallback to the plain configuration invocation' {
        $script:ReverseText | Should -Match 'Build-M365DSCConfiguration -Path'
    }

    It 'the wrapper probes for the M365DSCFastHost engine tag' {
        $script:CompilerText | Should -Match 'M365DSCFastHost'
    }
}
