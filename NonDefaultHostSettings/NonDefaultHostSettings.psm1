#Requires -Version 3

function Get-NonDefaultAdvancedSettings {

<#
.SYNOPSIS
    Obtains all the advanced settings which are not at their default value for one or more host.

.DESCRIPTION
    Obtains all the advanced settings which are not at their default value for one or more ESXi host.
    It output the setting(s) path, description, default value, and current value.

.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default value is Localhost.

.PARAMETER VMHost
    To specify one or more ESXi hosts.
    The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.
    This parameter has 2 aliases : "Hosts" and "Servers".

.EXAMPLE 
    Get-NonDefaultAdvancedSettings

    Obtains the advanced settings which are not at their default value for all ESXi hosts managed by the connected vCenter.

.EXAMPLE 
    Get-VMHost esxi55ga-3.vcloud.local | Get-NonDefaultAdvancedSettings

    Obtains the advanced settings which are not at their default value for the host esxi55ga-3.vcloud.local, using pipeline input.
#>

[cmdletbinding()]
    param(
        [string]$VIServer = "localhost",

        [Parameter(ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName=$True,
        Position=0)]
        [Alias('Hosts','Servers')]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl[]]$VMHost = (Get-VMHost)
    )

    Begin {
        # Checking if the required PowerCLI snapin is loaded, if not, loading it
        If(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
            Add-PSSnapin VMware.VimAutomation.Core }

        Set-PowercliConfiguration -InvalidCertificateAction "Ignore" -DisplayDeprecationWarnings:$false -Confirm:$false -WhatIf:$False | Out-Null

        If (-not($defaultVIServer)) {
            Connect-VIServer $VIServer | Out-Null
        }
        Else {
            Write-Verbose "Already connected the vCenter Server: $defaultVIServer" 
        }

        # Clearing the default parameter values in the function's scope
        $PSDefaultParameterValues.Clear()
    }

    Process {

        Foreach ($iVMhost in $VMhost) {

            $EsxCli = Get-EsxCli -VMHost $iVMhost

            $HostNonDefaultSettings = $($EsxCli.system.settings.advanced.list($True, $NUll, $Null))
            $HostNonDefaultSettings | Add-Member -MemberType NoteProperty -Name "Host" -Value $($iVMhost.Name)
            $HostNonDefaultSettings
        }
    }
    End {
    }
}
function Set-AdvancedSettingsToDefaults {

<#
.SYNOPSIS
    Sets the advanced settings which are not at their default value back to their default, for one or more host.

.DESCRIPTION
    Sets the advanced settings which are not at their default value back to their default, for one or more ESXi host.
    Supports -WhatIf parameter to see what modification(s) it would perform, without actually performing them.
    Supports -Confirm parameter to prompt for confirmation before performing the modification(s).

.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default value is Localhost.

.PARAMETER VMHost
    To specify one or more ESXi hosts.
    The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.
    This parameter has 2 aliases : "Hosts" and "Servers".

.EXAMPLE 
    Set-AdvancedSettingsToDefaults

    Sets the advanced settings which are not at their default value back to their default, for all ESXi hosts managed by the connected vCenter.

.EXAMPLE 
    Get-VMHost esxi55ga-3.vcloud.local | Set-AdvancedSettingsToDefaults

    Sets the advanced settings which are not at their default value back to their default, for the host esxi55ga-3.vcloud.local, using pipeline input.

.EXAMPLE
    Get-VMHost "ESXi55*" | Set-AdvancedSettingsToDefaults -WhatIf

    Displays the modification(s) it would perform on the hosts which have a name starting with "ESXi55", without actually performing them.
#>

[cmdletbinding(SupportsShouldProcess)]
    param(
        [string]$VIServer = "localhost",

        [Parameter(ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName=$True,
        Position=0)]
        [Alias('Hosts','Servers')]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl[]]$VMHost = (Get-VMHost)
    )

    Begin {
        # Checking if the required PowerCLI snapin is loaded, if not, loading it
        If(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
            Add-PSSnapin VMware.VimAutomation.Core }

        Set-PowercliConfiguration -InvalidCertificateAction "Ignore" -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null

        If (-not($defaultVIServer)) {
            Connect-VIServer $VIServer | Out-Null
        }
        Else {
            Write-Verbose "Already connected the vCenter Server: $defaultVIServer" 
        }
        # Clearing the default parameter values in the function's scope
        $PSDefaultParameterValues.Clear()
    }

    Process {
        Foreach ($iVMhost in $VMhost) {

             $HostSettingsToRemediate = Get-NonDefaultAdvancedSettings -VMHost $iVMhost

             Foreach ($SettingToRemediate in $HostSettingsToRemediate) {

                 $SettingToRemediate | Add-Member -MemberType NoteProperty -Name "SettingName" -Value $($SettingToRemediate.Path).Trim("/").replace("/",".")
             
                 # The default value can be in the DefaultStringValue property if the type is "string" or in the DefaultIntValue if the type is "integer"
                 # Building a custom property, named "DefaultValue", based on this logic 

                 If ( $($SettingToRemediate.Type) -eq "string" ) {
                    $SettingToRemediate | Add-Member -MemberType NoteProperty -Name "DefaultValue" -Value $($SettingToRemediate.DefaultStringValue)
                 }
                 Else {
                    $SettingToRemediate | Add-Member -MemberType NoteProperty -Name "DefaultValue" -Value $($SettingToRemediate.DefaultIntValue)
                 }
                
                If ( $PSCmdlet.ShouldProcess("Advanced Setting : $($SettingToRemediate.SettingName) on $($iVMhost.Name)","Setting to value : $($SettingToRemediate.DefaultValue)") ) {
                    Get-AdvancedSetting -Entity $iVMhost -Name $($SettingToRemediate.SettingName) | Set-AdvancedSetting -Value $($SettingToRemediate.DefaultValue) -Confirm:$false
                }
             }
        }
    }
    End {
    }
}