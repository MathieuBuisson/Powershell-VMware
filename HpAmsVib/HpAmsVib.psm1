#Requires -Version 3

function Find-BadHpAmsVib {

<#
.SYNOPSIS
    Looks for the hp-ams VIB installed on one or more ESXi hosts and displays them if they are in a version affected by the "Can't fork" bug.

.DESCRIPTION
    Looks for the hp-ams VIB installed on one or more ESXi hosts and displays them if they are in a version affected by the "Can't fork" bug.
    More information on this bug : http://kb.vmware.com/kb/2085618

    No output means that there is no ESXi host with the hp-ams VIB, or the installed version(s) of the hp-ams VIB(s) are not affected.

.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default is Localhost.

.PARAMETER VMhosts
    To specify one or more ESXi hosts.
    The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.
    This parameter has 2 aliases : "Hosts" and "Servers".

.PARAMETER Cluster
    To query all the ESXi hosts in the specified cluster.

.EXAMPLE 
    Find-BadHpAmsVib -Cluster Production

    Looks for the hp-ams VIB installed on all the ESXi hosts in the Production cluster.

.EXAMPLE 
    Get-VMHost EsxDev5* | Find-BadHpAmsVib

    Looks for the hp-ams VIB installed on the ESXi hosts with a name starting with EsxDev5, using pipeline input.

.LINK
    http://kb.vmware.com/kb/2085618
#>

    [cmdletbinding()]
    param(
        [string]$VIServer = "localhost",
        [Parameter(ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName=$True,
        Position=0)]
        [Alias('Hosts','Servers')]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl[]]$VMhosts,
        [string]$Cluster        
    )

    Begin {
        if(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
            Add-PSSnapin VMware.VimAutomation.Core }

        Set-PowercliConfiguration -InvalidCertificateAction "Ignore" -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null

        If (-not($defaultVIServer)) {
            Connect-VIServer $VIServer | Out-Null
        }
        Else {
            Write-Verbose "Already connected the vCenter Server: $defaultVIServer" 
        }
        If (-not ($PSBoundParameters.ContainsKey('VMhosts')) ) {
            $VMhosts = Get-VMHost
        }
        # Getting all hosts from the cluster(s) if the -Cluster parameter is specified
        If ($PSBoundParameters.ContainsKey('Cluster')) {
            $VMhosts = Get-Cluster -Name $Cluster | Get-VMHost
        }
        # Clearing the default parameter values in the function's scope
        $PSDefaultParameterValues.Clear()
    }
    Process {
    
        Foreach ($VMhost in $VMhosts) {

            $ESXiVersion = $VMhost.Version

            switch -Wildcard ($ESXiVersion) {
            "5.0*" { $ProblemVersions = "500.10.0.0","500.9" }
            "5.1*" { $ProblemVersions = "500.10.0.0","500.9" }
            "5.5*" { $ProblemVersions = "550.10.0.0","550.9" }
            }         

            $Esxcli = Get-EsxCli -VMHost $VMhost
            $VibList = $Esxcli.software.vib.list()
            $HpAmsVib = $VibList  | Where-Object { $_.Name -eq "hp-ams" }
        
            if ($HpAmsVib) {

               if ($ProblemVersions | ForEach-Object { $HpAmsVib.version -match $_ } | Where-Object { $_ }) {
            
                    # Building the properties of our custom output object
                    $Props = [ordered]@{
					'VMHost' = $VMhost.Name
					'ID' = $HpAmsVib.ID
					'Name' = $HpAmsVib.Name
					'Vendor' = $HpAmsVib.Vendor
					'Version' = $HpAmsVib.Version
					'InstallDate' = $HpAmsVib.InstallDate
                    }
		    New-Object -TypeName PSObject -Property $Props
                }
            }
        }
    }
    End {
    }
}

