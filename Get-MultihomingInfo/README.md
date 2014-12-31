DESCRIPTION :

This module contains one cmdlet : Get-MultihomingInfo, which has the alias "mhi".

Obtains IP configuration information of all the VMkernel interfaces for one or more ESXi hosts and determines if the Multihoming configuration of the ESXi host is correct or not.

A correct Multihoming configuration means that the VMkernel interfaces for each type of traffic are in different IP subnets.
More information : http://kb.vmware.com/kb/2010877

This cmdlet obtains the following information for each VMkernel interface :
Name, IP Address, SubnetMask, Subnet, Type of VMkernel traffic and whether or not Multihoming is correctly configured.

It requires Powershell version 3 and the PowerCLI snap-ins for vSphere.

PARAMETERS :

VIServer : To specify the vCenter Server to connect PowerCLI to.
The default is Localhost.

VMhosts : To specify one or more ESXi hosts.

The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.
This parameter has 2 aliases : "Hosts" and "Servers".

Cluster : To query all the ESXi hosts in the specified cluster.

Quiet : This mode only outputs a boolean value for each ESXi host : $True if Multihoming is correctly configured, $False if not.