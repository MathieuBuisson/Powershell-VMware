##Description :

This module contains 2 cmdlets : **Get-NonDefaultAdvancedSettings** and **Set-AdvancedSettingsToDefault**.  
It requires PowerCLI 5.5 or later and Powershell 3.0 or later.  

##Get-NonDefaultAdvancedSettings :

Obtains all the advanced settings which are not at their default value for one or more ESXi host.  
It output the setting(s) path, description, default value, and current value.

###Parameters :

**VIServer :** To specify the vCenter Server to connect PowerCLI to. The default is Localhost.

**VMHost :** To specify one or more ESXi hosts.  
The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.  
This parameter has 2 aliases : "Hosts" and "Servers".

##Set-AdvancedSettingsToDefault :

Sets the advanced settings which are not at their default value back to their default, for one or more ESXi host.  
Supports -WhatIf parameter to see what modification(s) it would perform, without actually performing them.  
Supports -Confirm parameter to prompt for confirmation before performing the modification(s).

###Parameters :

**VIServer :** To specify the vCenter Server to connect PowerCLI to. The default is Localhost.

**VMHost :** To specify one or more ESXi hosts.  
The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.  
This parameter has 2 aliases : "Hosts" and "Servers".