function Remove-BadHpAmsVib {

<#
.SYNOPSIS
    Looks for and uninstalls the hp-ams VIB installed on one or more ESXi hosts if they are in a version affected by the "Can't fork" bug.

.DESCRIPTION
    Looks for and uninstalls the hp-ams VIB installed on one or more ESXi hosts if they are in a version affected by the "Can't fork" bug.
    More information on this bug : http://kb.vmware.com/kb/2085618

.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default is Localhost.

.PARAMETER VMhosts
    To specify one or more ESXi hosts.
    The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.
    This parameter has 2 aliases : "Hosts" and "Servers".

.PARAMETER Cluster
    To query all the ESXi hosts in the specified cluster.

.PARAMETER Reboot
    If a hp-ams VIB has been uninstalled, puts the host in maintenance mode and reboots it.

    Assumes the host is in a DRS cluster in fully automated mode.
    If it is not in a DRS cluster, the running VMs will need to be evacuated manually for the host to enter maintenance mode successfully.
    If it is in a DRS cluster but not in fully automated mode, the DRS recommendations will need to be applied manually for the host to enter maintenance mode successfully.

    CAUTION : It does not exit maintenance mode after the reboot, so all hosts end up in maintenance mode and it will not do an orchestrated "evacuate & reboot" for all hosts in a cluster.
    For this reason, this parameter is not recommended when the VMHosts parameter contains several hosts.

.EXAMPLE 
    Remove-BadHpAmsVib -Cluster Production

    Looks for and uninstalls the hp-ams VIB installed on all the ESXi hosts in the Production cluster.

.EXAMPLE 
    Get-VMHost EsxDev5* | Remove-BadHpAmsVib -Reboot

    Looks for and uninstalls the hp-ams VIB installed on the ESXi hosts with a name starting with EsxDev5 and reboots the hosts for which the VIB was removed.

.LINK
    http://kb.vmware.com/kb/2085618
#>

    [cmdletbinding()]
    param(
        [string]$VIServer = "localhost",
        [Parameter(ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName=$True,
        Position=0)]
        [Alias('Hosts','Servers')]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl[]]$VMhosts,
        [string]$Cluster,
        [switch]$Reboot
    )

    Begin {
        if(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
            Add-PSSnapin VMware.VimAutomation.Core }

        Set-PowercliConfiguration -InvalidCertificateAction "Ignore" -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null

        If (-not($defaultVIServer)) {
            Connect-VIServer $VIServer | Out-Null
        }
        Else {
            Write-Verbose "Already connected the vCenter Server: $defaultVIServer" 
        }
        If (-not ($PSBoundParameters.ContainsKey('VMhosts')) ) {
            $VMhosts = Get-VMHost
        }
        # Getting all hosts from the cluster(s) if the -Cluster parameter is specified
        If ($PSBoundParameters.ContainsKey('Cluster')) {
            $VMhosts = Get-Cluster -Name $Cluster | Get-VMHost
        }
        # Clearing the default parameter values in the function's scope
        $PSDefaultParameterValues.Clear()
    }
    Process {
    
        Foreach ($VMhost in $VMhosts) {

            $ESXiVersion = $VMhost.Version

            switch -Wildcard ($ESXiVersion) {
            "5.0*" { $ProblemVersions = "500.10.0.0","500.9" }
            "5.1*" { $ProblemVersions = "500.10.0.0","500.9" }
            "5.5*" { $ProblemVersions = "550.10.0.0","550.9" }
            }

            $Esxcli = Get-EsxCli -VMHost $VMhost
            $VibList = $Esxcli.software.vib.list()
            $HpAmsVib = $VibList  | Where-Object { $_.Name -eq "hp-ams" }
        
            if ($HpAmsVib) {

               if ($ProblemVersions | ForEach-Object { $HpAmsVib.version -match $_ } | Where-Object { $_ }) {
                
                    Write-Warning "Uninstalling hp-ams VIB from $VMHost ..."
                    $Esxcli.software.vib.remove($false,$true,$true,$true,$HpAmsVib.Name) | Out-Null
                    Write-Warning "Uninstallation done, but the system needs to be rebooted for the changes to be effective."
                    
                    if ($Reboot) {
                        Set-VMHost -VMHost $VMhost -State maintenance
                        Restart-VMHost -VMHost $VMhost -Confirm:$False
                    }
                }
                Else {
                    Write-Output "The version of the hp-ams VIB on $VMhost is not affected."
                }
            }
            Else { Write-Output "No hp-ams VIB on $VMhost." }
        }
    }
    End {
    }
}
