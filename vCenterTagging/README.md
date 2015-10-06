##Description :

This module contains 2 cmdlets : **Export-TagAndAssignment** and **Import-TagAndAssignment**. 

It requires Powershell 3.0 (or later) and PowerCLI 5.5 R2 (or later).

##Export-TagAndAssignment :

Exports all the tags, tag categories and tag assignments from a vCenter to a file.
This file can be used later to import all the tags, categories and assignments back into a vCenter environment.

One use case is backing up all the tagging information from a vCenter Server before resetting the Inventory Service database (which deletes all tagging information).

###Parameters :

**VIServer :** To specify the vCenter Server to connect PowerCLI to.  
The default is Localhost.

**Path :** To specify the path and name of the file the tagging data should be exported to. 	
This parameter is mandatory.


##Import-TagAndAssignment :

Imports all the tags, tag categories and tag assignments from a file to a vCenter Server.

One use case is restoring all the tagging information from a vCenter Server after resetting the Inventory Service database (which deletes all tagging information).

###Parameters :

**VIServer :** To specify the vCenter Server to connect PowerCLI to.  
The default is Localhost.

**Path :** To specify the path and name of the file the tagging data should be imported from. 	
This parameter is mandatory.
