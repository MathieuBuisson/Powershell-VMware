#Requires -Version 3

function Export-TagAndAssignment {
	
<#
.SYNOPSIS
    Exports all the tags, tag categories and tag assignments from a vCenter to a file. This file can be used later to import all the tags, categories and assignments back into a vCenter environment.
.NOTES
    Author : Mathieu Buisson
#>

[cmdletbinding()]
    param(
        [string]$VIServer = "localhost",

        [Parameter(Mandatory=$True, Position=1)]
        [string]$Path        
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

        $TagCategories = Get-TagCategory
        $Tags = Get-Tag
        $TagAssignments = Get-TagAssignment

        # Grouping the tag categories, the tags and the tag assignments into an array
        $ExportArray = @($TagCategories,$Tags,$TagAssignments)

        try {
            Export-Clixml -InputObject $ExportArray -Path $Path -ErrorAction Stop
        }
        catch {
            Write-Error $_.Exception.Message
        }               
    }
    End {
    }
}

function Import-TagAndAssignment {
	
<#
.SYNOPSIS
    Imports all the tags, tag categories and tag assignments from a file to a vCenter Server.
.NOTES
    Author : Mathieu Buisson
#>

[cmdletbinding()]
    param(
        [string]$VIServer = "localhost",

        [Parameter(Mandatory=$True, Position=1)]
        [string]$Path        
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

        $Import = Import-Clixml -Path $Path

        # Creating the tag categories from the imported XML data
        Foreach ( $category in $Import[0] ) {

            New-TagCategory -Name $category.Name -Description $category.Description `
            -Cardinality $category.Cardinality -EntityType $category.EntityType
        }

        # Creating the tags from the imported XML data
        Foreach ( $tag in $Import[1] ) {

            New-Tag -Name $tag.Name -Category (Get-TagCategory -Name $tag.Category) `
            -Description $tag.Description
        }

        # Creating the tag assignments from the imported XML data
        Foreach ( $assignment in $Import[2] ) {

            $AssignTag = (Get-Tag -Name $assignment.Tag.Name)
            $AssignEntity = Get-VIObjectByVIView -MORef ($assignment.Entity.Id)

            New-TagAssignment -Tag $AssignTag -Entity $AssignEntity
        }
    }
    End {
    }
}
