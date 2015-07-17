##Description :

When a problem appears in a vSphere environnment, we need to know what changed or what happened prior to the problem appearing, to troubleshoot it.

Sometimes, the customer doesn’t know or is not sure.
Sometimes, the customer says : “Nothing changed”, but we might not entirely trust him/her.

There are cases where we know what happened but we are not sure if it was a user-initiated action.

Also, we might need to track the actions initiated by a specific user.

To help get this information, the **Audit-vCenterOperation** cmdlet extracts relevant information from vCenter events and allows to filter them down in several different ways. 

It can filter the operations on a start date, an end date, the user who initiated the operations, the vCenter object(s)targeted by the operation, and the type of operations. 
It outputs relevant vCenter events and user-friendly information from these events. 
By default, the operations are sorted in chronological order to facilitate auditing and historical tracking of events or configuration changes. 

Requires PowerCLI 5.5 or later and Powershell 3.0 or later. 

##Parameters :

**VIServer :** To specify the vCenter Server to connect PowerCLI to. The default is Localhost.

**Entity :** To filter the operations down to those which targeted the specified vCenter inventory object(s). 
It needs to be one or more PowerCLI object(s) representing one or more VM(s), VMHost(s), cluster(s) or datacenter(s).

**Username :** To filter the operations down to those which were initiated by the specified user

**Start :** To retrieve only the operations which occurred after the specified date (or date and time). The valid formats are dd/mm/yyyy or mm/dd/yyyy, depending on the local machine regional settings.

**Finish :** To retrieve only the operations which occurred before the specified date (or date and time). The valid formats are dd/mm/yyyy or mm/dd/yyyy, depending on the local machine regional settings. 

**OperationType :** To filter the operations down to a specific type or topic. 
The possible values are : Create, Reconfigure, Remove, DRS, HA, Password, Migration, Snapshot, Power, Alarm, Datastore, Permission.