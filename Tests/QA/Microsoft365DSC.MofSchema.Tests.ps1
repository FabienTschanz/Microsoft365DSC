<#
.SYNOPSIS
    Validates the EmbeddedInstance references of every resource's MOF schema file.

.DESCRIPTION
    A MOF schema file has to be self contained: every CIM class that is referenced through an
    EmbeddedInstance qualifier must be declared in the same file, since the DSC engine cannot
    resolve a class that is declared in the schema file of another resource.

    For each *.schema.mof file, two checks are generated:

    1. Every class referenced by an EmbeddedInstance qualifier is declared in the same file. A
       missing declaration means the resource cannot be compiled.
    2. Every class declared in the file is actually used, either by an EmbeddedInstance qualifier
       or as the base class of another declaration. An unused declaration is dead schema, and
       usually means that the property meant to use it is missing its EmbeddedInstance qualifier.

    Class names are compared case-insensitively, because MOF class names are case-insensitive and
    the schema files are not consistent about their casing.
#>

BeforeDiscovery {
    $resourcesPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/Microsoft365DSC/DscResources'
    $schemaFiles = Get-ChildItem -Path $resourcesPath -Filter '*.schema.mof' -Recurse | ForEach-Object {
        @{
            ResourceName = $_.Directory.Name
            FullName     = $_.FullName
        }
    }
}

BeforeAll {
    function Get-MofSchemaClassInfo
    {
        <#
        .SYNOPSIS
            Returns the declared classes and the class references of a MOF schema file.

        .PARAMETER FileName
            Specifies the path of the *.schema.mof file to analyze.
        #>
        [CmdletBinding()]
        [OutputType([System.Collections.Hashtable])]
        param
        (
            [Parameter(Mandatory = $true)]
            [System.String]
            $FileName
        )

        $content = Get-Content -Path $FileName -Raw

        # Only match declarations at the start of a line and skip commented out ones. The content of
        # the Description qualifiers is not stripped, since it regularly contains URLs which would
        # be mangled by a naive comment removal.
        $classMatches = [regex]::Matches($content, '(?im)^(?!\s*//)\s*class\s+(?<name>\w+)\s*(?::\s*(?<baseClass>\w+))?')
        $embeddedMatches = [regex]::Matches($content, '(?i)EmbeddedInstance\s*\(\s*"(?<name>[^"]+)"\s*\)')

        $declaredClasses = @()
        $baseClasses = @()
        foreach ($classMatch in $classMatches)
        {
            $declaredClasses += @{
                Name      = $classMatch.Groups['name'].Value
                BaseClass = $classMatch.Groups['baseClass'].Value
                Line      = ($content.Substring(0, $classMatch.Index) -split '\r?\n').Count
            }

            if ($classMatch.Groups['baseClass'].Success)
            {
                $baseClasses += $classMatch.Groups['baseClass'].Value
            }
        }

        $embeddedReferences = @()
        foreach ($embeddedMatch in $embeddedMatches)
        {
            $embeddedReferences += @{
                Name = $embeddedMatch.Groups['name'].Value
                Line = ($content.Substring(0, $embeddedMatch.Index) -split '\r?\n').Count
            }
        }

        return @{
            DeclaredClasses    = $declaredClasses
            EmbeddedReferences = $embeddedReferences
            BaseClasses        = $baseClasses
        }
    }
}

Describe -Name "MOF schema embedded instances for '<ResourceName>'" -ForEach $schemaFiles {
    BeforeAll {
        # Classes that are provided by the DSC engine itself and are therefore never declared in
        # the schema file of a resource.
        $externalClasses = @(
            'MSFT_Credential',
            'MSFT_KeyValuePair'
        )

        $schemaInfo = Get-MofSchemaClassInfo -FileName $FullName
        $declaredClassNames = @($schemaInfo.DeclaredClasses.Name)

        # The class carrying the name of the file is the resource itself, as is any class deriving
        # from OMI_BaseResource. Those are the entry points of the schema and are never referenced
        # by one of the other classes.
        $resourceClassName = (Split-Path -Path $FullName -Leaf) -replace '\.schema\.mof$', ''
        $entryPointClasses = @($schemaInfo.DeclaredClasses | Where-Object -FilterScript {
                $_.Name -eq $resourceClassName -or $_.BaseClass -eq 'OMI_BaseResource'
            } | ForEach-Object -Process { $_.Name })
    }

    It 'Should declare every class referenced by an EmbeddedInstance qualifier' {
        $undeclaredReferences = @($schemaInfo.EmbeddedReferences | Where-Object -FilterScript {
            $_.Name -notin $externalClasses -and $_.Name -notin $declaredClassNames
        })

        if ($undeclaredReferences.Count -gt 0)
        {
            $details = ($undeclaredReferences | ForEach-Object { "$($_.Name) (line $($_.Line))" } | Select-Object -Unique) -join ', '
            throw "The schema file of $ResourceName references the following embedded instances which are not declared in the file: $details."
        }
    }

    It 'Should reference every class declared in the schema file' {
        $referencedClassNames = @($schemaInfo.EmbeddedReferences.Name) + @($schemaInfo.BaseClasses)
        $unreferencedClasses = @($schemaInfo.DeclaredClasses | Where-Object -FilterScript {
            $_.Name -notin $entryPointClasses -and $_.Name -notin $referencedClassNames
        })

        if ($unreferencedClasses.Count -gt 0)
        {
            $details = ($unreferencedClasses | ForEach-Object { "$($_.Name) (line $($_.Line))" }) -join ', '
            throw "The schema file of $ResourceName declares the following classes which are never referenced by an EmbeddedInstance qualifier or used as a base class: $details."
        }
    }
}
