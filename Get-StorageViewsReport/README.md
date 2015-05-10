##Description :

Obtains storage capacity and utilization information by datastore, by VM or by ESXi host.  
This provides the same information as the Storage Views reports, feature which has been removed from vSphere 6.0.  
The default mode is by datastore.

Requires PowerCLI 5.5 or later and Powershell 3.0 or later.  

##Parameters :

**VIServer :** To specify the vCenter Server to connect PowerCLI to. The default is Localhost.

**ByVM :** To obtain storage capacity and utilization information by VM.

**VM :** Used in the "ByVM" mode, to specify one or more VMs.  
The default obtains information for all the VMs in the connected vCenter.

**ByDatastore :** To obtain storage capacity and utilization information by datastore.

**Datastore :** Used in the "ByDatastore" mode, to specify one or more datastores.  
The default obtains information for all the datastores in the connected vCenter.

**ByHost :** To obtain storage capacity and utilization information by ESXi host.

**Host :** Used in the "ByHost" mode, to specify one or more ESXi hosts.  
The default obtains information for all the hosts in the connected vCenter.
