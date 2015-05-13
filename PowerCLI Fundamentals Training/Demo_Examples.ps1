##############################################
# Demo Preparation
##############################################
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
Set-Location $env:USERPROFILE
Remove-VIRole -Role "custom*"
Get-VM | Get-Snapshot | Remove-Snapshot
Get-VM | Get-Random -Count 2 | New-Snapshot -Name "Before_Demo_Snaps"

Clear-Host

###############################################
# What is Powershell
###############################################

$PSVersionTable


################################################
# What is PowerCLI ?
################################################

Get-PSSnapin

# What Powershell Snapins do we get with PowerCLI ?
Get-PSSnapin -Registered

#Let's load all of them into our Powershell session :
Add-PSSnapin -Name vmware*

Get-PSSnapin

#How many cmdlets does the main PowerCLI snapin provide ?
Get-Command -PSSnapin VMware.VimAutomation.Core | Measure-Object 

#How many cmdlets does PowerCLI provide in total ?
Get-Command -PSSnapin VMware* | Measure-Object

#Besides cmdlets , it also adds 2 Powershell providers
Get-PSProvider | Where-Object { $_.Name -like "Vim*" } |
Select-Object -Property Name,Drives

cd vmstores:

# Checking the PowerCLI version
Get-PowerCLIVersion

# Let's connect to a vCenter Server :
Connect-VIServer 192.168.1.10

# and verify our connection :
$DefaultVIServer

clear-host

###################################################
# Feature number 1 : discoverability
###################################################

Get-Verb

# Let's say we want to configure Distributed vSwitches but you are not sure of the cmdlet name
Get-Command -Verb Set -noun "*switch*"

# Let's find out how we can start SSH on a host with IntelliSense (Ctrl+Space)
Get-VMHost esxi55ga-1.vcloud.local | Start-V

# Learning how to use a cmdlet with a little bit of GUI
Show-Command Set-VMHostAuthentication

# Get the help information in a separate window
Get-Help Set-VMHostAuthentication -ShowWindow

# If you learn better by looking at examples :
Get-Help Remove-Datastore -Examples

# To get all sections from the cmdlet help :
Get-Help Remove-Datastore -full

Clear-Host

#####################################################
# Interpreting the cmdlet help
#####################################################

Get-Help Set-VMHostAuthentication -Full | more

# This cmdlet has 2 parameter sets : one to join a domain, and one to leave a domain

# -WhatIf : to look at what a potentially destructive command would do, without actually doing it
Get-VMHost | Remove-Inventory -WhatIf

help Get-Snapshot -Full

Get-Snapshot -VM (Get-VM) -Name "*snap*"

# When parameter names are explicitly typed, the order doesn't matter :
Get-Snapshot -Name "*snap*"-VM (Get-VM)

# These are positional parameters :
Get-Snapshot (Get-VM) "*snap*"

# Now, the order (or position) matters :
Get-Snapshot "*snap*" (Get-VM)

Clear-Host

#####################################################
# Aliases
#####################################################

# cd works just like in the traditional command prompt
cd $env:USERPROFILE

# dir as well
dir

# Even ls !
ls

# But these are just aliases to a cmdlet
Get-Alias -Name dir
Get-Alias -name ls

# Which itself, has yet another alias : gci
Get-Alias -Definition Get-ChildItem

# Listing all the alias using the Alias Powershell drive
ls alias:\

# PowerCLI doesn't add any aliases :
Get-Alias -Definition "*vm*"

# But you can create your own :
New-Alias -Name scratch -Value Set-VMHostDiagnosticPartition

# The path of our current Powershell profile
$profile

Clear-Host

#####################################################
# What is an object and what is it made of ?​
#####################################################

# Everything is an object :
$TextVariable = "I'm just plain text"

# This is an object of the type [string] :
$TextVariable.GetType() | Select-Object -Property Name, Fullname

$NumberVariable = 19

# This is an object of the type [int] :
$NumberVariable | Get-Member

# Apparently, [int] objects have no properties but they have quite a few methods

# Let's see what we can do with a [datetime] object :
Get-Date | Get-Member

# Let's look at a few of its properties :
Get-Date | Select-Object -Property Day, DayOfWeek, DayOfYear

# We can very easily extract the month information from a date :
Get-Date | Select-Object -Property Month

# To see all the properties and thir values :
Get-Date | Format-List *

# Let's try one of its methods :
(Get-Date).AddDays(-7)

Clear-Host

#####################################################
# Variables
#####################################################

$MyVar = Get-VMHost 

# Looking at its content :
$MyVar

# Looking at it by its name :
Get-Variable -Name MyVar

# Listing all the variables in the current Powershell session
gci variable:\

# We can expand our variable from inside double quotes :
Write-Output "Here is a list of ESXi hosts : $MyVar"

