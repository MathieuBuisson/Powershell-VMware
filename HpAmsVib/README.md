DESCRIPTION :

This module contains 2 cmdlets : Find-BadHpAmsVib and Remove-BadHpAmsVib.
It requires Powershell version 3 (or later) and the PowerCLI 5.5 (or later).

FIND-BADHPAMSVIB :

Looks for the hp-ams VIB installed on one or more ESXi hosts and displays them if they are in a version affected by the "Can't fork" bug.

More information on this bug : http://kb.vmware.com/kb/2085618 .

No output means that there is no ESXi host with the hp-ams VIB, or the installed version(s) of the hp-ams VIB(s) are not affected.

PARAMETERS :

VIServer : To specify the vCenter Server to connect PowerCLI to.
The default is Localhost.

VMhosts : To specify one or more ESXi hosts. The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.
This parameter has 2 aliases : "Hosts" and "Servers".

Cluster : To query all the ESXi hosts in the specified cluster.

REMOVE-BADHPAMSVIB :

Looks for and uninstalls the hp-ams VIB installed on one or more ESXi hosts if they are in a version affected by the "Can't fork" bug.

More information on this bug : http://kb.vmware.com/kb/2085618

PARAMETERS :

VIServer : To specify the vCenter Server to connect PowerCLI to.
The default is Localhost.

VMhosts : To specify one or more ESXi hosts. The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.
This parameter has 2 aliases : "Hosts" and "Servers".

Cluster : To query all the ESXi hosts in the specified cluster.

Reboot : If a hp-ams VIB has been uninstalled, puts the host in maintenance mode and reboots it.

Assumes the host is in a DRS cluster in fully automated mode.
If it is not in a DRS cluster, the running VMs will need to be evacuated manually for the host to enter maintenance mode successfully.

If it is in a DRS cluster but not in fully automated mode, the DRS recommendations will need to be applied manually for the host to enter maintenance mode successfully.

CAUTION : It does not exit maintenance mode after the reboot, so all hosts end up in maintenance mode and it will not do an orchestrated "evacuate & reboot" for all hosts in a cluster.

For this reason, this parameter is not recommended when the VMHosts parameter contains several hosts.
