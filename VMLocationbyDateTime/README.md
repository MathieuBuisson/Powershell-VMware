DESCRIPTION :

This module contains 1 cmdlet : Get-VMHostbyDateTime .

It requires Powershell version 3 (or later) and the PowerCLI 5.5 (or later).

GET-VMHOSTBYDATETIME :

Tracks on which host was one (or more) VM(s) over a date or time range.

Useful to track VM location and migrations in a cluster where DRS is in fully automated mode.
It shows when the VM has changed host, the source and destination host, and the reason of the move.

If the source and destination hosts are the same for an output entry, the migration was a Storage vMotion.
If the source host is empty for an output entry, it was not a migration, but a start or restart of the VM.

PARAMETERS :

VIServer : To specify the vCenter Server to connect PowerCLI to.
The default is Localhost.

VM : To specify one or more VMs.

After : To get the VM location(s) and migration(s) during a time range starting from the specified point in time.

If no value is specified, the default is 180 days ago, which is the default retention policy for events in the   vCenter database. The precision is up to the second and it is using the vCenter local time.

Before : To get the VM location(s) and migration(s) during a time range ending at the specified point in time.

If no value is specified, the defaut is : now. The precision is up to the second and it is using the vCenter local time.

CAUTION : The DateTime object formatting depends on the culture. Examples provided in the help were tested with the en-US culture. In this culture, the format is MM/dd/yy, this why "03/13/2015" can be cast as a valid DateTime object.

For other cultures, like en-GB or en-IE, the format is dd/MM/yy so "03/13/2015" cannot be cast as a valid DateTime.
You can use the cmdlet Get-Culture to obtain the culture of your current Powershell session.
