#Requires -Version 3

function ConvertTo-DottedDecimalIP {
  <#
    .SYNOPSIS
      Returns a dotted decimal IP address from either an unsigned 32-bit integer or a dotted binary string.
    .DESCRIPTION
      ConvertTo-DottedDecimalIP uses a regular expression match on the input string to convert to an IP address.
      This function commes from : http://www.indented.co.uk/2010/01/23/powershell-subnet-math/
      (c) 2008-2014 Chris Dent.
    .PARAMETER IPAddress
      A string representation of an IP address from either UInt32 or dotted binary.
  #>
 
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
    [String]$IPAddress
  )
  
  Process {
    Switch -RegEx ($IPAddress) {
      "([01]{8}.){3}[01]{8}" {
        return [String]::Join('.', $( $IPAddress.Split('.') | ForEach-Object { [Convert]::ToUInt32($_, 2) } ))
      }
      "\d" {
        $IPAddress = [UInt32]$IPAddress
        $DottedIP = $( For ($i = 3; $i -gt -1; $i--) {
          $Remainder = $IPAddress % [Math]::Pow(256, $i)
          ($IPAddress - $Remainder) / [Math]::Pow(256, $i)
          $IPAddress = $Remainder
         } )
      
        return [String]::Join('.', $DottedIP)
      }
      default {
        Write-Error "Cannot convert this format"
      }
    }
  }
}
function ConvertTo-DecimalIP {
  <#
    .SYNOPSIS
      Converts a Decimal IP address into a 32-bit unsigned integer.
    .DESCRIPTION
      ConvertTo-DecimalIP takes a decimal IP, uses a shift-like operation on each octet and returns a single UInt32 value.
      This function commes from : http://www.indented.co.uk/2010/01/23/powershell-subnet-math/
      (c) 2008-2014 Chris Dent.
    .PARAMETER IPAddress
      An IP Address to convert.
  #>
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
    [Net.IPAddress]$IPAddress
  )
 
  Process {
    $i = 3; $DecimalIP = 0;
    $IPAddress.GetAddressBytes() | ForEach-Object { $DecimalIP += $_ * [Math]::Pow(256, $i); $i-- }
 
    return [UInt32]$DecimalIP
  }
}
function Get-NetworkAddress {
  <#
    .SYNOPSIS
      Takes an IP address and subnet mask then calculates the network address for the range.
    .DESCRIPTION
      Get-NetworkAddress returns the network address for a subnet by performing a bitwise AND
      operation against the decimal forms of the IP address and subnet mask. Get-NetworkAddress
      expects both the IP address and subnet mask in dotted decimal format.
      This function commes from : http://www.indented.co.uk/2010/01/23/powershell-subnet-math/
      (c) 2008-2014 Chris Dent.
    .PARAMETER IPAddress
      Any IP address within the network range.
    .PARAMETER SubnetMask
      The subnet mask for the network.
  #>
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
    [Net.IPAddress]$IPAddress,
    
    [Parameter(Mandatory = $True, Position = 1)]
    [Alias("Mask")]
    [Net.IPAddress]$SubnetMask
  )
 
  Process {
    return ConvertTo-DottedDecimalIP ((ConvertTo-DecimalIP $IPAddress) -band (ConvertTo-DecimalIP $SubnetMask))
  }
}

