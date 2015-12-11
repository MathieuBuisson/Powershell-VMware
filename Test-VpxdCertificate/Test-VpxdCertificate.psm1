#Requires -Version 3
function Test-VpxdCertificate {

<#
.SYNOPSIS
    Checks if a certificate file meets all the requirements for the vCenter Server certificate (5.x or 6.0).

.DESCRIPTION
    Checks if a certificate file meets all the requirements for the vCenter Server certificate (5.x or 6.0).

    Here is the list of requirements which are checked by this cmdlet for vCenter Server 5.x :

    Certificate must be X.509 v3.
    Certificate should begin with : "-----BEGIN CERTIFICATE-----".
    Certificate should end with : "-----END CERTIFICATE-----".
    Subject Alternative Name must contain "DNS Name=" with the fully qualified domain name of the vCenter server.
    The certificate must be valid : the current date must be between the "Valid from" date and the "Valid to" date.
    The Key usage must contain the following usages : Digital Signature, Key Encipherment, Data Encipherment
    The Enhanced key usage must contain : "Server Authentication" and "Client Authentication".
    The public key algorithm must be : RSA (2048 Bits).
    The certificate must NOT be a wildcard certificate.
    The signature hash algorithm must be SHA256, SHA384, or SHA512.

    Here is the list of requirements which are checked by this cmdlet for vCenter Server 6.0 :

    Certificate must be X.509 v3.
    Certificate should begin with : "-----BEGIN CERTIFICATE-----".
    Certificate should end with : "-----END CERTIFICATE-----".
    Subject Alternative Name must contain "DNS Name=" with the fully qualified domain name of the vCenter server.
    The certificate must be valid : the current date must be between the "Valid from" date and the "Valid to" date.
    The Key usage must contain the following usages : Digital Signature, Key Encipherment
    The public key algorithm must be : RSA (2048 Bits).
    The certificate must NOT be a wildcard certificate.
    The signature hash algorithm must be SHA256, SHA384, or SHA512.


    The cmdlet performs a test for each of the requirement mentioned above and outputs an object with a property corresponding to each of these test.
    The value of all these properties is either True or False. True means that the certificate passed the corresponding test and False means that the certificate failed the corresponding test.

    If this function is run from the vCenter Server itself, it will detect the vCenter Server version by itself.
    If it is not run from the vCenter Server itself, the vCenter version ("5.x" or "6.0") needs to be specified using the -VpxdVersion parameter.


.PARAMETER CertFilePath
    To specify the full path of the certificate file to check.
    The default value corresponds to the default vCenter Server certificate path.

.PARAMETER vCenterServerFQDN
    To specify the full DNS name of the vCenter Server.
    This is required if the cmdlet is not run from the vCenter Server itself or if the vCenter server is unable to resolve its own FQDN.

.PARAMETER VpxdVersion
    The vCenter Server certificate requirements are different between vCenter 5.x and 6.0.
    This parameter specifies the version of vCenter Server to define the requirements against which the certificate is checked.
    By default, if the function is run from the vCenter Server itself, it will detect the vCenter Server version by itself.

.PARAMETER Quiet
    Instead of outputing the result of the test for each requirement, the "quiet" mode just outputs a boolean value : True or False.
    True means that the specified certificate meets all the requirements, False means that it doesn't meet all the requirements.

.EXAMPLE
    Test-VpxdCertificate

    Checks if the certificate located in the default path on the local vCenter Server meets all the requirements for the detected version of vCenter Server.

.EXAMPLE
    Test-VpxdCertificate -CertFilePath $env:USERPROFILE\Desktop\rui.crt -vCenterServerFQDN "VC.vcloud.local" -VpxdVersion 5.x -Verbose

    Checks if the certificate file on the user's desktop meets all the requirements for vCenter 5.x, displaying verbose information.
    The verbose information contains the properties checked for each test and their values.

.EXAMPLE
    Test-VpxdCertificate -Quiet

    Checks if the certificate located in the default path on the local vCenter Server meets all the requirements for the detected version of vCenter Server.
    It outputs a boolean value : True or False. It is True only when the specified certificate meets all the requirements.

.NOTES
    Author : Mathieu Buisson
    
.LINK
    For the latest version of this module and its documentation, please refer to :
    https://github.com/MathieuBuisson/Powershell-VMware/tree/master/Test-VpxdCertificate

#>

[cmdletbinding()]
    param(
        [Parameter(Position=0)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$CertFilePath = "C:\ProgramData\VMware\VMware VirtualCenter\SSL\rui.crt",

        [Parameter(Position=1)]
        # This default value assumes that the function is run from the vCenter server and that it can resolve its own FQDN from its hostname
        [string]$vCenterServerFQDN = [System.Net.Dns]::GetHostByName((hostname)).HostName,`
        [Parameter(Position=2)]
        [ValidateSet("5.x","6.0")]
        [string]$VpxdVersion,

        [switch]$Quiet
    )

    Begin {
        # Checking if we are on a vCenter Server
        $LocalVpxd = Get-WmiObject -Class Win32_service -Filter "Name='vpxd'" -ErrorAction SilentlyContinue

        # If VpxdVersion parameter was not used, setting a value for $VpxdVersion
        If (-not ($PSBoundParameters.ContainsKey('VpxdVersion')) ) {
            If (-not ($LocalVpxd)) {
                Throw "The vCenter version has to be specified using the -VpxdVersion parameter, whenever the cmdlet is not run from a vCenter Server."
            }
            Else {
                $VpxdFile = Get-ChildItem $($LocalVpxd.PathName).Replace('"','')
                $VpxdProductVersion = $VpxdFile.VersionInfo.ProductVersion
                Write-Verbose "Detected vCenter Server version : $VpxdProductVersion"

                If ($VpxdProductVersion -match "^5\.\d*") {
                    $VpxdVersion = "5.x"
                }
                ElseIf ($VpxdProductVersion -match "^6\.\d*") {
                    $VpxdVersion = "6.0"
                }
                Else {
                    Write-Warning "The version of vCenter Server on the local machine is : $VpxdProductVersion"
                    Write-Warning "The vCenter version should be either 5.x or 6.x ."
                    Write-Warning "Falling back to `$VpxdVersion = 5.x"
                    $VpxdVersion = "5.x"
                }
            }
        }
        Write-Verbose "`$VpxdVersion : $VpxdVersion"
    }
    Process {
        # Checking if the module Microsoft.PowerShell.Security is loaded, if not, loading it
        If (-not (Get-Module Microsoft.PowerShell.Security -ErrorAction SilentlyContinue)) {            
	        Import-Module Microsoft.PowerShell.Security
        }
            
        $CertObject = Get-PfxCertificate -FilePath $CertFilePath

        #region Testing X.509 version3
        $CertificateType = $($CertObject.GetType().name)
        Write-Verbose "`$CertificateType : $CertificateType"
            
        $X509 = $($CertObject.GetType().name) -like "X509Certificate*"
        Write-Verbose "`$X509 : $X509"

        $Version = $($CertObject.Version) -eq 3
        Write-Verbose "Version : $($CertObject.Version)"
        Write-Verbose "`$Version : $Version"

        $X509v3 = $X509 -and $Version
        #endregion Testing X.509 version3

        #region Testing begins with "-----BEGIN CERTIFICATE-----"

        # Importing the content of the certificate as plain text
        $CertContent = Get-Content -Path $CertFilePath
        $FirstLine = $CertContent | Select-Object -First 1
        Write-Verbose "`$FirstLine : $FirstLine"

        $BeginCertificate = $FirstLine -eq "-----BEGIN CERTIFICATE-----"
        #endregion Testing begins with "-----BEGIN CERTIFICATE-----"

        #region Testing ends with "-----END CERTIFICATE-----"
        $LastLine = $CertContent | Select-Object -Last 1
        Write-Verbose "`$LastLine : $LastLine"

        $EndCertificate = $LastLine -eq "-----END CERTIFICATE-----"
        #endregion Testing ends with "-----END CERTIFICATE-----"

        #region Testing Subject alternative names contain FQDN
        $SubjectAltNameExtension = $CertObject.Extensions | Where-Object {$_.Oid.FriendlyName -match "Subject Alternative Name"}
        $SubjectAltNameObj = New-Object -ComObject X509Enrollment.CX509ExtensionAlternativeNames
        $SubjectAltNameString = [System.Convert]::ToBase64String($SubjectAltNameExtension.RawData)
        $SubjectAltNameObj.InitializeDecode(1, $SubjectAltNameString)

        # Preparing an empty array to populate it with the subject alternative names
        $SubjectAltNames = @()

        Foreach ($AlternativeName in $($SubjectAltNameObj.AlternativeNames)) {
            Write-Verbose "`$AlternativeName : $($AlternativeName.strValue)"
            $SubjectAltNames += $($AlternativeName.strValue)
        }
        $SubjectAltNamesContainFQDN = $SubjectAltNames -contains $vCenterServerFQDN
        #endregion Testing Subject alternative name with FQDN

        #region Testing current date is between the "Valid from" date and the Valid to" date

        $CurrentDate = Get-Date
        $ValidFrom = $CertObject.NotBefore
        Write-Verbose "`$ValidFrom : $($ValidFrom.ToString())"

        $ValidTo = $CertObject.NotAfter
        Write-Verbose "`$ValidTo : $($ValidTo.ToString())"
        $BetweenValidFromAndValidTo = ($CurrentDate -ge $ValidFrom) -and ($CurrentDate -le $ValidTo)
        #endregion Testing current date is between the "Valid from" date and the Valid to" date

        #region Testing Key usages
        $KeyUsageExtension = $CertObject.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Key Usage" }
        Write-Verbose "Key Usages : $($KeyUsageExtension.KeyUsages)"

        $KeyUsageString = $KeyUsageExtension.KeyUsages.ToString()

        If ($VpxdVersion -eq "5.x") {
            $RequiredKeyUsageFlags = "KeyEncipherment", "DigitalSignature", "DataEncipherment"
            Write-Verbose "Required key usages : KeyEncipherment, DigitalSignature, DataEncipherment"

            $KeyUsagesTest = ($KeyUsageString -match $RequiredKeyUsageFlags[0]) -and ($KeyUsageString -match $RequiredKeyUsageFlags[1]) -and ($KeyUsageString -match $RequiredKeyUsageFlags[2])
        }
        Else {
            $RequiredKeyUsageFlags = "KeyEncipherment", "DigitalSignature"
            Write-Verbose "Required key usages : KeyEncipherment, DigitalSignature"

            $KeyUsagesTest = ($KeyUsageString -match $RequiredKeyUsageFlags[0]) -and ($KeyUsageString -match $RequiredKeyUsageFlags[1])
        }
        #endregion Testing Key usages

        #region Testing Enhanced key usages
        $EnhancedKeyUsageExtension = $CertObject.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Enhanced Key Usage" }
        $ServerAuth = $EnhancedKeyUsageExtension.EnhancedKeyUsages.FriendlyName -contains "Server Authentication"
        Write-Verbose "ServerAuth Enhanced key usage : $ServerAuth"

        $ClientAuth = $EnhancedKeyUsageExtension.EnhancedKeyUsages.FriendlyName -contains "Client Authentication"
        Write-Verbose "ClientAuth Enhanced key usage : $ClientAuth"

        $EnhancedKeyUsagesTest = $ServerAuth -and $ClientAuth
        #endregion Testing Enhanced key usages

        #region Testing Public key size and algorithm

        $PublicKey = $CertObject.PublicKey.key
        Write-Verbose "Public key size : $($PublicKey.KeySize)"

        $KeySize2048Bits = $PublicKey.KeySize -ge 2048
        Write-Verbose "`$KeySize2048Bits : $KeySize2048Bits"

        Write-Verbose "Public key algorithm : $($PublicKey.KeyExchangeAlgorithm)"
        $PublicKeyAlgorithm = $PublicKey.KeyExchangeAlgorithm -like "RSA*"
        Write-Verbose "`$PublicKeyAlgorithm : $PublicKeyAlgorithm"

        $PublicKeySizeAndAlgorithm = $KeySize2048Bits -and $PublicKeyAlgorithm
        #endregion Testing Public key algorithm

        #region Testing Not wildcard certificate
        $CertCN = $CertObject.Subject -split "," | Where-Object { $_ -match "CN=" }
        Write-Verbose "Certificate CN : $CertCN"

        $NotWildcardCert = $certCN -notmatch "CN=\*\."
        #endregion Testing Not wildcard certificate

        #region Testing Signature hash algorithm
        $SignatureAlgorithm = $CertObject.SignatureAlgorithm.FriendlyName
        Write-Verbose "Signature hash algorithm : $SignatureAlgorithm"

        $SignatureAlgorithmTest = $SignatureAlgorithm -match "^sha\d{3}\d*"
        #endregion Testing Signature hash algorithm

        If ($Quiet) {
            If ($VpxdVersion -eq "5.x") {
                $X509v3 -and $BeginCertificate -and $EndCertificate -and $SubjectAltNamesContainFQDN -and $BetweenValidFromAndValidTo `                -and $KeyUsagesTest -and $EnhancedKeyUsagesTest -and $PublicKeySizeAndAlgorithm -and $NotWildcardCert -and $SignatureAlgorithmTest
            }
            Else {
                $X509v3 -and $BeginCertificate -and $EndCertificate -and $SubjectAltNamesContainFQDN -and $BetweenValidFromAndValidTo `
                -and $KeyUsagesTest -and $PublicKeySizeAndAlgorithm -and $NotWildcardCert -and $SignatureAlgorithmTest
            }
        }
        Else {
            # Properties of the custom output object will differ depending on the vCenter version
            If ($VpxdVersion -eq "5.x") {

                $TestResultProps = @{'Certificate is X.509 v3' = $X509v3
                                'Certificate begins with "-----BEGIN CERTIFICATE-----"' = $BeginCertificate
                                'Certificate ends with "-----END CERTIFICATE-----"' = $EndCertificate
						        'Subject alternative names contain the vCenter FQDN' = $SubjectAltNamesContainFQDN
                                'Current date is between the "Valid from" and "Valid to" dates' = $BetweenValidFromAndValidTo
                                'Certificate has the required key usages' = $KeyUsagesTest
                                'Certificate has the required enhanced key usages' = $EnhancedKeyUsagesTest
                                'Public key algorithm is RSA 2048 or higher' = $PublicKeySizeAndAlgorithm
                                'Certificate is NOT a wildcard certificate' = $NotWildcardCert
                                'Signature hash algorithm is SHA256 or higher' = $SignatureAlgorithmTest
                                }
            }
            Else {
                $TestResultProps = @{'Certificate is X.509 v3' = $X509v3
                                'Certificate begins with "-----BEGIN CERTIFICATE-----"' = $BeginCertificate
                                'Certificate ends with "-----END CERTIFICATE-----"' = $EndCertificate
						        'Subject alternative names contain the vCenter FQDN' = $SubjectAltNamesContainFQDN
                                'Current date is between the "Valid from" and "Valid to" dates' = $BetweenValidFromAndValidTo
                                'Certificate has the required key usages' = $KeyUsagesTest
                                'Public key algorithm is RSA 2048 or higher' = $PublicKeySizeAndAlgorithm
                                'Certificate is NOT a wildcard certificate' = $NotWildcardCert
                                'Signature hash algorithm is SHA256 or higher' = $SignatureAlgorithmTest
                                }
            }
		    $TestResultObj = New-Object -TypeName PSObject -Property $TestResultProps
            $TestResultObj
        }
    }
    End {
    }
}
