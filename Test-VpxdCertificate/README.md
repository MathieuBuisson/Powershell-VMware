##Description :



This module contains 1 cmdlet : **Test-VpxdCertificate**.  
It requires PowerShell version 3
 (or later).



##Test-VpxdCertificate :




Checks if a certificate file meets all the requirements for the vCenter Server 
certificate (5.x or 6.0).

**Here is the list of requirements which are checked by this cmdlet for vCenter Server 5.x :**

* Certificate must be X.509 v3.
* Certificate should begin with : "-----BEGIN CERTIFICATE-----".
* Certificate should end with : "-----END CERTIFICATE-----".
* Subject Alternative Name must contain "DNS Name=" with the fully qualified 
domain name of the vCenter server.
* The certificate must be valid : the current date must be between the "Valid 
from" date and the "Valid to" date.
* The Key usage must contain the following usages : Digital Signature, Key 
Encipherment, Data Encipherment
* The Enhanced key usage must contain : "Server Authentication" and "Client 
Authentication".
* The public key algorithm must be : RSA (2048 Bits).
* The certificate must NOT be a wildcard certificate.
* The signature hash algorithm must be SHA256, SHA384, or SHA512.  

**Here is the list of requirements which are checked by this cmdlet for vCenter Server 6.0 :**

* Certificate must be X.509 v3.
* Certificate should begin with : "-----BEGIN CERTIFICATE-----".
* Certificate should end with : "-----END CERTIFICATE-----".
* Subject Alternative Name must contain "DNS Name=" with the fully qualified 
domain name of the vCenter server.
* The certificate must be valid : the current date must be between the "Valid 
from" date and the "Valid to" date.
* The Key usage must contain the following usages : Digital Signature, Key 
Encipherment
* The public key algorithm must be : RSA (2048 Bits).
* The certificate must NOT be a wildcard certificate.
* The signature hash algorithm must be SHA256, SHA384, or SHA512.

The cmdlet performs a test for each of the requirement mentioned above and 
outputs an object with a property corresponding to each of these test.  
The value of all these properties is either True or False.  
True means that the certificate passed the corresponding test and False means that the certificate failed the corresponding test.  

If this function is run from the vCenter Server itself, it will detect the vCenter Server version by itself.
If it is not run from the vCenter Server itself, the vCenter version ("5.x" or "6.0") needs to be specified using the -VpxdVersion parameter.

###Parameters :



**CertFilePath :** To specify the full path of the certificate file to check.  
The default value corresponds to the default vCenter Server certificate path.  
If not specified, it defaults to C:\ProgramData\VMware\VMware VirtualCenter\SSL\rui.crt .



**vCenterServerFQDN :** To specify the full DNS name of the vCenter Server.  
This is required if the cmdlet is not run from the vCenter Server itself or if the vCenter server is unable to resolve its own FQDN.  
If not specified, it defaults to [System.Net.Dns]::GetHostByName((hostname)).HostName .

**VpxdVersion :** The vCenter Server certificate requirements are different between vCenter 5.x and 6.0.  
This parameter specifies the version of vCenter Server to define the requirements against which the certificate is checked.  
By default, if the function is run from the vCenter Server itself, it will detect the vCenter Server version by itself.



**Quiet :** Instead of outputing the result of the test for each requirement, the "quiet" mode just outputs a boolean value : True or False.  
True means that the specified certificate meets all the requirements, False means that it doesn't meet all the requirements.



###Examples :



-------------------------- EXAMPLE 1 --------------------------

PS C:\>Test-VpxdCertificate


Checks if the certificate located in the default path on the local vCenter 
Server meets all the requirements for the detected version of vCenter Server.




-------------------------- EXAMPLE 2 --------------------------

PS C:\>Test-VpxdCertificate -CertFilePath $env:USERPROFILE\Desktop\rui.crt 
-vCenterServerFQDN "VC.vcloud.local" -VpxdVersion 5.x -Verbose


Checks if the certificate file on the user's desktop meets all the requirements 
for vCenter 5.x, displaying verbose information.
The verbose information contains the properties checked for each test and their 
values.




-------------------------- EXAMPLE 3 --------------------------

PS C:\>Test-VpxdCertificate -Quiet


Checks if the certificate located in the default path on the local vCenter 
Server meets all the requirements for the detected version of vCenter Server.
It outputs a boolean value : True or False. It is True only when the specified 
certificate meets all the requirements.