function Get-MultihomingInfo {

<#
.SYNOPSIS
    Obtains IP configuration information relative to multihoming of all the VMkernel interfaces for one or more ESXi hosts.

.DESCRIPTION
    Obtains IP configuration information of all the VMkernel interfaces for one or more ESXi hosts and determines if the Multihoming configuration of the ESXi host is correct or not.

    A correct Multihoming configuration means that the VMkernel interfaces for each type of traffic are in different IP subnets.

    This cmdlet obtains the following information for each VMkernel interface :
    Name, IP Address, SubnetMask, Subnet, Type of VMkernel traffic and whether or not Multihoming is correctly configured.

.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default is Localhost.

.PARAMETER VMhosts
    To specify one or more ESXi hosts.
    The default will query all ESXi hosts managed by the vCenter Server you are connected to in PowerCLI.
    This parameter has 2 aliases : "Hosts" and "Servers".

.PARAMETER Cluster
    To query all the ESXi hosts in the specified cluster.

.PARAMETER Quiet
    This mode only outputs a boolean value for each ESXi host : $True if Multihoming is correctly configured, $False if not.

.EXAMPLE 
    Get-MultihomingInfo -Cluster Production

    Obtains IP configuration information relative to multihoming for each ESXi host in the Production cluster.

.EXAMPLE 
    Get-VMHost EsxDev5* | Get-MultihomingInfo

    Obtains IP configuration information relative to multihoming for each ESXi host with a name starting with EsxDev5, using pipeline input.

.EXAMPLE
    mhi (Get-VMHost Rack12-Esx18) -Quiet

    Outputs a boolean value stating whether multihoming is correctly configured or not for the ESXi host called Rack12-Esx18 , using the cmdlet alias "mhi".

.LINK
    http://kb.vmware.com/kb/2010877
  #>
    [cmdletbinding()]
    param(
    [string]$VIServer = "localhost",
    [Parameter(ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
    Position=0)]
    [Alias('Hosts','Servers')]
    [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl[]]$VMhosts,
    [string]$Cluster,
    [switch]$Quiet
    )
    Begin {
        Set-PowercliConfiguration -InvalidCertificateAction "Ignore" -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null

        # Connecting to the vCenter Server if not already connected
        If (-not($defaultVIServer)) {
            Connect-VIServer $VIServer
        }
        Else {
             Write-Verbose "Already connected the vCenter Server: $defaultVIServer" 
        }
        # Clearing the default parameter values in the function's scope
        $PSDefaultParameterValues.Clear()
        
        If (-not ($PSBoundParameters.ContainsKey('VMhosts')) ) {
            $VMhosts = Get-VMHost
        }

        # Getting all hosts from the cluster(s) if the -Cluster parameter is specified
        If ($Cluster) {
            $VMhosts = Get-Cluster -Name $Cluster | Get-VMHost
        }
    }
    Process {
        Foreach ($VMhost in $VMhosts) {
            Write-Verbose "--------------------- HOST : $VMhost.Name -------------------"
        
            # Preparing a collection to store information for each individual VMkernel interface
            $MultihomingInfoCollection = @()
        
            $VMKinterfaces = Get-VMHostNetworkAdapter -VMHost $VMhost -VMkernel    
            Foreach ( $VMKinterface in $VMKinterfaces) {
            
                $MultihomingInfoProperties = [ordered]@{'ESXi Host'=$VMhost.Name                    
                        'Name'=$VMKinterface.Name
                        'IP Address'=$VMKinterface.IP
                        'SubnetMask'=$VMKinterface.SubnetMask
                        'Subnet'=Get-NetworkAddress $VMKinterface.IP $VMKinterface.SubnetMask
                        'Management'=$VMKinterface.ManagementTrafficEnabled
                        'VMotion'=$VMKinterface.VMotionEnabled
                        'FaultTolerance'=$VMKinterface.FaultToleranceLoggingEnabled
                        'VSANTraffic'=$VMKinterface.VsanTrafficEnabled
                        'MultihomingOK'=$False
                        }

                # Building a custom object from the list of properties above
                $MultihomingInfoObj = New-Object -TypeName PSObject -Property $MultihomingInfoProperties
                
                # Building a collection of MultihomingInfo object for each ESXi host
                $MultihomingInfoCollection += $MultihomingInfoObj
            }
        
            $UniqueSubnets = ($MultihomingInfoCollection.Subnet | Sort-Object -Unique).length
            $MultihomingOK = $UniqueSubnets -ge $VMKinterfaces.length
            $MultihomingInfoCollection | ForEach-Object { $_.MultihomingOK=$MultihomingOK }
        
            If ($Quiet) {
                Write-Output $MultihomingOK
            }
            Else {
                Write-Output $MultihomingInfoCollection
            }
        }
    }
    End {}
}

# Setting an alias for the function Get-MultihomingInfo
New-Alias -Name mhi -Value Get-MultihomingInfo
Export-ModuleMember -Function *
Export-ModuleMember -Alias *
