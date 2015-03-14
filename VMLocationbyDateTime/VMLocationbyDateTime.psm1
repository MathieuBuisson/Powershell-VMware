#Requires -Version 3

function Get-VMHostbyDateTime {

<#
.SYNOPSIS
    Tracks on which host was one (or more) VM(s) over a date or time range.

.DESCRIPTION
    Tracks on which host was one (or more) VM(s) over a date or time range.
    Useful to track VM location and migrations in a cluster where DRS is in fully automated mode.
    It shows when the VM has changed host , the source and destination host, and the reason of the move.

    If the source and destination hosts are the same for an output entry, the migration was a Storage vMotion.
    If the source host is empty for an output entry, it was not a migration, but a start or restart of the VM.

.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default is Localhost.

.PARAMETER VM
    To specify one or more VMs.

.PARAMETER After
    To get the VM location(s) and migration(s) during a time range starting from the specified point in time.
    If no value is specified, the default is 180 days ago, which is the default retention policy for events in the vCenter database.
    The precision is up to the second and it is using the vCenter local time.

.PARAMETER Before
    To get the VM location(s) and migration(s) during a time range ending at the specified point in time.
    If no value is specified, the defaut is : now.
    The precision is up to the second and it is using the vCenter local time.

.EXAMPLE 
    Get-VM BigVM | Get-VMHostbyDateTime -After (Get-Date).AddMonths(-1)

    Tracks the location(s) and migration event(s) over the last month for the VM named BigVM

.EXAMPLE
    Get-VM BigVM | Get-VMHostbyDateTime -After "01/16/2015 13:16" -Before "01/16/2015 18:04"

    Tracks the location(s) and migration event(s) the 16th of January between 13:16 and 18:04 for the VM named BigVM

.EXAMPLE
    Get-VMHostbyDateTime -VM (Get-VM) -After "03/13/2015"

    Tracks the location(s) and migration event(s) for all VMs since the 13th of March 2015.

.OUTPUTS
    One or more objects of the type VMLocationbyDateTime.VMLocation
#>

    [cmdletbinding()]
    param(
        [string]$VIServer = "localhost",
        [Parameter(Mandatory = $True,ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName=$True,Position=0)]        
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl[]]$VM,
        [datetime]$After = (Get-Date).AddDays(-180), 
        [datetime]$Before = (Get-Date)
    )

    Begin {
        # Checking if the required PowerCLI snapin is loaded, if not, loading it
        if(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
            Add-PSSnapin VMware.VimAutomation.Core }

        Set-PowercliConfiguration -InvalidCertificateAction "Ignore" -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null

        if (-not($defaultVIServer)) {
            Connect-VIServer $VIServer | Out-Null
        }
        Else {
            Write-Verbose "Already connected the vCenter Server: $defaultVIServer" 
        }
        # Preparing a collection to store the output objects
        $LocationCollection = @()
    }
    Process {
        Foreach ($iVM in $VM) {

            $iVMEvents = Get-VIEvent -Entity $iVM -Start $After -Finish $Before | Where-Object { $_.GetType().name -eq "VmPoweredOnEvent" -or $_.GetType().name -eq "VmStartingEvent" -or $_.GetType().name -like "*VmMigrated*" }
            
            # Sorting the events for each VM in chronological order
            $iVMSortedEvents = $iVMEvents | Sort-Object -Property CreatedTime

            Foreach ($Event in $iVMSortedEvents) {

                # Building the properties of our custom output object
                $EventProps = [ordered]@{'VM' = $Event.VM.Name
						        'DateTime' = $Event.CreatedTime
						        'SourceHost' = $Event.SourceHost.Name
						        'DestinationHost' = $Event.Host.Name
						        'Reason' = $Event.GetType().Name
                            }
			    $VMHostobj = New-Object -TypeName PSObject -Property $EventProps

                # Adding a type for our custom output object to link that type to a custom formatting view defined in VMLocationbyDateTime.ps1xml
                $VMHostobj.PSObject.Typenames.Insert(0,'VMLocationbyDateTime.VMLocation')
                $LocationCollection += $VMHostobj
            }            
        }
    }
    End {
        $LocationCollection
    }
}