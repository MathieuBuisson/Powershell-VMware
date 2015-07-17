#Requires -Version 3

function Audit-vCenterOperation {
<#
.SYNOPSIS
    Obtains vCenter events and filters them to meaningful vCenter operations.
    It can filter the operations on a start date, an end date, the user who initiated the operations, the vCenter object(s) and the type of operations.

.DESCRIPTION
    Obtains vCenter events and filters them to meaningful vCenter operations.
    It can filter the operations on a start date, an end date, the user who initiated the operations, the vCenter object(s) targeted by the operation, and the type of operations.
    It outputs relevant vCenter events and user-friendly information from these events.
    By default, the operations are sorted in chronological order to facilitate auditing and historical tracking of events or configuration changes.

.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default is Localhost.

.PARAMETER Entity
    To filter the operations down to those which targeted the specified vCenter inventory object(s).
    It needs to be one or more PowerCLI object(s) representing one or more VM(s), VMHost(s), cluster(s) or datacenter(s).

.PARAMETER Username
    To filter the operations down to those which were initiated by the specified user

.PARAMETER Start
    To retrieve only the operations which occurred after the specified date (or date and time). The valid formats are dd/mm/yyyy or mm/dd/yyyy, depending on the local machine regional settings.

.PARAMETER Finish
    To retrieve only the operations which occurred before the specified date (or date and time). The valid formats are dd/mm/yyyy or mm/dd/yyyy, depending on the local machine regional settings.

.PARAMETER OperationType
    To filter the operations down to a specific type or topic.
    The possible values are : 
    Create, Reconfigure, Remove, DRS, HA, Password, Migration, Snapshot, Power, Alarm, Datastore, Permission

.EXAMPLE 
    Get-Cluster Test-Cluster | Audit-vCenterOperation -OperationType Reconfigure

    To track when the configuration of the cluster "Test-Cluster" was changed and by who.
    
.EXAMPLE 
    Audit-vCenterOperation -OperationType Migration -Start (Get-Date).AddDays(-7)

    To track all the migrations (vMotion and Storage vMotion) for all VMs which occurred during the last 7 days.

.EXAMPLE
    Get-VMHost | Audit-vCenterOperation -Username "User01" -OperationType Power

    To verify if the user "User01" has initiated a power operation on a ESXi host.
#>

    [cmdletbinding()]
    param(
        [string]$VIServer = "localhost",
        [Parameter(ValueFromPipeline = $True,Position=0)]
        [ValidateScript({ $($_[0].GetType()).Namespace -eq "VMware.VimAutomation.ViCore.Impl.V1.Inventory" })]
        $Entity,
        [string]$Username,
        [datetime]$Start,
        [datetime]$Finish,
        [ValidateSet("Create","Reconfigure","Remove","DRS","HA","Password","Migration","Snapshot","Power","Alarm","Datastore","Permission")]
        [string]$OperationType
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

        # Modifying $PSBoundParameters to feed the parameters to Get-VIEvent
        $PSBoundParameters.Remove('VIServer') | Out-Null
        If ($PSBoundParameters.ContainsKey('OperationType')) {
            $PSBoundParameters.Remove('OperationType') | Out-Null
        }
        $MaxNumEvents = 1000000000
        $PSBoundParameters.Add('MaxSamples',$MaxNumEvents)

        Write-Verbose "Bound Parameters Sent to Get-VIEvent :  $($PSBoundParameters.Keys)"
        
        # Preparing an empty collection to store the output objects
        $OutputObjectCollection = @()
    }
    Process {
        $AllEvents =  Get-VIEvent @PSBoundParameters | Where-Object { $_.FullFormattedMessage -notlike "*Check Notification*" -and $_.FullFormattedMessage -notlike "*unknown agent*" -and $_.FullFormattedMessage -notlike "*Update Download*" -and $_.FullFormattedMessage -notlike "*API invocations*" }
        $AllActions = $AllEvents | Where-Object { $_.UserName -and $_.UserName -ne "vpxuser" }

        # Sorting the actions by date and time to facilitate historical tracking
        $SortedActions = $AllActions | Sort-Object -Property CreatedTime
        Write-Verbose "`$SortedActions contains $($SortedActions.Count) events"
        
        If ($OperationType) {
            Write-Verbose "Filtering for actions of the type : $OperationType "
            switch ($OperationType)
            {
               "Create" {
                    $FilteredActions = $SortedActions | Where-Object { $_.FullFormattedMessage -like "*Creat*" -and $_.FullFormattedMessage -notlike "*Snapshot*" }
               }
               "Reconfigure" {
                    $FilteredActions = $SortedActions | Where-Object { $_.FullFormattedMessage -like "*Reconfigur*" -or $_.FullFormattedMessage -like "*Modif*" }
               }
               "Remove" {
                    $FilteredActions = $SortedActions | Where-Object { $_.FullFormattedMessage -like "*Remov*" -and $_.FullFormattedMessage -notlike "*Snapshot*" }
               }
               "DRS" {
                    $FilteredActions = $SortedActions | Where-Object { $_.FullFormattedMessage -like "*DRS*" }
               }               
               "HA" {
                    $FilteredActions = $SortedActions | Where-Object { $_.FullFormattedMessage -like "*vSphere HA*" }
               }

               "Password" {
                    $FilteredActions = $SortedActions | Where-Object { $_.FullFormattedMessage -like "*Password*" }
               }
               "Migration" {
                    $FilteredActions = $SortedActions | Where-Object { $_.FullFormattedMessage -like "*Migrat*" }
               }
                "Snapshot" {
                    $FilteredActions = $SortedActions | Where-Object { $_.FullFormattedMessage -like "*Snapshot*" -or $_.FullFormattedMessage -like "*consolidat*" }
               }
               "Power" {
                    $FilteredActions = $SortedActions | Where-Object { $_.FullFormattedMessage -like "*Power*" -or $_.FullFormattedMessage -like "*Reset*" -or $_.FullFormattedMessage -like "*Restart*" -or $_.FullFormattedMessage -like "*Reboot*" -and $_.FullFormattedMessage -notlike "*Service*" -and $_.FullFormattedMessage -notlike "*No operating system*"}
               }
               "Alarm" {
                    $FilteredActions = $SortedActions | Where-Object { $_.FullFormattedMessage -like "*Alarm*" -or $_.FullFormattedMessage -like "*Yellow*" -or $_.FullFormattedMessage -like "*Green*" }
               }
               "Datastore" {
                    $FilteredActions = $SortedActions | Where-Object { $_.FullFormattedMessage -like "*Datastore*" }
               }
               "Permission" {
                    $FilteredActions = $SortedActions | Where-Object { $_.FullFormattedMessage -like "*Permission*" -or $_.FullFormattedMessage -like "*Role*" }
               }
            } # End switch
        } # End If
        Else {
            $FilteredActions = $SortedActions
        }
        Write-Verbose "`$FilteredActions contains $($FilteredActions.Count) events"

        foreach ( $FilteredAction in $FilteredActions) {

            # Building the properties of our custom output object
            $Props = [ordered]@{
			    'Key' = $FilteredAction.Key
			    'CreatedTime' = $FilteredAction.CreatedTime
			    'UserName' = $FilteredAction.UserName
			    'Datacenter' = $FilteredAction.Datacenter.Name
			    'ComputeResource' = $FilteredAction.ComputeResource.Name
                'Host' = $FilteredAction.Host.Name
                'Vm' = $FilteredAction.Vm.Name
                'Message' = $FilteredAction.FullFormattedMessage
            }
		    $OutputObject = New-Object -TypeName PSObject -Property $Props
            $OutputObjectCollection += $OutputObject
        }
    }
    End {
        Write-Verbose "Executed End block"
        Write-Verbose "`$FilteredActions contains $($FilteredActions.Count) events"

        $OutputObjectCollection
    }
}