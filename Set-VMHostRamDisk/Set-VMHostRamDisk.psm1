function Set-VMHostRamDisk {

<#
.SYNOPSIS
    Configures the memory allocated to a RAMDisk for one or more ESXi hosts.

.DESCRIPTION
    Configures the memory allocation (reservation, limit and whether the reservation is expandable) of a RAMDisk for one or more ESXi hosts.

.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default value is Localhost.

.PARAMETER Host
    To specify one or more ESXi hosts.
    The default obtains information for all the hosts in the connected vCenter.

.PARAMETER RamDisk
    To specify the RAMDisk to configure.
    Possible values : "tmp","root", or "hostdstats".

.PARAMETER Reservation
    To configure the memory guaranteed to the specified RAMDisk in MB.

.PARAMETER Limit
    To configure the maximum amount of memory which can be allocated to the specified RAMDisk in MB.

.PARAMETER ExpandableReservation
    To specify that more than the reservation can be allocated to the specified RAMDisk if there are available resources in the parent resource pool.

.EXAMPLE 
    Set-VMHostRamDisk -Host (Get-VMHost esxi55ga-2.vcloud.local) -RamDisk tmp -limit 400 -ExpandableReservation

    Configures the limit to 400 MB for the RAMDisk tmp of the host esxi55ga-2.vcloud.local and allows to allocate more than the reservation if there are available resources in the parent resource pool.

.EXAMPLE 
    Get-VMHost "ESXi55*" | Set-VMHostRamDisk -RamDisk root -Reservation 50 -Limit 50

    Configures the reservation and limit to 50 MB for the RAMDisk root of all ESXi hosts with a name starting with "ESXi55", using pipeline input.
.NOTES
    Author : Mathieu Buisson
    
#>
[cmdletbinding()]
    param(
        [string]$VIServer = "localhost",
        
        [Parameter(ValueFromPipeline = $True,Position=0)]   
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl[]]$Host = (Get-VMHost),

        [Parameter(Mandatory=$True,Position=1)]
        [ValidateSet("tmp","root","hostdstats")] 
        [string]$RamDisk,

        [int]$Reservation,

        [int]$Limit,

        [switch]$ExpandableReservation
    )

    Begin {
        # Checking if the required PowerCLI snapin (or module) is loaded, if not, loading it
        If (Get-Module VMware.VimAutomation.Core -ListAvailable -ErrorAction SilentlyContinue) {
            If (-not (Get-Module VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
	        Import-Module VMware.VimAutomation.Core
            }
        }
        Else {
            If (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
                Add-PSSnapin VMware.VimAutomation.Core
            }
        }
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

        # Building a new system resources configuration
        $Spec = New-Object VMware.Vim.HostSystemResourceInfo

        switch ($RamDisk) {
            'tmp' {$Spec.Key = "host/system/kernel/kmanaged/visorfs/tmp"}
            'root' {$Spec.Key = "host/system/kernel/kmanaged/visorfs/root"}
            'hostdstats' {$Spec.Key = "host/system/kernel/kmanaged/visorfs/hostdstats"}
        }
        $Spec.Config = New-Object VMware.Vim.ResourceConfigSpec
        $Spec.Config.cpuAllocation = New-Object VMware.Vim.ResourceAllocationInfo
        $Spec.Config.memoryAllocation = New-Object VMware.Vim.ResourceAllocationInfo
        If ($Reservation) {
            $Spec.Config.memoryAllocation.Reservation = $Reservation
        }
        If ($Limit) {
            $Spec.Config.MemoryAllocation.Limit = $Limit
        }
        If ($PSBoundParameters.ContainsKey('ExpandableReservation')) {
            $Spec.Config.MemoryAllocation.ExpandableReservation = $True
        }

        Foreach ($VMHost in $Host) {

            # Applying the new system resources configuration
            $Spec.Config.ChangeVersion = $VMHost.ExtensionData.SystemResources.Config.ChangeVersion
            $VMHost.ExtensionData.UpdateSystemResources($Spec)
        }
    }
    End {
    }
}