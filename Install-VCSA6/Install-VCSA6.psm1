function Install-VCSA6 {

<#
.SYNOPSIS
    Deploys a vCenter Server Appliance 6.0 using PowerCLI and a default OVA file from the vCenter Appliance 6.0 ISO file.

.DESCRIPTION
    Deploys a vCenter Server Appliance 6.0 using PowerCLI and a default OVA file.
    Works for a vCenter Server Appliance with embedded Platform Services Controller, for an external (already deployed) Platform Services Controller and also for the Platform Services Controller only.
    It requires PowerCLI 5.8 or later because it uses the cmdlets Get-OvfConfiguration and Import-VApp.

    To get the default OVA file, first mount the vCenter Appliance ISO file (VMware_VCSA-all-6.0.0-xxxx.iso) and copy the file \Your_ISO_Content\vcsa\vmware-vcsa to a location of your choice.
    Rename the copy of the file vmware-vcsa to vmware-vcsa.ova .

    The resulting VM is powered off.

.PARAMETER VIServer
    To specify the vCenter Server to connect PowerCLI to.
    The default is Localhost.

.PARAMETER OVAFilePath
    To specify the full path for the vCenter Appliance OVA file.

.PARAMETER Cluster
    The cluster to which the vCenter Appliance will be deployed.

.PARAMETER VMName
    The name of the virtual machine which will be deployed as a new vCenter appliance.

.PARAMETER VMNetwork
    The name of the portgroup the vCenter Appliance will be connected to.

.PARAMETER DeploymentOption
    To specify a value representing an appliance size and deployment mode.

    Explanation of the possible values :

    tiny : a vCenter Server + embedded Platform Services Controller for up to 10 hosts and 100 VMs.
    small : a vCenter Server + embedded Platform Services Controller for up to 100 hosts and 1000 VMs.
    medium : a vCenter Server + embedded Platform Services Controller for up to 400 hosts and 4000 VMs.
    large : a vCenter Server + embedded Platform Services Controller for up to 1000 hosts and 10,000 VMs.
    management-tiny : vCenter Server only, for up to 10 hosts and 100 VMs.
    management-small : vCenter Server only, for up to 100 hosts and 1000 VMs.
    management-medium : vCenter Server only, for up to 400 hosts and 4000 VMs.
    management-large : vCenter Server only, for up to 1000 hosts and 10,000 VMs.
    infrastructure : Platform Services Controller only.

.PARAMETER IPAddress
    IPV4 address of the vCenter Appliance

.PARAMETER FQDN
    Full DNS name of the vCenter Appliance

.PARAMETER SubnetMaskCIDR
    Subnet mask of the vCenter Appliance's IP address in CIDR notation.
    The default value is 24, which corresponds to 255.255.255.0

.PARAMETER Gateway
    IP address of the vCenter appliance's default gateway

.PARAMETER DNSServer
    IP address of the vCenter appliance's DNS server

.PARAMETER RootPasswd
    vCenter Appliance root password

.PARAMETER SSHEnabled
    To specify if SSH is enabled on the vCenter appliance or not.
    The default is $True.
    Set it to $False to disable SSH on the vCenter Appliance.

.PARAMETER SSODomainName
    To specify the SSO domain name.
    The default is "vsphere.local".

.PARAMETER SSOSiteName
    To specify the SSO site name.
    The default is "Default-First-Site".

.PARAMETER SSOAdminPasswd
    Password for the administrator account in the SSO domain.

.PARAMETER NTPServer
    To specify the NTP server which the vCenter Appliance will use to sync time.
    The default is : "0.pool.ntp.org".

.PARAMETER DiskStorageFormat
    To specify the storage format for the disks of the imported VMs.
    When you set this parameter, you set the storage format for all virtual machine disks in the OVF package.

    This parameter accepts the following values : Thin, Thick, and EagerZeroedThick.
    The default is Thin.
    The vCenter Appliance has 11 virtual disks, so this parameter has a big impact on the storage space and the deployment time.


.EXAMPLE 
    Install-VCSA6 "C:\Deployment\vmware-vcsa.ova" -Cluster "Test-Cluster" -VMName "VCSA" -VMNetwork "Production" -DeploymentOption "tiny" -IPAddress "192.168.1.151" -Gateway "192.168.1.1" -DNSServer "192.168.1.1" -RootPasswd "Passw0rd!" -SSOAdminPasswd "Passw0rd!"

    Deploys a vCenter Appliance 6.0 using the OVA file C:\Deployment\vmware-vcsa.ova and the default parameter values.

.EXAMPLE 
    dir C:\Deployment\*.ova | Install-VCSA6 -Cluster "Test-Cluster" -VMName "VCSA" -VMNetwork "Production" -DeploymentOption "tiny" -IPAddress "192.168.1.151" -Gateway "192.168.1.1" -DNSServer "192.168.1.1" -RootPasswd "Passw0rd!" -SSOAdminPasswd "Passw0rd!"

    Deploys a vCenter Appliance 6.0 using pipeline input for -OVAFilePath and the default parameter values.

.LINK
https://github.com/lamw/PowerCLI-Deployment/tree/master/VCSA%206.0%20Embedded

http://www.virtuallyghetto.com/2015/02/ultimate-automation-guide-to-deploying-vcsa-6-0-part-1-embedded-node.html
#>
    [cmdletbinding()]
    param(
        [string]$VIServer = "localhost",
        [Parameter(Mandatory = $True,ValueFromPipeline = $True,Position=0)]        
        [ValidateScript({ Test-Path $_ })]
        [String]$OVAFilePath,

        [Parameter(Mandatory = $True)]
        [string]$Cluster,

        [Parameter(Mandatory = $True)]
        [string]$VMName,

        [Parameter(Mandatory = $True)]
        [string]$VMNetwork,

        [Parameter(Mandatory = $True)]
        [ValidateSet('tiny','small','medium','large','management-tiny','management-small','management-medium','management-large','infrastructure', ignorecase=$False)]
        [string]$DeploymentOption,

        [Parameter(Mandatory = $True)]
        [ValidateScript({ [bool]($_ -as [ipaddress]) })]
        [string]$IPAddress,

        [string]$FQDN = "",

        [ValidateRange(8,31)]
        [int]$SubnetMaskCIDR = 24,

        [Parameter(Mandatory = $True)]
        [ValidateScript({ [bool]($_ -as [ipaddress]) })]
        [string]$Gateway,

        [Parameter(Mandatory = $True)]
        [ValidateScript({ [bool]($_ -as [ipaddress]) })]
        [string]$DNSServer,

        [Parameter(Mandatory = $True)]
        [string]$RootPasswd,

        [Boolean]$SSHEnabled = $True,

        [string]$SSODomainName = "vsphere.local",

        [string]$SSOSiteName = "Default-First-Site",

        [Parameter(Mandatory = $True)]
        [string]$SSOAdminPasswd,

        [string]$NTPServer = "0.pool.ntp.org",

        [ValidateSet('Thin','Thick','EagerZeroedThick')]
        $DiskStorageFormat = "Thin"
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
        # Clearing the default parameter values in the function's scope
        $PSDefaultParameterValues.Clear()
    }
    Process {
        # Loading the OVA configuration into a variable for further manipulation
        $OvfConfig = Get-OvfConfiguration -Ovf $OVAFilePath

        $VMHost = Get-Cluster $Cluster | Get-VMHost | Sort-Object -Property MemoryGB | Select-Object -First 1
        $Datastore = $VMHost | Get-datastore | Sort-Object -Property FreeSpaceGB -Descending | Select -first 1
        $Network = Get-VirtualPortGroup -Name $VMNetwork -VMHost $VMHost

        # Filling out the OVF/OVA configuration properties
        
        $OvfConfig.NetworkMapping.Network_1.value = $Network
        $OvfConfig.DeploymentOption.value = $DeploymentOption
        $OvfConfig.IpAssignment.IpProtocol.value = "IPv4"
        $ovfconfig.Common.guestinfo.cis.appliance.net.addr.family.value = "ipv4"
        $OvfConfig.Common.guestinfo.cis.appliance.net.mode.value = "static"
        $OvfConfig.Common.guestinfo.cis.appliance.net.addr_1.value = $IPAddress
        $OvfConfig.Common.guestinfo.cis.appliance.net.pnid.value =if ($FQDN) {$FQDN} Else {$IPAddress}
        $OvfConfig.Common.guestinfo.cis.appliance.net.prefix.value = $SubnetMaskCIDR.ToString()
        $OvfConfig.Common.guestinfo.cis.appliance.net.gateway.value = $Gateway
        $OvfConfig.Common.guestinfo.cis.appliance.net.dns.servers.value = $DNSServer
        $OvfConfig.Common.guestinfo.cis.appliance.root.passwd.value = $RootPasswd
        $OvfConfig.Common.guestinfo.cis.appliance.ssh.enabled.value = $SSHEnabled.ToString()
        $OvfConfig.Common.guestinfo.cis.vmdir.domain_name.value = $SSODomainName
        $OvfConfig.Common.guestinfo.cis.vmdir.site_name.value = $SSOSiteName
        $OvfConfig.Common.guestinfo.cis.vmdir.password.value = $SSOAdminPasswd
        $OvfConfig.Common.guestinfo.cis.appliance.ntp.servers.value = $NTPServer

        # Deploying the OVF/OVA using the above configuration properties

        Import-VApp -Source $OVAFilePath -OvfConfiguration $OvfConfig -Name $VMName -VMHost $VMHost -Datastore $Datastore -DiskStorageFormat $DiskStorageFormat
    }
    End {
    }
}
