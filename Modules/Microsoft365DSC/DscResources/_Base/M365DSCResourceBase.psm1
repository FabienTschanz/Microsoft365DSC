using namespace System
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Reflection

<#
    Shared foundation for all Microsoft365DSC class-based resources.

    This file is SOURCE ONLY. Utilities/Build-Microsoft365DSC.ps1 emits it verbatim into
    Modules/Microsoft365DSC/Classes/_Shared.psm1, which every generated Part<NN>.psm1 opens with
    `using module`. It is never imported on its own: PowerShell classes do not cross module
    boundaries, and DSC only parses RootModule plus one level of NestedModules when looking for
    [DscResource()] classes.

    IMPORTANT - this file must never gain top-level executable code.

    Every converted resource opens with `using module ..\_Base\M365DSCResourceBase.psm1` so that it
    parses cleanly in an editor instead of showing TypeNotFound on the base class. `using module`
    IMPORTS the module at PARSE time, which means an editor executes this file every time anyone
    opens a resource. Class and enum definitions are inert and safe. Anything else - a command
    call, an assignment, a Write-Host - would run in the contributor's editor, unprompted, on every
    file open. Put such code in one of the Modules/*.psm1 helpers instead.

    It exists to give class-based resources back three things that function-based resources got
    for free:

      1. $PSBoundParameters      -> $this.GetBoundParameters()
      2. $MyInvocation.MyCommand -> $this.GetResourceName()
      3. a per-resource $Script: scope. The generated root module has ONE module scope shared by
         all resources, so the former $Script:exportedInstance / $Script:* caches would
         cross-contaminate. They become $this.ExportedInstance / $this.ResourceCache.
#>

# Per-derived-type reflection cache.
class M365DSCResourceInfo
{
    [Type] $Type

    [Dictionary[String, PropertyInfo]] $Properties

    M365DSCResourceInfo([Type] $Type)
    {
        $this.Type = $Type
        $this.Properties = [Dictionary[String, PropertyInfo]]::new([StringComparer]::OrdinalIgnoreCase)

        # Members declared on the base class are infrastructure, not resource schema.
        $baseMembers = [M365DSCResourceBase].GetProperties().Name

        foreach ($property in $Type.GetProperties())
        {
            if ($baseMembers -contains $property.Name)
            {
                continue
            }

            if (-not $property.CanWrite)
            {
                continue
            }

            $this.Properties[$property.Name] = $property

            $definition = @{
                TypeName    = $Type.Name
                MemberType  = 'ScriptProperty'
                MemberName  = $property.Name
                Value       = [ScriptBlock]::Create(('$value = $this._GetProperty(''{0}''); if ($value -is [System.Array]) {{ , $value }} else {{ $value }}' -f $property.Name))
                SecondValue = [ScriptBlock]::Create(('$this._SetProperty(''{0}'', $args[0])' -f $property.Name))
                Force       = $true
            }
            Update-TypeData @definition
        }
    }
}

class M365DSCResourceBase
{
    #region Infrastructure state

    <#
        DSC marshals class-resource properties by REFLECTION, in both directions: it writes the CLR
        backing fields when it populates an instance, and reads the CLR backing fields off whatever
        a method returns. An ETS ScriptProperty that stored values elsewhere meant DSC wrote where
        the class never looked and the class wrote where DSC never looked. Measured on 7.6.4: a
        resource built this way returned Id='' and DisplayName='' through Invoke-DscResource, while
        an otherwise identical class without the ETS layer round-tripped correctly.

        So the ScriptProperty writes THROUGH to the real property (see _SetProperty) and this class
        keeps no property state of its own.
    #>
    # Underscore-prefixed on purpose. A derived class cannot redeclare a member the base already
    # defines, and resource schemas do use ordinary words as property names - the schema scan found
    # MSFT_SCHeaderPattern.Values - so the internal members stay out of that namespace.

    # Replaces $Script:exportedInstance, which cannot stay script-scoped once all
    # resources share one module scope.
    hidden [System.Object] $ExportedInstance

    # Replaces the assorted per-resource $Script:* caches ($Script:RoleDefinitions,
    # $Script:AllSchedules, $Script:exportedGroups, ...).
    hidden [Hashtable] $ResourceCache = @{}

    hidden static [Dictionary[Type, M365DSCResourceInfo]] $_initialized = `
        [Dictionary[Type, M365DSCResourceInfo]]::new()

    # Per-complex-type property metadata (ValidateSet presence, nested complex types),
    # built lazily for SanitizeComplexValue.
    hidden static [Dictionary[Type, System.Object]] $_complexMetadata = `
        [Dictionary[Type, System.Object]]::new()

    hidden [M365DSCResourceInfo] $_info

    # Resource-name to type map, populated by each generated Part<NN>.psm1 at import time.
    hidden static [Dictionary[String, Type]] $_registry = `
        [Dictionary[String, Type]]::new([StringComparer]::OrdinalIgnoreCase)

    # Which part module declares each resource.
    hidden static [Dictionary[String, String]] $_moduleByResource = `
        [Dictionary[String, String]]::new([StringComparer]::OrdinalIgnoreCase)

    static [void] Register([Type] $Type, [System.String] $ModuleName)
    {
        [M365DSCResourceBase]::_registry[$Type.Name] = $Type
        [M365DSCResourceBase]::_moduleByResource[$Type.Name] = $ModuleName
    }

    static [System.String] ResolveModuleName([System.String] $Name)
    {
        $moduleName = $null
        [void] [M365DSCResourceBase]::_moduleByResource.TryGetValue($Name, [ref] $moduleName)
        return $moduleName
    }

    static [Type] Resolve([System.String] $Name)
    {
        $type = $null
        [void] [M365DSCResourceBase]::_registry.TryGetValue($Name, [ref] $type)
        return $type
    }

    static [String[]] GetRegisteredNames()
    {
        return [String[]] [M365DSCResourceBase]::_registry.Keys
    }

    #endregion

    M365DSCResourceBase()
    {
        $type = $this.GetType()

        $info = $null
        if (-not [M365DSCResourceBase]::_initialized.TryGetValue($type, [ref] $info))
        {
            $info = [M365DSCResourceInfo]::new($type)
            [M365DSCResourceBase]::_initialized[$type] = $info
        }

        $this._info = $info
    }

    #region Property plumbing

    # Reads the real CLR property.
    hidden [System.Object] _GetProperty([System.String] $Name)
    {
        $propertyInfo = $this._info.Properties[$Name]
        if ($null -eq $propertyInfo)
        {
            return $null
        }

        return $propertyInfo.GetValue($this)
    }

    # Validates, then writes THROUGH to the real CLR property.
    hidden [void] _SetProperty([System.String] $Name, [System.Object] $Value)
    {
        $propertyInfo = $this._info.Properties[$Name]
        if ($null -eq $propertyInfo)
        {
            throw [ArgumentException]::new("Unknown property '$Name' on resource '$($this.GetResourceName())'.", $Name)
        }

        $this.ValidateProperty($propertyInfo, $Name, $Value)

        if ([M365DSCResourceBase]::IsComplexClassType($propertyInfo.PropertyType))
        {
            $Value = [M365DSCResourceBase]::SanitizeComplexValue($Value, $propertyInfo.PropertyType)
        }

        if ($null -eq $Value)
        {
            $this.SetNullValue($propertyInfo)
            return
        }

        if ($Value -is [System.String] -and $Value -eq '' -and
            @($propertyInfo.GetCustomAttributes($true) | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }).Count -gt 0)
        {
            $this.SetNullValue($propertyInfo)
            return
        }

        if ($Value -isnot [System.String] -and $Value -is [System.Collections.IEnumerable] -and
            @($Value).Count -eq 0 -and
            @($propertyInfo.GetCustomAttributes($true) | Where-Object { $_ -is [System.Management.Automation.ValidateEnumeratedArgumentsAttribute] }).Count -gt 0)
        {
            $this.SetNullValue($propertyInfo)
            return
        }

        $converted = $Value -as $propertyInfo.PropertyType
        if ($null -eq $converted)
        {
            throw [InvalidOperationException]::new(
                "Cannot assign property '$Name' on resource '$($this.GetResourceName())': " +
                "a value of type '$($Value.GetType().FullName)' does not convert to " +
                "'$($propertyInfo.PropertyType.FullName)'." +
                $this.DescribeConversionFailure($Value, $propertyInfo.PropertyType))
        }

        $propertyInfo.SetValue($this, $converted)
    }

    # Applies the parameter validation attributes declared on the property.
    hidden [void] SetNullValue([PropertyInfo] $PropertyInfo)
    {
        $value = $null
        if ($PropertyInfo.PropertyType.IsValueType -and
            $null -eq [Nullable]::GetUnderlyingType($PropertyInfo.PropertyType))
        {
            $value = [Activator]::CreateInstance($PropertyInfo.PropertyType)
        }

        $field = $PropertyInfo.DeclaringType.GetField(
            "<$($PropertyInfo.Name)>k__BackingField",
            [BindingFlags]::Instance -bor [BindingFlags]::NonPublic)

        if ($null -ne $field)
        {
            $field.SetValue($this, $value)
            return
        }

        $PropertyInfo.SetValue($this, $value)
    }

    # True when the property targets an embedded complex class (or an array of one).
    # Every embedded class is MSFT_-prefixed; resource classes, PSCredential and
    # CimInstance are not.
    hidden static [System.Boolean] IsComplexClassType([Type] $Type)
    {
        $element = if ($Type.IsArray) { $Type.GetElementType() } else { $Type }
        return ($element.IsClass -and $element.Name -like 'MSFT_*')
    }

    hidden static [System.Object] GetComplexPropertyMetadata([Type] $Type)
    {
        $metadata = $null
        if ([M365DSCResourceBase]::_complexMetadata.TryGetValue($Type, [ref] $metadata))
        {
            return $metadata
        }

        $table = [Dictionary[String, System.Object]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($property in $Type.GetProperties())
        {
            if (-not $property.CanWrite)
            {
                continue
            }

            $table[$property.Name] = [PSCustomObject] @{
                HasValidateSet = @($property.GetCustomAttributes([ValidateSetAttribute], $true)).Count -gt 0
                IsComplex      = [M365DSCResourceBase]::IsComplexClassType($property.PropertyType)
                Type           = $property.PropertyType
            }
        }

        [M365DSCResourceBase]::_complexMetadata[$Type] = $table
        return $table
    }

    <#
        Complex classes carry [ValidateSet] restored from the former MOF ValueMaps. Unlike the
        resource's own properties, which _SetProperty routes around validation for null/empty
        (SetNullValue), nested members are assigned by PowerShell's hashtable-to-class conversion
        during the -as cast below, which enforces every attribute - and one $null or '' on a
        ValidateSet member makes the WHOLE cast return $null. Graph frequently hands back $null/''
        for enum-typed members, and the PS 5.1 dispatch path deserializes instances carrying every
        property including unset ones. Dropping those keys before the cast keeps "unset" meaning
        unset; a non-empty out-of-set value still fails the cast and is reported by
        DescribeConversionFailure.
    #>
    hidden static [System.Object] SanitizeComplexValue([System.Object] $Value, [Type] $TargetType)
    {
        if ($null -eq $Value)
        {
            return $null
        }

        if ($TargetType.IsArray)
        {
            $element = $TargetType.GetElementType()

            if ($Value -is [System.String])
            {
                # Would enumerate as chars; let the cast fail exactly as today.
                return $Value
            }

            if ($Value -is [IDictionary] -or $Value -isnot [IEnumerable])
            {
                # Scalar-to-array coercion: sanitize the single element, PowerShell wraps it.
                return [M365DSCResourceBase]::SanitizeComplexValue($Value, $element)
            }

            $result = [List[System.Object]]::new()
            foreach ($item in $Value)
            {
                $result.Add([M365DSCResourceBase]::SanitizeComplexValue($item, $element))
            }
            return $result.ToArray()
        }

        if ($TargetType.IsInstanceOfType($Value))
        {
            return $Value
        }

        $entries = [Ordered] @{}
        if ($Value -is [IDictionary])
        {
            foreach ($key in @($Value.Keys))
            {
                $entries[[System.String] $key] = $Value[$key]
            }
        }
        elseif ($Value.PSObject.BaseObject -is [System.Management.Automation.PSCustomObject])
        {
            # Includes Deserialized.MSFT_* instances from the PS 5.1 -> 7 dispatch, which carry
            # every property. Flattening to a hashtable means only the surviving keys are assigned.
            foreach ($property in $Value.PSObject.Properties)
            {
                $entries[$property.Name] = $property.Value
            }
        }
        else
        {
            # Unrecognized shape: pass through unchanged, worst case equals today's behavior.
            return $Value
        }

        $metadata = [M365DSCResourceBase]::GetComplexPropertyMetadata($TargetType)
        $clean = @{}
        foreach ($key in $entries.Keys)
        {
            $item = $entries[$key]

            $meta = $null
            if ($metadata.TryGetValue($key, [ref] $meta))
            {
                if ($meta.HasValidateSet -and
                    ($null -eq $item -or ($item -is [System.String] -and $item -eq '')))
                {
                    continue
                }

                if ($meta.IsComplex -and $null -ne $item)
                {
                    $item = [M365DSCResourceBase]::SanitizeComplexValue($item, $meta.Type)
                }
            }

            # Unknown keys stay: they still fail the cast and get reported, semantics preserved.
            $clean[$key] = $item
        }

        return $clean
    }

    # Narrows a failed conversion down to the element and member that caused it.
    hidden [System.String] DescribeConversionFailure([System.Object] $Value, [Type] $Type)
    {
        $elementType = if ($Type.IsArray) { $Type.GetElementType() } else { $Type }

        $index = -1
        foreach ($item in @($Value))
        {
            $index++

            if ($null -eq $item -or $null -ne ($item -as $elementType))
            {
                continue
            }

            $where = if ($Type.IsArray) { " Element [$index]" } else { ' The value' }

            if ($item -isnot [System.Collections.IDictionary])
            {
                return "$where of type '$($item.GetType().FullName)' does not convert to '$($elementType.FullName)'."
            }

            $known = @($elementType.GetProperties() | ForEach-Object { $_.Name })
            $unknown = @($item.Keys | Where-Object { $_ -notin $known })
            if ($unknown.Count -gt 0)
            {
                return "$where carries member(s) not declared on '$($elementType.Name)': $($unknown -join ', ')."
            }

            foreach ($key in $item.Keys)
            {
                $member = $elementType.GetProperty($key)
                if ($null -eq $member)
                {
                    continue
                }

                # An out-of-set string converts to [string] just fine, so the -as probe below
                # cannot name it. Check the ValidateSet explicitly.
                $validateSet = @($member.GetCustomAttributes([System.Management.Automation.ValidateSetAttribute], $true)) |
                    Select-Object -First 1
                if ($null -ne $validateSet -and $null -ne $item[$key])
                {
                    foreach ($single in @($item[$key]))
                    {
                        if ($null -ne $single -and
                            -not ($single -is [System.String] -and $single -eq '') -and
                            $validateSet.ValidValues -notcontains $single)
                        {
                            return "$where member '$key' value '$single' is not in the valid set for " +
                                "'$($elementType.Name).$key': $($validateSet.ValidValues -join ', ')."
                        }
                    }
                }

                if ($null -ne $item[$key] -and $null -eq ($item[$key] -as $member.PropertyType))
                {
                    # Recursive conversion failure description
                    return "$where member '$key' of type '$($item[$key].GetType().FullName)' does not convert to '$($member.PropertyType.FullName)'." +
                        $this.DescribeConversionFailure($item[$key], $member.PropertyType)
                }
            }

            return "$where does not convert to '$($elementType.Name)' and no single member explains it."
        }

        return ''
    }

    hidden [void] ValidateProperty([PropertyInfo] $PropertyInfo, [System.String] $Name, [System.Object] $Value)
    {
        if ($null -eq $Value)
        {
            return
        }

        foreach ($attribute in $PropertyInfo.GetCustomAttributes($true))
        {
            if ($attribute -is [System.Management.Automation.ValidateSetAttribute])
            {
                foreach ($item in @($Value))
                {
                    if ($item -is [System.String] -and $item -eq '')
                    {
                        continue
                    }

                    if ($attribute.ValidValues -notcontains $item)
                    {
                        throw [ArgumentException]::new(
                            "The value '$item' is not valid for property '$Name'. Valid values are: $($attribute.ValidValues -join ', ').",
                            $Name)
                    }
                }
            }
            elseif ($attribute -is [System.Management.Automation.ValidateRangeAttribute])
            {
                foreach ($item in @($Value))
                {
                    if ($item -lt $attribute.MinRange -or $item -gt $attribute.MaxRange)
                    {
                        throw [ArgumentOutOfRangeException]::new(
                            $Name,
                            $item,
                            "The value '$item' is outside the valid range for property '$Name' ($($attribute.MinRange) to $($attribute.MaxRange)).")
                    }
                }
            }
            elseif ($attribute -is [System.Management.Automation.ValidateScriptAttribute])
            {
                foreach ($item in @($Value))
                {
                    if (-not (& $attribute.ScriptBlock $item))
                    {
                        throw [ArgumentException]::new("The value '$item' is not valid for property '$Name'.", $Name)
                    }
                }
            }
            elseif ($attribute -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute])
            {
                if ($Value -is [System.String] -and [System.String]::IsNullOrEmpty($Value))
                {
                    throw [ArgumentException]::new("Property '$Name' may not be null or empty.", $Name)
                }
            }
        }
    }

    #endregion

    #region $PSBoundParameters replacement

    <#
        The direct replacement for $PSBoundParameters.

        "Specified" means "not $null". There is no separate record of which properties were
        assigned, because there cannot be one: DSC populates instances by reflection, so an
        assignment-tracking set stays empty on exactly the path that matters most - the LCM.

        This is why the converter emits value-type properties as System.Nullable[T]. DSC only sets
        the properties present in the compiled MOF instance and leaves the rest at their CLR
        defaults, so with a nullable property "omitted" is $null while "specified as $false" is
        $false, and the two stay distinguishable. With a plain [Boolean] they are not - measured:
        an omitted [UInt32] came back as 0 and an omitted [Nullable[UInt32]] came back as $null.
    #>
    [Hashtable] GetBoundParameters()
    {
        $result = @{}
        foreach ($name in $this._info.Properties.Keys)
        {
            $value = $this._GetProperty($name)
            if ($null -ne $value)
            {
                $result[$name] = $value
            }
        }
        return $result
    }

    [Hashtable] ToHashtable()
    {
        return $this.GetBoundParameters()
    }

    [void] FromHashtable([Hashtable] $Source)
    {
        foreach ($entry in $Source.GetEnumerator())
        {
            if ($this._info.Properties.ContainsKey($entry.Key))
            {
                $this.($entry.Key) = $entry.Value
            }
        }
    }

    #endregion

    #region Identity

    # Replaces $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '') and
    # $MyInvocation.MyCommand.Source
    [System.String] GetResourceName()
    {
        return $this.GetType().Name
    }

    # Replaces $PSScriptRoot, used by every Export-TargetResource as
    # Get-M365DSCExportContentForResource -ModulePath $PSScriptRoot.
    [System.String] GetModulePath()
    {
        $module = Get-Module -Name 'Microsoft365DSC'
        if ($null -eq $module)
        {
            $module = Get-Module -Name 'Microsoft365DSC' -ListAvailable | Select-Object -First 1
        }
        return $module.ModuleBase
    }

    #endregion

    #region Shared resource plumbing

    # Replaces the copy-pasted #region Telemetry block in all 535 resources.
    [void] AddTelemetry([System.String] $MethodName)
    {
        $data = Format-M365DSCTelemetryParameters -ResourceName $this.GetResourceName() `
            -CommandName $MethodName `
            -Parameters $this.GetBoundParameters()
        Add-M365DSCTelemetryEvent -Data $data
    }

    [System.String] Connect([System.String] $Workload)
    {
        return (New-M365DSCConnection -Workload $Workload -InboundParameters $this.GetBoundParameters())
    }

    [System.String] Connect([System.String] $Workload, [System.String] $Url)
    {
        return (New-M365DSCConnection -Workload $Workload -InboundParameters $this.GetBoundParameters() -Url $Url)
    }

    # Replaces the copy-pasted New-M365DSCLogEntry call in every catch block.
    [void] LogError([System.Object] $Exception, [System.String] $Message)
    {
        New-M365DSCLogEntry -Message $Message `
            -Exception $Exception `
            -Source $this.GetResourceName() `
            -TenantId $this._GetProperty('TenantId') `
            -Credential $this._GetProperty('Credential')
    }


    # Emits the standard deprecation warning for every listed parameter the user actually bound.
    # TODO: callers remove their parameters (and this call) at the next breaking change release.
    hidden [void] WarnDeprecated([System.String[]] $ParameterNames)
    {
        $bound = $this.GetBoundParameters()
        foreach ($name in $ParameterNames)
        {
            if ($bound.ContainsKey($name))
            {
                Write-Warning -Message "The parameter '$name' is deprecated. It will be removed in the next breaking change release."
            }
        }
    }

    # Serialises a nullable boolean into a JSON literal
    [System.String] BoolToJson([System.Object] $Value)
    {
        if ($null -eq $Value)
        {
            return 'false'
        }

        return ([System.Boolean] $Value).ToString().ToLower()
    }

    #endregion

    #region Default DSC method implementations

    # Default Test() for every resource. Splats GetCompareParameters() so a resource that only
    # needs custom comparison parameters overrides that method and keeps this Test() untouched.
    # Argument order is load-bearing: -DesiredValues must be evaluated BEFORE -CurrentValues so the
    # desired snapshot is taken before Get() runs.
    [bool] Test()
    {
        $this.AddTelemetry('Test')

        $compareParameters = $this.GetCompareParameters()
        return (Test-M365DSCTargetResource -DesiredValues $this.GetBoundParameters() `
                -ResourceName $this.GetResourceName() `
                @compareParameters `
                -CurrentValues $this.Get().ToHashtable())
    }

    # Overridden by resources that need custom comparison parameters
    # (ExcludedProperties / IncludedProperties / PostProcessing / PostProcessingArgs).
    [Hashtable] GetCompareParameters()
    {
        return @{}
    }

    # True when the PostProcessing scriptblock runs for report generation (New-M365DSCDeltaReport)
    # rather than for Test(). Reporting compares two configuration files and has no guaranteed
    # workload connection, so callbacks that call a cmdlet must return their values untouched.
    static [bool] IsReportContext([System.Object[]] $PostProcessingArgs)
    {
        foreach ($argument in $PostProcessingArgs)
        {
            if ($argument -is [System.Collections.Hashtable] -and $argument['IsReport'] -eq $true)
            {
                return $true
            }
        }

        return $false
    }

    # Every schema property of the derived type. Replaces
    # $MyInvocation.MyCommand.Parameters.GetEnumerator()
    [System.String[]] GetSchemaPropertyNames()
    {
        return [System.String[]] $this._info.Properties.Keys
    }

    # Declared type of one schema property, or $null when the derived type has no such property.
    [Type] GetSchemaPropertyType([System.String] $Name)
    {
        $propertyInfo = $this._info.Properties[$Name]
        if ($null -eq $propertyInfo)
        {
            return $null
        }

        return $propertyInfo.PropertyType
    }

    [Hashtable] GetSettingsCatalogCompareParameters()
    {
        return $this.GetSettingsCatalogCompareParameters(@())
    }

    # Shared comparison shim for the settings-catalog resources.
    [Hashtable] GetSettingsCatalogCompareParameters([System.String[]] $ExcludedProperties)
    {
        $result = @{
            PostProcessing     = {
                param($DesiredValues, $CurrentValues, $ValuesToCheck, $PostProcessingArgs)
                foreach ($name in $PostProcessingArgs[0])
                {
                    $currentValue = $CurrentValues[$name]
                    $desiredValue = $DesiredValues[$name]

                    if ($currentValue -is [System.Collections.ICollection] -and $currentValue.Count -eq 0)
                    {
                        $currentValue = $null
                    }
                    if ($desiredValue -is [System.Collections.ICollection] -and $desiredValue.Count -eq 0)
                    {
                        $desiredValue = $null
                    }

                    if ($null -ne $currentValue -or $null -ne $desiredValue)
                    {
                        $ValuesToCheck[$name] = $null
                        if (-not $DesiredValues.ContainsKey($name))
                        {
                            $DesiredValues.Add($name, $null)
                        }
                    }
                }

                return [System.Tuple[Hashtable, Hashtable, Hashtable]]::new($DesiredValues, $CurrentValues, $ValuesToCheck)
            }
            # Prevent array unrolling
            PostProcessingArgs = @(, $this.GetSchemaPropertyNames())
        }

        if ($ExcludedProperties.Count -gt 0)
        {
            $result.ExcludedProperties = $ExcludedProperties
        }

        return $result
    }

    [Hashtable] GetForExport([Hashtable] $Values)
    {
        $this.FromHashtable($Values)
        return $this.Get().ToHashtable()
    }

    #endregion

    #region Windows PowerShell 5.1 dispatch

    [bool] RequiresPowerShellCore()
    {
        return ($global:PSVersionTable.PSEdition -ne 'Core')
    }

    [System.Object] InvokeInPowerShellCore([System.String] $MethodName)
    {
        return (Invoke-M365DSCClassResourceInPowerShellCore -ClassName $this.GetResourceName() `
                -MethodName $MethodName `
                -Parameters $this.GetBoundParameters())
    }

    #endregion
}
