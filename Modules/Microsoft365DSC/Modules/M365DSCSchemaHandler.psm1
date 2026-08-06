<#
    .SYNOPSIS
        Removes // line comments from MOF content.

    .DESCRIPTION
        Schema files use // to comment out property definitions that must not be part of the
        schema, for example the circular reference guarded against in
        MSFT_AADServicePrincipal.schema.mof. Those lines are still valid property syntax, so
        the property regex happily matches them and emits a duplicate entry.

        A plain string replace cannot be used because // legitimately occurs inside quoted
        strings - nearly every property description carries an https:// documentation link -
        so quoting state is tracked while scanning.
#>
function Remove-M365DSCMofComment
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $Content
    )

    $result = [System.Text.StringBuilder]::new($Content.Length)

    foreach ($line in ($Content -split "`n"))
    {
        $inString = $false
        $commentStart = -1

        for ($i = 0; $i -lt $line.Length; $i++)
        {
            $character = $line[$i]

            if ($inString -and $character -eq '\')
            {
                # Skip the escaped character, e.g. \" inside a description.
                $i++
                continue
            }

            if ($character -eq '"')
            {
                $inString = -not $inString
                continue
            }

            if (-not $inString -and $character -eq '/' -and ($i + 1) -lt $line.Length -and $line[$i + 1] -eq '/')
            {
                $commentStart = $i
                break
            }
        }

        if ($commentStart -ge 0)
        {
            $line = $line.Substring(0, $commentStart)
        }

        [void] $result.AppendLine($line)
    }

    return $result.ToString()
}

function New-M365DSCSchemaDefinition
{
    [CmdletBinding()]
    param ()

    $schemaFiles = Get-ChildItem -Path './Modules/Microsoft365DSC/DscResources/*.schema.mof' -Recurse -File

    $classInfoList = @()
    $seenClasses = @{}

    foreach ($file in $schemaFiles)
    {
        $readMePath = "$($file.DirectoryName)/readme.md"
        $readMeContent = Get-Content $readMePath -Raw
        $resourceDescription = $readMeContent.Split('## Description')[1].Trim()

        Write-Verbose -Message $file.Name
        $mofContent = Remove-M365DSCMofComment -Content (Get-Content $file.FullName -Raw)

        # Match class definitions
        $classMatches = [regex]::Matches($mofContent, 'class\s+(\w+)(?:\s*:\s*\w+)?\s*(\{.*?\});', 'Singleline')

        foreach ($classMatch in $classMatches)
        {
            $className = $classMatch.Groups[1].Value
            $classBody = $classMatch.Groups[2].Value

            $normalizedBody = ($classBody -replace '\s+', ' ').Trim()

            if ($seenClasses.ContainsKey($className))
            {
                if ($seenClasses[$className].Body -ne $normalizedBody)
                {
                    Write-Warning -Message ("Class '{0}' is declared in both '{1}' and '{2}' with different definitions. Keeping the one from '{1}'." -f `
                            $className, $seenClasses[$className].File, $file.Name)
                }

                continue
            }

            $seenClasses[$className] = @{
                Body = $normalizedBody
                File = $file.Name
            }

            $propertyMatches = [regex]::Matches($classBody, '\[(?<propertykeyorwrite>Key|Write|Required)(?<qualifiers>(?:"(?:[^"\\]|\\.)*"|[^\]"])*)\]\s*(?<propertytype>\w+)\s+(?<propertyname>\w+)(?<isarray>\[\])?\s*;', @('Singleline', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase))

            $propertyInfoList = @()

            foreach ($propertyMatch in $propertyMatches)
            {
                $propertyKeyOrWrite = $propertyMatch.Groups['propertykeyorwrite'].Value
                $propertyType = $propertyMatch.Groups['propertytype'].Value
                $propertyName = $propertyMatch.Groups['propertyname'].Value
                $isArray = $propertyMatch.Groups['isarray'].Success

                $qualifiers = $propertyMatch.Groups['qualifiers'].Value
                $propertyDescription = [regex]::Match($qualifiers, 'Description\("(?<description>(?:[^"]|\\")*)"\)', 'IgnoreCase').Groups['description'].Value
                $embeddedInstanceType = [regex]::Match($qualifiers, 'EmbeddedInstance\("(?<type>\w+)"\)', 'IgnoreCase').Groups['type'].Value
                $valueMap = [regex]::Match($qualifiers, 'ValueMap\{(?<entries>[^}]*)\}', 'IgnoreCase').Groups['entries'].Value
                $values = [regex]::Match($qualifiers, '(?<!Value)Values\{(?<entries>[^}]*)\}', 'IgnoreCase').Groups['entries'].Value

                # ValueMap without Values is legal: the raw values double as the display names.
                if ([System.String]::IsNullOrEmpty($values))
                {
                    $values = $valueMap
                }

                if ($embeddedInstanceType)
                {
                    $propertyType = $embeddedInstanceType
                }

                if ($isArray)
                {
                    $propertyType = $propertyType + '[]'
                }

                $propertyInfoList += [ordered]@{
                    CIMType     = $propertyType
                    Description = $propertyDescription
                    Name        = $propertyName
                    Option      = $propertyKeyOrWrite
                }

                if ($ValueMap.Length -gt 0)
                {
                    # ValueMap/Values entries are quoted MOF strings and an entry can itself
                    # contain a comma, e.g. the flags value "companyPortal,email". Splitting on
                    # ',' tears those entries apart and produces duplicates in the generated
                    # SchemaDefinition.json, so extract the quoted tokens instead.
                    $ValueMap = @([regex]::Matches($ValueMap, '"([^"]*)"') | ForEach-Object { $_.Groups[1].Value })
                    $Values = @([regex]::Matches($Values, '"([^"]*)"') | ForEach-Object { $_.Groups[1].Value })

                    if ($propertyType.ToLower().Contains('string'))
                    {
                        $propertyInfoList[-1].ValueMap = [String[]]$valueMap
                        $propertyInfoList[-1].Values = [String[]]$values
                    }
                    elseif ($propertyType.ToLower().Contains('int'))
                    {
                        $propertyInfoList[-1].ValueMap = [int[]]$valueMap
                        $propertyInfoList[-1].Values = [int[]]$values
                    }
                }
            }

            $classInfoList += [ordered] @{
                ClassName   = $className
                Parameters  = $propertyInfoList
                Description = $resourceDescription
            }
        }
    }

    $jsonContent = ConvertTo-Json $classInfoList -Depth 99 -Compress
    Set-Content -Value $jsonContent -Path '.\Modules\Microsoft365DSC\SchemaDefinition.json'
}
