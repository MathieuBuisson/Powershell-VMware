##Description :

Powershell script (packaged as a module) to automate the procedure of http://kb.vmware.com/kb/2042200 .  
It reset the database of the Inventory Service for vCenter 5.1 and 5.5.  
It requires Powershell 2.0 or later.  
It works only if the Inventory Service and SSO are installed on the same machine as the vCenter Server.

##Usage :

Because it is a module, you first need to import it, with the following command :  
`Import-Module C:\Path\To\Reset-ISdatabase.psm1`  

Then, you can use the **Reset-ISdatabase** command.
You can also use its alias : **risdb**.

It needs to be run as Administrator.

It has quite a few parameters, but it can be run without any parameter if the vCenter server is in the
default configuration.

##Parameters :

**-NoPrompt :** By default, the script prompts you to confirm that you understand the potential consequences of resetting
the Inventory Service database.  
If you want to suppress this prompt, use the -NoPrompt parameter.

**-DBpath :** Allows you to specify the path to the Inventory Service Database, if it's not the default path.

**-ScriptsPath :** Allows you to specify the path to the Inventory Service Scripts folder, if it's not the default path.

**-vCenterPort :** Allows you to specify the vCenter HTTPS port, if it's not the default.

**-ISport :** Allows you to specify the Inventory Service port, if it's not the default.

**-LookupServicePort :** Allows you to specify the Lookup Service port, if it's not the default.

**-Verbose :** By default, the function doesn't display much output on the console while running.  
If you want the function to display what it's doing on the console, use the -Verbose parameter

For the full help and usage examples, run the command :  
`Get-Help Reset-ISdatabase -Full`
