[CmdletBinding()]
param(
)

<#
    Exercises the complex-type hydration path of M365DSCResourceBase through the public
    New-M365DSCResourceInstance seam: assigning a complex-typed property routes through
    _SetProperty -> SanitizeComplexValue -> the hashtable-to-class conversion, which now
    enforces the [ValidateSet] attributes restored on embedded complex classes.

    Uses IntuneCloudProvisioningPolicyWindows365 because its Assignments property targets
    MSFT_DeviceManagementConfigurationPolicyAssignments, whose dataType and
    deviceAndAppManagementAssignmentFilterType members both carry a [ValidateSet].
#>

BeforeAll {
    $repoRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..' -Resolve
    Import-Module -Name (Join-Path -Path $repoRoot -ChildPath 'Modules\Microsoft365DSC\Microsoft365DSC.psd1') -Global

    $Script:NewInstance = {
        param ([System.Collections.Hashtable] $Property)
        New-M365DSCResourceInstance -ResourceName 'IntuneCloudProvisioningPolicyWindows365' -Property $Property
    }
}

Describe 'M365DSCResourceBase complex-type hydration' {
    It 'Hydrates a complex array element with valid ValidateSet values' {
        $instance = & $Script:NewInstance @{
            Assignments = @(
                @{
                    dataType = '#microsoft.graph.groupAssignmentTarget'
                    deviceAndAppManagementAssignmentFilterType = 'include'
                    groupId = '42a638ec-2bf2-47a8-8f5f-176ce2124b7b'
                }
            )
        }

        $instance.Assignments.Count | Should -Be 1
        $instance.Assignments[0].dataType | Should -Be '#microsoft.graph.groupAssignmentTarget'
        $instance.Assignments[0].deviceAndAppManagementAssignmentFilterType | Should -Be 'include'
    }

    It 'Drops a $null value on a ValidateSet member instead of failing the conversion' {
        $instance = & $Script:NewInstance @{
            Assignments = @(
                @{
                    dataType = '#microsoft.graph.groupAssignmentTarget'
                    deviceAndAppManagementAssignmentFilterType = $null
                    groupId = '42a638ec-2bf2-47a8-8f5f-176ce2124b7b'
                }
            )
        }

        $instance.Assignments.Count | Should -Be 1
        $instance.Assignments[0].deviceAndAppManagementAssignmentFilterType | Should -BeNullOrEmpty
        $instance.Assignments[0].groupId | Should -Be '42a638ec-2bf2-47a8-8f5f-176ce2124b7b'
    }

    It 'Drops an empty string on a ValidateSet member instead of failing the conversion' {
        $instance = & $Script:NewInstance @{
            Assignments = @(
                @{
                    dataType = '#microsoft.graph.groupAssignmentTarget'
                    deviceAndAppManagementAssignmentFilterType = ''
                }
            )
        }

        $instance.Assignments.Count | Should -Be 1
        $instance.Assignments[0].deviceAndAppManagementAssignmentFilterType | Should -BeNullOrEmpty
    }

    It 'Keeps $null on members without a ValidateSet' {
        $instance = & $Script:NewInstance @{
            Assignments = @(
                @{
                    dataType = '#microsoft.graph.allDevicesAssignmentTarget'
                    groupId = $null
                }
            )
        }

        $instance.Assignments.Count | Should -Be 1
        $instance.Assignments[0].groupId | Should -BeNullOrEmpty
    }

    It 'Throws on an out-of-set value and names the offending member' {
        {
            & $Script:NewInstance @{
                Assignments = @(
                    @{
                        dataType = 'not-a-real-target'
                    }
                )
            }
        } | Should -Throw -ExpectedMessage '*dataType*not in the valid set*'
    }

    It 'Hydrates every element of a complex array when one element carries a $null ValidateSet member' {
        $instance = & $Script:NewInstance @{
            Assignments = @(
                @{
                    dataType = '#microsoft.graph.groupAssignmentTarget'
                    groupId = '11111111-1111-1111-1111-111111111111'
                },
                @{
                    dataType = '#microsoft.graph.exclusionGroupAssignmentTarget'
                    deviceAndAppManagementAssignmentFilterType = $null
                    groupId = '22222222-2222-2222-2222-222222222222'
                }
            )
        }

        $instance.Assignments.Count | Should -Be 2
        $instance.Assignments[1].dataType | Should -Be '#microsoft.graph.exclusionGroupAssignmentTarget'
    }

    It 'Hydrates a PSCustomObject element the same as a hashtable' {
        $instance = & $Script:NewInstance @{
            Assignments = @(
                [PSCustomObject] @{
                    dataType = '#microsoft.graph.groupAssignmentTarget'
                    deviceAndAppManagementAssignmentFilterType = $null
                    groupId = '42a638ec-2bf2-47a8-8f5f-176ce2124b7b'
                }
            )
        }

        $instance.Assignments.Count | Should -Be 1
        $instance.Assignments[0].groupId | Should -Be '42a638ec-2bf2-47a8-8f5f-176ce2124b7b'
    }

    It 'Hydrates a non-array complex property and recurses into nested members' {
        $instance = & $Script:NewInstance @{
            WindowsSetting = @{
                Locale = 'de-CH'
            }
            DomainJoinConfigurations = @(
                @{
                    DomainJoinType = 'azureADJoin'
                    RegionGroup = $null
                    RegionName = 'automatic'
                }
            )
        }

        $instance.WindowsSetting.Locale | Should -Be 'de-CH'
        $instance.DomainJoinConfigurations.Count | Should -Be 1
        $instance.DomainJoinConfigurations[0].DomainJoinType | Should -Be 'azureADJoin'
        $instance.DomainJoinConfigurations[0].RegionGroup | Should -BeNullOrEmpty
    }

    It 'Restored the [ValidateSet] attribute on the embedded complex class' {
        $instance = & $Script:NewInstance @{
            Assignments = @(
                @{
                    dataType = '#microsoft.graph.groupAssignmentTarget'
                }
            )
        }

        $property = $instance.Assignments[0].GetType().GetProperty('dataType')
        $validateSet = $property.GetCustomAttributes([System.Management.Automation.ValidateSetAttribute], $true)
        $validateSet | Should -Not -BeNullOrEmpty
        $validateSet[0].ValidValues | Should -Contain '#microsoft.graph.groupAssignmentTarget'
    }
}
