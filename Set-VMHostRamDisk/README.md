##Description :

This module contains 1 cmdlet : **Set-VMHostRamDisk**. 		
It work with PowerCLI 5.5 (or later).

It configures the memory allocation (reservation, limit and whether the reservation is expandable) of a RAMDisk for one or more ESXi hosts.


###Parameters :

**VIServer :** To specify the vCenter Server to connect PowerCLI to.  
The default is Localhost.

**Host :** To specify one or more ESXi hosts.
    The default obtains information for all the hosts in the connected vCenter.		

**RamDisk :** To specify the RAMDisk to configure.		
    Possible values : "tmp","root", or "hostdstats".

**Reservation :** To configure the memory guaranteed to the specified RAMDisk in MB.		

**Limit :** To configure the maximum amount of memory which can be allocated to the specified RAMDisk in MB.		

**ExpandableReservation :** To specify that more than the reservation can be allocated to the specified RAMDisk if there are available resources in the parent resource pool.