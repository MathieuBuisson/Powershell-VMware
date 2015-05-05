#Requires -Version 3

function Get-StorageViewsReport {

<#
.SYNOPSIS
    Obtains storage capacity and utilization information by datastore, by VM or by host.

.DESCRIPTION
    Obtains storage capacity and utilization information by datastore, by VM or by ESXi host.
    The default mode is by datastore.

.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default value is Localhost.

.PARAMETER ByVM
    To obtain storage capacity and utilization information by VM.

.PARAMETER VM
    Used in the "ByVM" mode, to specify one or more VMs.
    The default obtains information for all the VMs in the connected vCenter.

.PARAMETER ByDatastore
    To obtain storage capacity and utilization information by datastore.

.PARAMETER Datastore
    Used in the "ByDatastore" mode, to specify one or more datastores.
    The default obtains information for all the datastores in the connected vCenter.

.PARAMETER ByHost
    To obtain storage capacity and utilization information by ESXi host.

.PARAMETER Host
    Used in the "ByHost" mode, to specify one or more ESXi hosts.
    The default obtains information for all the hosts in the connected vCenter.

.EXAMPLE 
    Get-StorageViewsReport

    Obtains storage capacity and utilization information by datastore, for all the datastores in the connected vCenter.

.EXAMPLE 
    Get-Datastore iSCSI* | Get-StorageViewsReport | Format-Table -Auto

    Obtains storage capacity and utilization information by datastore, for the datastores which have a name starting with iSCSI, using pipeline input.
    Output is displayed as a table.

.EXAMPLE
    Get-StorageViewsReport -ByVM
    Obtains storage capacity and utilization information by VM, for all the VMs in the connected vCenter.

.EXAMPLE
    Get-StorageViewsReport -ByHost

    Obtains storage capacity and utilization information by ESXi host, for all the hosts in the connected vCenter.

.EXAMPLE
    Get-VMHost ESXi5* | Get-StorageViewsReport
    Obtains storage capacity and utilization information by ESXi host, for the hosts which have a name starting with ESXi5, using pipeline input.

#>

[cmdletbinding(DefaultParameterSetName="ByDatastore")]
    param(
        [string]$VIServer = "localhost",
        
        [Parameter(ParameterSetName='ByVM')]
        [switch]$ByVM,

        [Parameter(ValueFromPipeline = $True,
        ParameterSetName='ByVM',
        ValueFromPipelineByPropertyName=$True,Position=0)]   
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl[]]$VM = (Get-VM),

        [Parameter(ParameterSetName='ByDatastore')]
        [switch]$ByDatastore,

        [Parameter(ValueFromPipeline = $True,
        ParameterSetName='ByDatastore',
        ValueFromPipelineByPropertyName=$True,Position=0)]   
        [VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.VmfsDatastoreImpl[]]$Datastore = (Get-Datastore),


        [Parameter(ParameterSetName='ByHost')]
        [switch]$ByHost,

        [Parameter(ValueFromPipeline = $True,
        ParameterSetName='ByHost',Position=0)]   
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl[]]$Host = (Get-VMHost)
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
        If (-not ($PSBoundParameters.ContainsKey('VM')) ) {
            $VM = Get-VM
        }
    }
    Process {
        If ($PSCmdlet.ParameterSetName -eq "ByVM") {

            foreach ($iVM in $VM) {

                $iVMSnap = Get-Snapshot -VM $iVM.Name

                # Building the properties of our custom output object
                $ByVMProps = [ordered]@{'VM' = $iVM.Name
						        'SpaceUsedGB' = [Math]::Round($iVM.UsedSpaceGB, 2)
                                'ProvisionedSpaceGB' = [Math]::Round($iVM.ProvisionedSpaceGB, 2)
                                'SnapshotSpaceGB' = If ($iVMSnap) {[Math]::Round(($iVMSnap.SizeGB | Measure-Object -Sum).Sum, 2)} Else {0}
                                'Virtual Disks' = $iVM.HardDisks.Count}

		        $ByVMObj = New-Object -TypeName PSObject -Property $ByVMProps
                $ByVMObj
            }
        }
        If ($PSCmdlet.ParameterSetName -eq "ByDatastore") {
            
            $SnapView = Get-VM | Get-Snapshot | Get-View

            foreach ($iDatastore in $Datastore) {

                $ByDatastoreVMs = Get-VM -Datastore $iDatastore

                $iDatastoreView = $SnapView | Where-Object { $_.Config.datastoreURL.Name -eq $($iDatastore.Name) }
                If ($iDatastoreView) {
                    $iDatastoreSnapshots = Get-Snapshot * | Where-Object { $_.Id -in $($iDatastoreView.MoRef) }
                }

                # Building the properties of our custom output object
                $ByDatastoreProps = [ordered]@{'Datastore' = $iDatastore.Name
                                'State' = $iDatastore.State
                                'FSType' = $iDatastore.Type
						        'CapacityGB' = [Math]::Round($iDatastore.CapacityGB, 2)
                                'SpaceUsedGB' = [Math]::Round(($iDatastore.CapacityMB - $iDatastore.FreeSpaceMB) / 1024, 2)
                                'FreeSpaceGB' = [Math]::Round($iDatastore.FreeSpaceGB, 2)
                                'ProvisionedSpaceGB' =  If ($ByDatastoreVMs) {[Math]::Round(($ByDatastoreVMs.ProvisionedSpaceGB | Measure-Object -Sum).Sum, 2)} Else {0}
                                'SnapshotSpaceGB' = If ($iDatastoreSnapshots) {[Math]::Round(($iDatastoreSnapshots.sizeGB | Measure-Object -Sum).Sum, 2)} Else {0}
                                }

		        $ByDatastoreObj = New-Object -TypeName PSObject -Property $ByDatastoreProps
                $ByDatastoreObj
            }
        }
        If ($PSCmdlet.ParameterSetName -eq "ByHost") {
            
            foreach ($iHost in $Host) {

                $ByHostVMs = Get-VM -Location $iHost

                If ($ByHostVMs) {
                    $HostSnaps = Get-Snapshot -VM $ByHostVMs
                }
                
                # Building the properties of our custom output object
                $ByHostProps = [ordered]@{'Host' = $($iHost.Name)
                                'SpaceUsedGB' = If ($ByHostVMs) {[Math]::Round(($ByHostVMs.UsedSpaceGB | Measure-Object -Sum).Sum, 2)} Else {0}
                                'SnapshotSpaceGB' = If ($HostSnaps) {[Math]::Round(($HostSnaps.sizeGB | Measure-Object -Sum).Sum, 2)} Else {0}
                                'ProvisionedSpaceGB' = If ($ByHostVMs) {[Math]::Round(($ByHostVMs.ProvisionedSpaceGB | Measure-Object -Sum).Sum, 2)} Else {0}
                                'Virtual Disks' = If ($ByHostVMs) { ($($ByHostVMs).HardDisks | Measure-Object).Count } Else {0}
                                }

		        $ByHostObj = New-Object -TypeName PSObject -Property $ByHostProps
                $ByHostObj

            }
        }
    }

}