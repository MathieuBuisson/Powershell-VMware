#Requires -Version 3

function  Register-AllOrphanedVmx {
<#
.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default is Localhost.

.PARAMETER ResourcePool
    To specify in which cluster or resource pool the VMs should be registered into.

.EXAMPLE 
    Register-AllOrphanedVmx -ResourcePool ( Get-Cluster DevCluster )

#>

    [cmdletbinding()]
    param(
        [string]$VIServer = "localhost",
        [Parameter(Position=0,Mandatory=$True)]
        $ResourcePool
    )

    Begin {
        # Checking if the required PowerCLI snapin (or module) is loaded, if not, loading it
        If (Get-Module VMware.VimAutomation.Core -ListAvailable -ErrorAction SilentlyContinue) {
            If (-not (Get-Module VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
	            Import-Module VMware.VimAutomation.Core
            }
        }
        Else {
            If (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
                Add-PSSnapin VMware.VimAutomation.Core
            }
        }
        Set-PowercliConfiguration -InvalidCertificateAction "Ignore" -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null

        If (-not($defaultVIServer)) {
            Connect-VIServer $VIServer | Out-Null
        }
        Else {
            Write-Verbose "Already connected the vCenter Server: $defaultVIServer" 
        }
    }
    Process {
        $SearchResult = @()
        foreach($Datastore in (Get-Datastore -Verbose:$False)) {
           # Set up Search for .VMX Files in Datastore
           $ds = Get-Datastore -Name $Datastore -Verbose:$False| %{Get-View $_.Id -Verbose:$False}
           $SearchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
           $SearchSpec.matchpattern = "*.vmx"
           $dsBrowser = Get-View $ds.browser -Verbose:$False
           $DatastorePath = "[" + $ds.Summary.Name + "]"
 
           # Find all .VMX file paths in Datastore, filtering out ones with .snapshot (Useful for NetApp NFS)

           If ($dsBrowser.SearchDatastoreSubFolders($DatastorePath, $SearchSpec) |
           Where-Object {$_.FolderPath -notmatch ".snapshot"} | %{$_.FolderPath + ($_.File | select Path).Path} |
           Where-Object {$_ -match '\.vmx$'}) {
               $SearchResult += $dsBrowser.SearchDatastoreSubFolders($DatastorePath, $SearchSpec) |
               Where-Object {$_.FolderPath -notmatch ".snapshot"} | %{$_.FolderPath + ($_.File | select Path).Path} |
               Where-Object {$_ -match '\.vmx$'}
            }
        }
        
        Write-Verbose "VMX files paths : `n"
        Foreach ($VmxFile in $SearchResult) {
        Write-Verbose "$VmxFile"
        }

        $RegisteredVMs = Get-VM
        Write-Verbose "Registered VMs names : `n"
        Foreach ($RegisteredVM in $RegisteredVMs) {
            Write-Verbose $($RegisteredVM.Name)
        }

        # Deriving the VM names from the VMX files name
        $TrimmedVmxPaths = $searchresult -replace '\.vmx$',''
        $NamesFromVmx = $TrimmedVmxPaths -replace '(?s)^.*/','' | Sort-Object
        $NamesFromRegisteredVMs = $RegisteredVMs | Sort-Object -Property Name | Select-Object -ExpandProperty Name

        $CompareResult = Compare-Object -ReferenceObject $NamesFromRegisteredVMs -DifferenceObject $NamesFromVmx

        $UnregisteredVMX = $CompareResult | Where-Object { $_.SideIndicator -eq "=>" }

        Foreach ($Unregistered in $UnregisteredVMX) {

            $VmxFilePath = $SearchResult | Where-Object { $_ -like "*$($Unregistered.InputObject)*.vmx" }
            Write-Verbose "Registering VM with name : $($Unregistered.InputObject) from VMX file : $($VmxFilePath)"
            New-VM -VMFilePath $VmxFilePath -ResourcePool $ResourcePool
        }
    }
    End {
    }
}
