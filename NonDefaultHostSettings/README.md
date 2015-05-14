##Description :

This module contains 2 cmdlets : **Get-NonDefaultAdvancedSettings** and **Set-AdvancedSettingsToDefaults**.  
It requires PowerCLI 5.5 or later and Powershell 3.0 or later.  

##Get-NonDefaultAdvancedSettings :

###Parameters :

**VIServer :** To specify the vCenter Server to connect PowerCLI to. The default is Localhost.

**VMHost :** To specify one or more ESXi hosts.  
The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.  
This parameter has 2 aliases : "Hosts" and "Servers".

##Set-AdvancedSettingsToDefaults :

###Parameters :

**VIServer :** To specify the vCenter Server to connect PowerCLI to. The default is Localhost.

**VMHost :** To specify one or more ESXi hosts.  
The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.  
This parameter has 2 aliases : "Hosts" and "Servers".