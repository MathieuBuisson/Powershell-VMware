##Description :

This module contains 3 cmdlets : **Get-CPUOvercommit**, **Get-MemoryOvercommit** and **Get-StorageOvercommit**.  
It requires Powershell version 3 (or later) and the PowerCLI 5.5 (or later).

##Get-CPUOvercommit :

Obtains the number of vCPUs and the number of physical CPU cores for one or more ESXi hosts (or for a cluster if the Cluster parameter is used) and compares them to evaluate CPU overcommitment.
        
The CPU overcommitment is evaluated by comparing the number of vCPUs of all the running VMs for each ESXi host and the number of physical cores on this host.

###Parameters :

**VIServer :** To specify the vCenter Server to connect PowerCLI to.
The default is Localhost.

**VMhosts :** To specify one or more ESXi hosts. The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.  
This parameter has 2 aliases : "Hosts" and "Servers".

**Cluster :** Outputs global values for the specified cluster

**Quiet :** This mode only outputs a boolean value for each ESXi host (or for the cluster if the Cluster parameter is used) : $True if there is overcommitment, $False if not.

##Get-MemoryOvercommit :

Obtains physical memory and virtual memory information for one or more ESXi hosts (or for a cluster if the Cluster parameter is used) and compares them to evaluate memory overcommitment.
        
The memory overcommitment is evaluated by comparing the memory allocated to the running VMs for each ESXi host and the physical RAM on this host.

###Parameters :

The same as for Get-CPUOvercommit

##Get-StorageOvercommit :

Obtains the used space, provisioned space and capacity for one or more datastores and compares them to evaluate storage overcommitment.

"Storage overcommitment" is evaluated by comparing the provisioned space for all VMs in the datastore (or datastore cluster) with its capacity.

This storage overcommitment is possible only when there are thin provisioned VMDKs and this doesn't take into account thin provisioning at the LUN level which may be provided by the storage array.
The VMs provisioned space includes the space provisioned for all VMDKs, snapshots, linked clones, swap files and VM logs.

###Parameters :

**VIServer :** To specify the vCenter Server to connect PowerCLI to.
The default is Localhost.

**Datastore :** To specify one or more datastores. The default will query all datastores managed by the vCenter Server you are connected to in PowerCLI.  
This parameter has an alias : **Storage**.

**Cluster :** Outputs global values for the specified datastore cluster

**Quiet :** This mode only outputs a boolean value for each datastore (or for the datastore cluster if the Cluster parameter is used) : $True if there is overcommitment, $False if not.
