#Requires -Version 3

function Get-CPUOvercommit {
<#
.SYNOPSIS
    Obtains the number of vCPUs and the number of physical CPU cores for one or more ESXi hosts and compares them to evaluate CPU overcommitment.

.DESCRIPTION
    Obtains the number of vCPUs and the number of physical CPU cores for one or more ESXi hosts (or for a cluster if the Cluster parameter is used) and compares them to evaluate CPU overcommitment.
        
    The CPU overcommitment is evaluated by comparing the number of vCPUs of all the running VMs for each ESXi host and the number of physical cores on this host.

.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default is Localhost.

.PARAMETER VMhosts
    To specify one or more ESXi hosts.
    The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.
    This parameter has 2 aliases : "Hosts" and "Servers".

.PARAMETER Cluster
    Outputs global values for the specified cluster

.PARAMETER Quiet
    This mode only outputs a boolean value for each ESXi host (or for the cluster if the Cluster parameter is used) :
    $True if there is overcommitment, $False if not.

.EXAMPLE 
    Get-CPUOvercommit -Cluster Production

    Obtains vCPU, physical cores and overcommitment information, providing global values for the cluster called Production.

.EXAMPLE 
    Get-VMHost EsxDev5* | Get-CPUOvercommit

    Obtains vCPU, physical cores and overcommitment information for each ESXi host with a name starting with EsxDev5, using pipeline input.

.EXAMPLE
    Get-CPUOvercommit -Quiet

    Outputs a boolean value stating whether there is CPU overcommitment or not, for each ESXi host managed by the connected vCenter Server.
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
    [switch]$Quiet
    )

    Begin {
        if(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
            Add-PSSnapin VMware.VimAutomation.Core }

        Set-PowercliConfiguration -InvalidCertificateAction "Ignore" -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null

        If (-not($defaultVIServer)) {
            Connect-VIServer $VIServer
        }
        Else {
            Write-Verbose "Already connected the vCenter Server: $defaultVIServer" 
        }
        # Clearing the default parameter values in the function's scope
        $PSDefaultParameterValues.Clear()
        
        If (-not ($PSBoundParameters.ContainsKey('VMhosts')) ) {
            $VMhosts = Get-VMHost
        }
        # Getting all hosts from the cluster(s) if the -Cluster parameter is specified
        If ($PSBoundParameters.ContainsKey('Cluster')) {
            $VMhosts = Get-Cluster -Name $Cluster | Get-VMHost
        }
        # Preparing a collection to store information for each individual ESXi host
        $OvercommitInfoCollection = @()
    }
    Process {

        Foreach ($VMhost in $VMhosts) {
            
            $HostPoweredOnvCPUs = (Get-VM -Location $VMhost | Where-Object {$_.PowerState -eq "PoweredOn" } | Measure-Object NumCpu -Sum).Sum
            Write-Verbose "`$HostPoweredOnvCPUs for $VMhost is : $HostPoweredOnvCPUs"

            # Building the properties for our custom object            
            $OvercommitInfoProperties = [ordered]@{'ESXi Host'=$VMhost.Name                    
                    'CPU Cores'=$VMhost.NumCpu
                    'Total vCPUs'=(Get-VM -Location $VMhost | Measure-Object NumCpu -Sum).Sum
                    'PoweredOn vCPUs'=if ($HostPoweredOnvCPUs) {$HostPoweredOnvCPUs} Else { 0 -as [int] }
                    'vCPU/Core ratio'=if ($HostPoweredOnvCPUs) {[Math]::Round(($HostPoweredOnvCPUs / $VMhost.NumCpu), 3)} Else { $null }
                    'CPU Overcommit (%)'=if ($HostPoweredOnvCPUs) {[Math]::Round(100*(($HostPoweredOnvCPUs - $VMhost.NumCpu) / $VMhost.NumCpu), 3)} Else { $null }
                    }           

            # Building a custom object from the list of properties above
            $OvercommitInfoObj = New-Object -TypeName PSObject -Property $OvercommitInfoProperties

            If ($Quiet) {
                $OvercommitInfoBoolean = $HostPoweredOnvCPUs -gt $VMhost.NumCpu
                $OvercommitInfoCollection += $OvercommitInfoBoolean
            }            
            Else {  
                $OvercommitInfoCollection += $OvercommitInfoObj
            }
        }
    }
    End {
        If ($PSBoundParameters.ContainsKey('Cluster')) {

            $ClusterPoweredOnvCPUs = (Get-VM -Location $Cluster | Where-Object {$_.PowerState -eq "PoweredOn" } | Measure-Object NumCpu -Sum).Sum
            $ClusterCPUCores = ($VMhosts | Measure-Object NumCpu -Sum).Sum
            Write-Verbose "`$ClusterPoweredOnvCPUs for $Cluster is : $ClusterPoweredOnvCPUs"
            Write-Verbose "`$ClusterCPUCores for $Cluster is : $ClusterCPUCores"

            # Building a custom object specific to the -Cluster parameter
            $ClusterOvercommitProperties = [ordered]@{'Cluster Name'=$Cluster                    
                    'CPU Cores'=$ClusterCPUCores
                    'Total vCPUs'=($OvercommitInfoCollection."Total vCPUs" | Measure-Object -Sum).Sum
                    'PoweredOn vCPUs'=if ($ClusterPoweredOnvCPUs) {$ClusterPoweredOnvCPUs} Else { 0 -as [int] }
                    'vCPU/Core ratio'=if ($ClusterPoweredOnvCPUs) {[Math]::Round(($ClusterPoweredOnvCPUs / $ClusterCPUCores), 3)} Else { $null }
                    'CPU Overcommit (%)'=if ($ClusterPoweredOnvCPUs) {[Math]::Round(100*(( $ClusterPoweredOnvCPUs - $ClusterCPUCores) / $ClusterCPUCores), 3)} Else { $null }
                    }     
            
            $ClusterOvercommitObj = New-Object -TypeName PSObject -Property $ClusterOvercommitProperties

            If ($Quiet) {
                $ClusterOvercommitBoolean = $ClusterPoweredOnvCPUs -gt $ClusterCPUCores
                $ClusterOvercommitBoolean
            }
            
            Else { $ClusterOvercommitObj
            }
        }
        Else { $OvercommitInfoCollection }
    }
}
function Get-MemoryOvercommit {
<#
.SYNOPSIS
    Obtains physical memory and virtual memory information for one or more ESXi hosts and compares them to evaluate memory overcommitment.

.DESCRIPTION
    Obtains physical memory and virtual memory information for one or more ESXi hosts (or for a cluster if the Cluster parameter is used) and compares them to evaluate memory overcommitment.
        
    The memory overcommitment is evaluated by comparing the memory allocated to the running VMs for each ESXi host and the physical RAM on this host.

.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default is Localhost.

.PARAMETER VMhosts
    To specify one or more ESXi hosts.
    The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.
    This parameter has 2 aliases : "Hosts" and "Servers".

.PARAMETER Cluster
    Outputs global values for the specified cluster

.PARAMETER Quiet
    This mode only outputs a boolean value for each ESXi host (or for the cluster if the Cluster parameter is used) :
    $True if there is overcommitment, $False if not.

.EXAMPLE 
    Get-MemoryOvercommit -Cluster Production

    Obtains physical RAM, vRAM and overcommitment information, providing global values for the cluster called Production.

.EXAMPLE 
    Get-VMHost EsxDev5* | Get-MemoryOvercommit

    Obtains physical RAM, vRAM and overcommitment information for each ESXi host with a name starting with EsxDev5, using pipeline input.

.EXAMPLE
    Get-MemoryOvercommit -Quiet

    Outputs a boolean value stating whether there is RAM overcommitment or not, for each ESXi host managed by the connected vCenter Server.
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
    [switch]$Quiet
    )

    Begin {
        if(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
            Add-PSSnapin VMware.VimAutomation.Core }

        Set-PowercliConfiguration -InvalidCertificateAction "Ignore" -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null

        If (-not($defaultVIServer)) {
            Connect-VIServer $VIServer
        }
        Else {
            Write-Verbose "Already connected the vCenter Server: $defaultVIServer" 
        }
        # Clearing the default parameter values in the function's scope
        $PSDefaultParameterValues.Clear()
        
        If (-not ($PSBoundParameters.ContainsKey('VMhosts')) ) {
            $VMhosts = Get-VMHost
        }
        # Getting all hosts from the cluster(s) if the -Cluster parameter is specified
        If ($PSBoundParameters.ContainsKey('Cluster')) {
            $VMhosts = Get-Cluster -Name $Cluster | Get-VMHost
        }
        # Preparing a collection to store information for each individual ESXi host
        $OvercommitInfoCollection = @()
    }

    Process {

        Foreach ($VMhost in $VMhosts) {
            
            $PhysRAM = [Math]::Round($VMhost.MemoryTotalGB, 2)
            $HostPoweredOnvRAM = [Math]::Round((Get-VM -Location $VMhost | Where-Object {$_.PowerState -eq "PoweredOn" } | Measure-Object MemoryGB -Sum).Sum, 2)
            Write-Verbose "`$PhysRAM for $VMhost is : $PhysRAM"
            Write-Verbose "`$HostPoweredOnvRAM for $VMhost is : $HostPoweredOnvRAM"

            # Building the properties for our custom object
            $OvercommitInfoProperties = [ordered]@{'ESXi Host'=$VMhost.Name                    
                    'Physical RAM (GB)'=$PhysRAM
                    'Total vRAM (GB)'=[Math]::Round((Get-VM -Location $VMhost | Measure-Object MemoryGB -Sum).Sum, 2)
                    'PoweredOn vRAM (GB)'=if ($HostPoweredOnvRAM) {$HostPoweredOnvRAM} Else { 0 -as [int] }
                    'vRAM/Physical RAM ratio'=if ($HostPoweredOnvRAM) {[Math]::Round(($HostPoweredOnvRAM / $PhysRAM), 3)} Else { $null }
                    'RAM Overcommit (%)'=if ($HostPoweredOnvRAM) {[Math]::Round(100*(($HostPoweredOnvRAM - $PhysRAM) / $PhysRAM), 2)} Else { $null }
                    }           

            # Building a custom object from the list of properties above
            $OvercommitInfoObj = New-Object -TypeName PSObject -Property $OvercommitInfoProperties

            If ($Quiet) {
                $OvercommitInfoBoolean = $HostPoweredOnvRAM -gt $PhysRAM
                $OvercommitInfoCollection += $OvercommitInfoBoolean
            }
            Else {  
                $OvercommitInfoCollection += $OvercommitInfoObj
            }
        }
    }
    End {
        If ($PSBoundParameters.ContainsKey('Cluster')) {

            $ClusterPoweredOnvRAM = [Math]::Round((Get-VM -Location $Cluster | Where-Object {$_.PowerState -eq "PoweredOn" } | Measure-Object MemoryGB -Sum).Sum, 2)
            $ClusterPhysRAM = [Math]::Round(($VMhosts | Measure-Object MemoryTotalGB -Sum).Sum, 2)
            Write-Verbose "`$ClusterPoweredOnvRAM for $Cluster is : $ClusterPoweredOnvRAM"
            Write-Verbose "`$ClusterPhysRAM for $Cluster is : $ClusterPhysRAM"

            # Building a custom object specific to the -Cluster parameter
            $ClusterOvercommitProperties = [ordered]@{'Cluster Name'=$Cluster                    
                    'Physical RAM (GB)'=$ClusterPhysRAM
                    'Total vRAM (GB)'=[Math]::Round(($OvercommitInfoCollection."Total vRAM (GB)" | Measure-Object -Sum).Sum, 2)
                    'PoweredOn vRAM (GB)'=if ($ClusterPoweredOnvRAM) {$ClusterPoweredOnvRAM} Else { 0 -as [int] }
                    'vRAM/Physical RAM ratio'=if ($ClusterPoweredOnvRAM) {[Math]::Round(($ClusterPoweredOnvRAM / $ClusterPhysRAM), 3)} Else { $null }
                    'RAM Overcommit (%)'=if ($ClusterPoweredOnvRAM) {[Math]::Round(100*(( $ClusterPoweredOnvRAM - $ClusterPhysRAM) / $ClusterPhysRAM), 2)} Else { $null }
                    }     
            
            $ClusterOvercommitObj = New-Object -TypeName PSObject -Property $ClusterOvercommitProperties

            If ($Quiet) {
                $ClusterOvercommitBoolean = $ClusterPoweredOnvRAM -gt $ClusterPhysRAM
                $ClusterOvercommitBoolean
            }
            
            Else { $ClusterOvercommitObj
            }
        }
        Else { $OvercommitInfoCollection }
    }
}
function Get-StorageOvercommit {
<#
.SYNOPSIS
    Obtains the used space, provisioned space and capacity for one or more datastores to evaluate storage overcommitment.


.DESCRIPTION
    Obtains the used space, provisioned space and capacity for one or more datastores and compares them to evaluate storage overcommitment.

    "Storage overcommitment" is evaluated by comparing the provisioned space for all VMs in the datastore (or datastore cluster) with its capacity.

    This storage overcommitment is possible only when there are thin provisioned VMDKs and this doesn't take into account thin provisioning at the LUN level which may be provided by the storage array.
    The VMs provisioned space includes the space provisioned for all VMDKs, snapshots, linked clones, swap files and VM logs.
        
.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default is Localhost.

.PARAMETER Datastore
    To specify one or more datastores.
    The default will query all datastores managed by the vCenter Server you are connected to in PowerCLI.
    This parameter has an alias : "Storage".

.PARAMETER Cluster
    Outputs global values for the specified datastore cluster

.PARAMETER Quiet
    This mode only outputs a boolean value for each datastore (or for the datastore cluster if the Cluster parameter is used) :
    $True if there is overcommitment, $False if not.

.EXAMPLE 
    Get-StorageOvercommit -Cluster Production

    Obtains the used space, provisioned space and capacity, providing global values for the datastore cluster called Production.

.EXAMPLE 
    Get-Datastore iSCSI* | Get-StorageOvercommit

    Obtains the used space, provisioned space and capacity for each datastore with a name starting with iSCSI, using pipeline input.

.EXAMPLE
    Get-StorageOvercommit -Quiet

    Outputs a boolean value stating whether there is storage overcommitment or not, for each datastore managed by the connected vCenter Server.
  #>

    [cmdletbinding()]
    param(
    [string]$VIServer = "localhost",
    [Parameter(ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName=$True,
    Position=0)]
    [Alias('Storage')]
    [VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.VmfsDatastoreImpl[]]$Datastore,
    [string]$Cluster,
    [switch]$Quiet
    )

    Begin {
        if(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
            Add-PSSnapin VMware.VimAutomation.Core }

        Set-PowercliConfiguration -InvalidCertificateAction "Ignore" -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null

        If (-not($defaultVIServer)) {
            Connect-VIServer $VIServer
        }
        Else {
            Write-Verbose "Already connected the vCenter Server: $defaultVIServer" 
        }
        # Clearing the default parameter values in the function's scope
        $PSDefaultParameterValues.Clear()
        
        If (-not ($PSBoundParameters.ContainsKey('Datastore')) ) {
            $Datastore = Get-Datastore
        }
        # Getting all hosts from the cluster(s) if the -Cluster parameter is specified
        If ($PSBoundParameters.ContainsKey('Cluster')) {
            $Datastore = Get-Datastore -Location $Cluster
        }
        # Preparing a collection to store information for each individual ESXi host
        $OvercommitInfoCollection = @()
    }

    Process {

        Foreach ($Store in $Datastore) {
            
            $UsedSpace = [Math]::Round(((Get-VM -Datastore $Store).UsedSpaceGB | Measure-Object -Sum).Sum, 2)
            $ProvisionedSpace = [Math]::Round(((Get-VM -Datastore $Store).ProvisionedSpaceGB | Measure-Object -Sum).Sum, 2)
            Write-Verbose "`$UsedSpace for $Store is : $UsedSpace"
            Write-Verbose "`$ProvisionedSpace for $Store is : $ProvisionedSpace"

            # Building the properties for our custom object
            $OvercommitInfoProperties = [ordered]@{'Datastore'=$Store.Name                   
                    'Capacity (GB)'=$Store.CapacityGB
                    'Used Space (GB)'=if ($UsedSpace) { $UsedSpace } Else { 0 -as [int] }
                    'Provisioned Space (GB)'=if ($ProvisionedSpace) { $ProvisionedSpace } Else { 0 -as [int] }
                    'Provisioned / Capacity ratio'=if ($ProvisionedSpace) {[Math]::Round(($ProvisionedSpace / $Store.CapacityGB), 3)} Else { $null }
                    'Storage Overcommit (%)'=if ($ProvisionedSpace) {[Math]::Round(100*(($ProvisionedSpace - $Store.CapacityGB) / $Store.CapacityGB), 2)} Else { $null }
                    }           

            # Building a custom object from the list of properties above
            $OvercommitInfoObj = New-Object -TypeName PSObject -Property $OvercommitInfoProperties

            If ($Quiet) {
                $OvercommitInfoBoolean = $ProvisionedSpace -gt $Store.CapacityGB
                $OvercommitInfoCollection += $OvercommitInfoBoolean
            }
            Else {  
                $OvercommitInfoCollection += $OvercommitInfoObj
            }
        }
    }
    End {
        If ($PSBoundParameters.ContainsKey('Cluster')) {
            
            $ClusterCapacity = [Math]::Round(((Get-DatastoreCluster $Cluster).CapacityGB | Measure-Object -Sum).Sum, 2)
            $ClusterUsedSpace = [Math]::Round(((Get-VM -Datastore $Cluster).UsedSpaceGB | Measure-Object -Sum).Sum, 2)
            $ClusterProvisionedSpace = [Math]::Round(((Get-VM -Datastore $Cluster).ProvisionedSpaceGB | Measure-Object -Sum).Sum, 2)
            Write-Verbose "`$ClusterCapacity for $Cluster is : $ClusterCapacity"
            Write-Verbose "`$UsedSpace for $Cluster is : $UsedSpace"
            Write-Verbose "`$ProvisionedSpace for $Cluster is : $ProvisionedSpace"
            
            # Building a custom object specific to the -Cluster parameter
            $ClusterOvercommitProperties = [ordered]@{'Datastore Cluster'=$Cluster                    
                    'Capacity (GB)'=$ClusterCapacity
                    'Used Space (GB)'=if ($ClusterUsedSpace) { $ClusterUsedSpace } Else { 0 -as [int] }
                    'Provisioned Space (GB)'=if ($ClusterProvisionedSpace) { $ClusterProvisionedSpace } Else { 0 -as [int] }
                    'Provisioned / Capacity ratio'=if ($ClusterProvisionedSpace) {[Math]::Round(($ClusterProvisionedSpace / $ClusterCapacity), 3)} Else { $null }
                    'Storage Overcommit (%)'=if ($ClusterProvisionedSpace) {[Math]::Round(100*(( $ClusterProvisionedSpace - $ClusterCapacity) / $ClusterCapacity), 2)} Else { $null }
                    }     
            
            $ClusterOvercommitObj = New-Object -TypeName PSObject -Property $ClusterOvercommitProperties

            If ($Quiet) {
                $ClusterOvercommitBoolean = $ClusterProvisionedSpace -gt $ClusterCapacity
                $ClusterOvercommitBoolean
            }
            
            Else { $ClusterOvercommitObj
            }
        }
        Else { $OvercommitInfoCollection }
    }
}
