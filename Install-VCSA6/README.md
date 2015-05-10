##Description :

This module contains 1 cmdlet : **Install-VCSA6** .

Based on William Lam's scripts : Deployment-Embedded.ps1, Deployment-PSC.ps1 and Deployment-VCSA-Mgmt.ps1 in:  
https://github.com/lamw/PowerCLI-Deployment

More information :  
http://www.virtuallyghetto.com/2015/02/ultimate-automation-guide-to-deploying-vcsa-6-0-part-1-embedded-node.html

It deploys a vCenter Server Appliance 6.0 using PowerCLI and a default OVA file.

It works for a vCenter Server Appliance with embedded Platform Services Controller, for an external (already deployed) Platform Services Controller and also for the Platform Services Controller only.

It requires PowerCLI 5.8 or later because it uses the cmdlets **Get-OvfConfiguration** and **Import-VApp**.

To get the default OVA file, first mount the vCenter Appliance ISO file (VMware_VCSA-all-6.0.0-xxxx.iso) and copy the file \Your_ISO_Content\vcsa\vmware-vcsa to a location of your choice. Then, rename the copy of the file vmware-vcsa to vmware-vcsa.ova .

The resulting VM is powered off.

##Parameters :

**VIServer :** To specify the vCenter Server to connect PowerCLI to.  
The default is Localhost.

**OVAFilePath :** To specify the full path for the vCenter Appliance OVA file.

**Cluster :** The cluster to which the vCenter Appliance will be deployed.

**VMName :** The name of the virtual machine which will be deployed as a new vCenter appliance.

**VMNetwork :** The name of the portgroup the vCenter Appliance will be connected to.

**DeploymentOption :** To specify a value representing an appliance size and deployment mode.

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

**IPAddress :** IPV4 address of the vCenter Appliance

**FQDN :** Full DNS name of the vCenter Appliance

**SubnetMaskCIDR :** Subnet mask of the vCenter Appliance's IP address in CIDR notation. The default value is 24, which corresponds to 255.255.255.0

**Gateway :** IP address of the vCenter appliance's default gateway

**DNSServer :** IP address of the vCenter appliance's DNS server

**RootPasswd :** vCenter Appliance root password

**SSHEnabled :** To specify if SSH is enabled on the vCenter appliance or not.
    The default is $True.
    Set it to $False to disable SSH on the vCenter Appliance.

**SSODomainName :** To specify the SSO domain name.
    The default is "vsphere.local".

**SSOSiteName :** To specify the SSO site name.
    The default is "Default-First-Site".

**SSOAdminPasswd :** Password for the administrator account in the SSO domain.

**NTPServer :** To specify the NTP server which the vCenter Appliance will use to sync time.
    The default is : "0.pool.ntp.org".

**DiskStorageFormat :** To specify the storage format for the disks of the imported VMs.  
When you set this parameter, you set the storage format for all virtual machine disks in the OVF package.  
This parameter accepts the following values : **Thin**, **Thick**, and **EagerZeroedThick**.  
The default is **Thin**.  
The vCenter Appliance has 11 virtual disks, so this parameter has a big impact on the storage space and the deployment time.