# But not from inside single quotes :
Write-Output 'Here is a list of ESXi hosts : $MyVar'# Expanding some variables but not all :Write-Output "Here are the hosts in `$MyVar : $MyVar"# Weird output in the ISE --> do it in a Powershell console# Browsing invidual objects in a collection :$MyVar[0]$MyVar[-1]$Myvar[-1].Name$MyVar.Name# PowerCLI-specific variables $DefaultVIServer and $DefaultVIServers$DefaultVIServer$DefaultVIServersClear-Host####################################################### Filtering objects####################################################### Getting only the VMs which are powered on :Get-VM | Where-Object -FilterScript { $_.PowerState -eq "PoweredOn" }# Getting the ESXi hosts with the name starting with "esxi55"Get-VMHost | Where { $_.Name -like "esxi55*" }# If there are hundreds of hosts, the following is more efficient :Get-VMHost -Name esxi55*# Simplified Where-Object syntax introduced with Powershell version 3 :Get-VM | where NumCpu -gt 1# -like is not case sensitive :Get-VMHost | Where-Object { $_.Name -like "EsXi55gA-1*" }# If you really want a case sensitive match, use -clike :Get-VMHost | Where-Object { $_.Name -clike "EsXi55gA-1*" }# Multiple conditions in the filterscript with "-and" :Get-VMHost |Where { $_.Parent -eq (Get-Cluster Test-Cluster) -and $_.MaxEVCMode -eq "intel-Westmere" } |Select-Object Name,MaxEVCMode# we can filter on something else than just a property# For example : getting all the VMs which have at least one snapshot :Get-VM | Where-Object { Get-Snapshot -VM $_ }# Checking if we have VMs reaching the 32 snapshots limit :Get-VM | Where-Object { (Get-Snapshot -VM $_).count -ge 32 }###################################################### Building multi-commands one-liners###################################################### Out-default at the end of the pipeline :Get-VM | where NumCpu -gt 1 | Out-Default# output to fileGet-VM | where NumCpu -gt 1 | Out-File SMP_VMs.txt# Checking the file :notepad SMP_VMs.txt# Reading the file directly in the console :Get-Content -Path SMP_VMs.txt# output to file : there is nothing left in the pipeline :Get-VM | where NumCpu -gt 1 | Out-File SMP_VMs.txt | Get-Member# Output both to a file and to the pipeline :Get-VM | where NumCpu -gt 1 | Tee-Object -FilePath SMP_VMs.txt -Append# Checking the file again:notepad SMP_VMs.txt# Exporting to a CSV file :Get-VM | where NumCpu -gt 1 | Export-Csv -Path SMP_VMs.csv -NoTypeInformationnotepad SMP_VMs.csv# Reconstructing the original objects from the CSV file :Import-Csv -Path SMP_VMs.csvImport-Csv -Path SMP_VMs.csv | Format-Table -Property Name,Powerstate,NumCPU,MemoryMB# VMHost objects are complex objects, with a whole hierarchy of sub-properties :$MyVar[0].NetworkInfo$MyVar[0].NetworkInfo.DnsAddress# XML is better at handling multi-value and hierarchical properties :$MyVar[0] | Export-Clixml -Path Host.xmlnotepad Host.xml# Complex One-liner :# Getting all powered off VMs with more than 1 vCPU and reduce their number of vCPU to 1Get-VM | where NumCpu -gt 1 | where PowerState -eq PoweredOff | Set-VM -NumCpu 1clear-Host####################################################### Sorting, grouping, selecting, measuring####################################################### Getting the VMs which are consuming the most storage spaceGet-VM | Sort-Object -Property UsedSpaceGB -Descending# Now we see the property on which we are ordering :Get-VM | Sort-Object -Property UsedSpaceGB -Descending | Select-Object Name,UsedSpaceGB# Getting the 2 VMs which are consuming the most storage spaceGet-VM | Sort-Object -Property UsedSpaceGB -Descending | Select-Object Name,UsedSpaceGB -First 2# Getting the VM which is consuming the least storage space :Get-VM | Sort-Object -Property UsedSpaceGB -Descending | Select-Object Name,UsedSpaceGB -Last 1# Let's get all the vmkernel interfaces and group them by host :Get-VMHost | Get-VMHostNetworkAdapter -VMKernel | Group-Object -Property VMHost# Now, let's expand these groups :Get-VMHost | Get-VMHostNetworkAdapter -VMKernel | Group-Object -Property VMHost | Select-Object -ExpandProperty Group# The same information + the host name :Get-VMHost | Get-VMHostNetworkAdapter -VMKernel | Select-Object VMHost,Name,Mac,IP,SubnetMask | Sort-Object VMHost,Name# Counting the number of vCenter events in the last 7 days :Get-VIEvent -Start (Get-Date).AddDays(-7) | Measure-Object# Measuring on a specific property :Get-Datastore | Measure-Object -Property FreeSpaceGB -Maximum -Minimum -AverageClear-Host####################################################### Creating custom objects####################################################### Getting the storage devices of one ESXi host :$Devices = Get-ScsiLun -VmHost esxi55ga-1.vcloud.local$Devices | Select-Object -prop CanonicalName,LunType,IsLocal# Let's what type of objects we have :$Devices | Get-Member$Select_Properties_Device = $Devices | Select-Object -prop CanonicalName,LunType,IsLocal -First 1$Select_Properties_Device | Get-Member# Get-Member tells us the object type is preserved.# But the object only have the properties we have selected and all the methods are stripped outGet-Datastore | Select-Object -Property Name,FreeSpaceMB,CapacityMB# What if we want these values in Gigabytes ?Get-Datastore | Select-Object -Property Name,@{Label="FreeSpaceGB";Expression={ $_.FreeSpaceMB / 1024 }},@{Label="CapacityMB";Expression={ $_.CapacityMB / 1024 }}# Let's round these ugly numbers at 2 decimal places :Get-Datastore | Select-Object -Property Name,@{Label="FreeSpaceGB";Expression={ [Math]::Round($_.FreeSpaceMB / 1024,2) }},@{Label="CapacityMB";Expression={ [Math]::Round($_.CapacityMB / 1024,2) }}# If we just want the percentage of free space :Get-Datastore | Select-Object -Property Name,@{Label="FreeSpace %";Expression={ $_.FreeSpaceMB / $_.CapacityMB * 100 }}# Ugly numbers again, let's get rid of the decimals :Get-Datastore | Select-Object -Property Name,@{Label="FreeSpace %";Expression={ ($_.FreeSpaceMB / $_.CapacityMB * 100) -as [int] }}####################################################### How the pipeline works####################################################### We need to restart the CIM service on the host esxi55ga-1.vcloud.localGet-VMHostService -vmhost esxi55ga-1.vcloud.local# We know the service is there, so why the below doesn't work ??Get-VMHostService -vmhost esxi55ga-1.vcloud.local | Restart-VMHostService -HostService sfcbd-watchdoghelp Restart-VMHostService -Full# The only parameter which accepts pipeline input is -HostService# It accepts pipeline input by value (object type)# What object type is it expecting ?# So, this should work :Get-VMHostService -vmhost esxi55ga-1.vcloud.local | Where key -eq sfcbd-watchdog | Restart-VMHostService# Is this going to work ?Get-Process VpxClient | Get-ChildItem# Why ?# Let's look at which parameters of Get-ChildItem can take pipeline input :Get-Help ls -Full | more# -Path : by value and by property name# Does the object which was in the pipeline have a property named "Path" ?Get-Process VpxClient | Get-Member -Name PathClear-Host####################################################### Formatting the ouput######################################################Get-ResourcePool# Format as a list :Get-ResourcePool | Format-List -Property *# Format as a table :Get-ResourcePool | Format-Table# Same ouput as without display :Get-ResourcePool | Format-Table -Property Parent,MemLimitMB,@{Label="CpuLimitGhz";Expression={ $_.CpuLimitMHz / 1024 }}# automatically size the width of the columns :Get-ResourcePool | Format-Table -Property Parent,MemLimitMB,@{Label="CpuLimitGhz";Expression={ $_.CpuLimitMHz / 1024 }} -AutoSize# Now, let's sort it by our property "CpuLimitGhz"Get-ResourcePool | Format-Table -Property Parent,MemLimitMB,@{Label="CpuLimitGhz";Expression={ $_.CpuLimitMHz / 1024 }} | Sort-Object -Property CpuLimitGhzGet-VM | Format-WideGet-VM | Format-Wide -Column 4# Gotcha number 1 :get-VM | Format-Wide | Start-VM# Why ?Get-VM | Format-Wide | Get-Member# Gotcha number 2 :Get-Command -verb Format | Format-Table -AutoSize# Let's try this formatting provided by VMware :Get-ScsiLun esxi55ga-1.vcloud.local -CanonicalName naa.6000eb360d5d81c000000000000000bb |Get-Vmhostdisk | Get-VMHostDiskPartition | Format-VMHostDiskPartition "PrettyFormatting" -WhatIf# Oops! Fortunately, we used the -WhatIf parameterClear-Host###################################################### Enumerating objects in a pipeline###################################################### Let's get the latest snapshot for each VM and add a description according to their place in the snapshot treeGet-VM | Get-Snapshot | ForEach-Object { if ( -not $_.children ) { Set-Snapshot $_ -Description "Latest Snap"Set-Snapshot $_.Parent -Description "Not the latest snap. The latest is $_"}}# Checking the result :Get-VM | Get-Snapshot | Format-Table Name,Description -AutoSize# Creating an exact copy of the vCenter admin roles for later customizationGet-VIRole | Where-Object { $_.Name -like "*Admin*" } |ForEach-Object { New-VIRole -name "custom_$_" -Privilege (Get-VIPrivilege -Role $_) }####################################################### Comparing objects####################################################### Let's modify our role custom_ResourcePoolAdministrator# Let's add the privilege to manage the hosts' system resources$Priv = Get-VIPrivilege -Id Host.Config.ResourcesSet-VIRole -Role custom_ResourcePoolAdministrator -AddPrivilege $Priv# Now, let's compare our custom role with the original :$Original = Get-VIRole -Name ResourcePoolAdministrator$Custom = Get-VIRole -Name custom_ResourcePoolAdministrator# Let's see what we have in our variables :$custom$custom.PrivilegeList# So, what we want to compare is the property "PrivilegeList" of our roles :Compare-Object -ReferenceObject $Original.PrivilegeList -DifferenceObject $Custom.PrivilegeListClear-Host####################################################### Script security####################################################### Let's double-click the .psm1 files on the desktop# Do this in the console, not the ISEcd C:\Users\Administrator\DesktopGet-ChildItem "*.ps*"# let's run our Hello_World script :Hello_World.ps1# We know the file is in our current working directory and we know the file name is correct# We get a very instructive suggestion.\Hello_World.ps1# What is our current executionPolicy :Get-ExecutionPolicySet-ExecutionPolicy -ExecutionPolicy AllSigned# Now, let's see if we can run our Hello_World script :.\Hello_World.ps1# Does it have a signature ?Get-Content .\Hello_World.ps1####################################################### Other types of pipeline######################################################Write-Error "This is an error !"Write-Warning "This is a warning !"Write-Verbose "This is verbose information."Write-Verbose "This is verbose information." -VerboseClear-Host####################################################### PowerCLI views######################################################Get-VMHost -Name esxi55ga-1.vcloud.local | Get-View# Or :Get-View -ViewType Hostsystem -Filter @{"Name"="esxi55ga-1.vcloud.local"}# Let's store it into a variable to play with it$HostView = Get-View -ViewType Hostsystem -Filter @{"Name"="esxi55ga-1.vcloud.local"}$HostView.Hardware$HostView.Hardware.PciDevice$HostView.Hardware.PciDevice | Format-Table Id,VendorName,DeviceName$HostView.Config.MultipathState.path# No APD, good# Let's create a view for all our VMs :$VMsView = Get-View -ViewType VirtualMachine$VMsView | Select-Object -Property Guest.ToolsRunningStatus, @{Label="VM Name";Expression={ (Get-VIObjectByVIView -VIView $_).Name }}# We need to build properties from hashtables to access sub-properties :$VMsView | Select-Object -Property @{Label="ToolsStatus";Expression={ $_.Guest.ToolsRunningStatus }}, @{Label="VM Name";Expression={ (Get-VIObjectByVIView -VIView $_).Name }}# Let's open a VM console to one VM in the vSphere client# Getting the number of console connections for each VM :$VMsView | select @{Label="VM Name";Expression={ (Get-VIObjectByVIView -VIView $_).Name }},  @{Label="MKS Connections";Expression={ $_.Runtime.NumMksConnections }} | ft -AutoSize# Extensiondata another way of generating a view from an existing object :$VMs = Get-VM$VMs.ExtensionData# We get the exact same information as a view$VMs.ExtensionData.Runtime.NumMksConnectionsClear-Host####################################################### Get-EsxCli####################################################### Storing the esxcli interface for a host into a variable$ESXCli = Get-EsxCli -VMHost esxi55ga-1.vcloud.local# Getting the system UUID (to troubleshoot a lock issue)$ESXCli.system.uuid.get()# getting the same information for all ESXi hosts :$VMHosts = Get-VMHostForeach ($VMhost in $VMhosts) {    $Esxcli = Get-EsxCli -VMHost $VMhost    $ESXCli.system.uuid.get()}# Getting all installed VIBs from all hosts :$VMHosts = Get-VMHostForeach ($VMhost in $VMhosts) {    $Esxcli = Get-EsxCli -VMHost $VMhost    $VibList = $Esxcli.software.vib.list()    $VibList | Add-Member -MemberType NoteProperty -Name "Host" -Value $VMHost    $VibList | ft Host,Name,Vendor,Version -AutoSize}# Uninstalling a VIB :$Esxcli.software.vib.remove($false,$true,$true,$true,"hp-ams")# What else can we do with our $ESXCli object ? A lot :explorer http://rvdnieuwendijk.com/2012/08/19/how-to-list-all-the-powercli-esxcli-commands/