##Description

Esxi log files are plain text, which makes them quite difficult to process with Powershell.
This Powershell module converts each line in ESXi log files into a Powershell object, allowing further processing.
This module contains 3 cmdlets : **Get-ESXiLogWithDate**, **Convert-ESXiLogToLocalTime** and **Measure-ESXiLogTimeSpan**.

It works with the following log file types : auth.log, esxupdate.log, fdm.log, hostd.log, hostd-probe.log, shell.log,
storagerm.log, syslog.log, usb.log, vmauthd.log, vmkdevmgr.log, vmkernel.log, vmksummary.log, vmkwarning.log, vobd.log
and vpxa.log.

##Get-ESXiLogWithDate :

Converts each line in ESXi log files into a Powershell object.
Each log entry object has a property called Timestamp which is itself a datetime object, this allows the log entry
objects to be easily filtered, altered, sorted, grouped, measured, etc...
It takes one or more log files (or folders) as input and outputs custom objects with typename : ESXi.LogEntry.

There is a custom formatting view for the ESXi.LogEntry object so that its default formatting looks like the line in
the original log file.

##Convert-ESXiLogToLocalTime :

Converts the ESXi log entries TimeStamp property from UTC time to local time, using the
time zone information from the local operating system.
It takes one or more objects of type ESXi.LogEntry, generally piped from the Get-ESXiLogWithDate cmdlet and outputs
objects of the same type, only their TimeStamp property is converted.

##Measure-ESXiLogTimeSpan :

Takes one or more objects of type ESXi.LogEntry, piped from the Get-ESXiLogWithDate or 
Convert-ESXiLogToLocalTime cmdlets and measures the duration covered by the input logs.
It outputs one object of the type : System.TimeSpan and the precision is to the second.

##Usage :

Requires Powershell version 3.

To use this modules, the folder ESXiLogDateTime should be copied to C:\Program Files\WindowsPowerShell\Modules to leverage
module auto-loading and to avoid having to edit the path of the root module file in the module manifest (ESXiLogDateTime.psd1).

For the full help information and usage examples, run :
`Help Get-ESXiLogWithDate -Full`  

or  
`Help Convert-ESXiLogToLocalTime -Full`  

or  
`Help Measure-ESXiLogTimeSpan -Full`
