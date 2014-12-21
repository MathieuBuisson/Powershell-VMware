#Requires -Version 3
function Get-ESXiLogWithDate {
<#
.SYNOPSIS
    Transforms ESXi log entries from plain text to Powershell objects with a TimeStamp property which is itself, a datetime object.

.DESCRIPTION
    Transforms ESXi log entries from plain text to Powershell objects for further manipulation.
    Each log entry object has a property called Timestamp which is itself a datetime object, this allows the log entry objects to be easily filtered, altered, sorted, grouped, measured...

.PARAMETER LogFiles
    The path of one or more log files to parse. It can also be one or more folders containing the log files to parse.
    Accepts wildcards.

.PARAMETER Before
    To retrieve only the log entries where the timestamp is before the specified point in time.
    It must be a string in a format that can be converted to a datetime object.

.PARAMETER After
    To retrieve only the log entries where the timestamp is after the specified point in time.
    It must be a string in a format that can be converted to a datetime object.

.PARAMETER Yesterday
    To retrieve only the entries where the timestamp is within the day before the current date.

.PARAMETER FromLastDays
    To retrieve only the entries logged from the specified number of days ago 

.EXAMPLE
    Get-ESXiLogWithDate -LogFiles C:\esx-esx2-4\var\log\h*.log -After "12/09/2014 11:55:00" -Before "12/09/2014 11:59:00"
    Retrieves all log entries from log files with a filename starting with "h" where the timestamp is between 11:55 and 11:59 the 9th of December 2014.

.EXAMPLE
    Get-ESXiLogWithDate -LogFiles C:\esx-esx2-4\var\log\vmkernel.log -Yesterday
    Retrieves all log entries from the vmkernel log where the timestamp is from the day before the current date.

.EXAMPLE
    Get-ESXiLogWithDate -LogFiles C:\esx-esx2-4\var\log\ -FromLastDays 7
    Retrieves all log entries from all files in  C:\esx-esx2-4\var\log\ where the timestamp is from the last 7 days.

.OUTPUTS
    Custom objects with typeName: ESXi.LogEntry
#>
    [CmdletBinding()]
    
    Param(
        
        [Parameter(Position=0,
                   HelpMessage="Specify the path of one or more log files to parse. Accepts wildcards.")]
        [string[]]$LogFiles = ".",
        
        [datetime]$Before = (Get-Date),
        
        [datetime]$After = ((Get-Date).AddYears(-10)).date,
        
        [switch]$Yesterday,
        
        [int]$FromLastDays
    )

    Begin {       
        if ( $Yesterday ) {
            Write-Verbose "`$Yesterday : $Yesterday."
            $Before = (Get-Date).Date
            $After = ((Get-Date).AddDays(-1)).Date
        }
        if ( $FromLastDays ) {
            Write-Verbose "`$FromLastDays : $FromLastDays."
            $After = (Get-Date).AddDays(-$FromLastDays)
        }

        Write-Verbose "`$Before : $Before ."
        Write-Verbose "`$After : $After ."
    }
    Process {

        foreach ( $LogFile in (Get-ChildItem $LogFiles) ) {
            Write-Verbose "`$LogFile : $LogFile"

            $LogContent = Get-Content -Path $LogFile.FullName | Where-Object { $_ -match "\d{4}-\d{2}-\d{2}T" }

            foreach ( $LogEntry in $LogContent ) {
                $SplitLogEntry = $LogEntry -split 'Z'

                # Defining the custom properties for the log entry object
                $CustomProps = [ordered]@{'Logfile'=$LogFile.Name
                                          'TimeStamp'=$SplitLogEntry[0].Substring(0,19) -replace 'T',' ' -as [datetime] 
                                          'LogMessage'=$SplitLogEntry[1]}

                $LogEntryObj = New-Object -TypeName psobject -Property $CustomProps

                # Setting a typename for the output object to link it to a custom view
                $LogEntryObj.PSObject.Typenames.Insert(0,'ESXi.LogEntry')

                if (($LogEntryObj.TimeStamp -le $Before) -and ($LogEntryObj.TimeStamp -ge $After)) {
                    Write-Output $LogEntryObj
                }

            }

        }
    }
    End {}
}

function Convert-ESXiLogToLocalTime {
<#
.SYNOPSIS
    Convert ESXi log entries TimeStamp property from UTC to local time.

.DESCRIPTION
        Convert ESXi log entries TimeStamp property from UTC time to local time.
        Uses the time zone information from the local operating system.

.PARAMETER LogEntries
    one or more ESXi log entries to convert to local time. The log entries can be piped from Get-ESXiLogWithDate

.EXAMPLE
    Get-ESXiLogWithDate -LogFiles C:\esx-esx2-4\var\log\vmkernel.log -Yesterday | Convert-ESXiLogToLocalTime
    Retrieves all log entries from the vmkernel log where the timestamp is from the day before the current date and converts them to local time.

.EXAMPLE
    $MyLogs = Get-ESXiLogWithDate -LogFiles C:\esx-esx2-4\var\log\ -FromLastDays 7
    $MyLogs | Convert-ESXiLogToLocalTime

    Retrieves all log entries from all files in  C:\esx-esx2-4\var\log\ where the timestamp is from the last 7 days and stores them in the variable MyLog.
    Then, all the log entries stored in MyLog are piped to Convert-ESXiLogToLocalTime to convert them to local time.

.OUTPUTS
    Custom objects with typeName: ESXi.LogEntry
#>
[CmdletBinding()]
    
    Param(
        
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   HelpMessage="Specify one or more ESXi log entries to convert to local time. The log entries can be piped from Get-ESXiLogWithDate",
                   Position=0)]
        [PSObject]$LogEntries
    )

    Begin {
        $LocalTimeZone = [System.TimeZoneInfo]::Local
        Write-Verbose "`$LocalTimeZone : $LocalTimeZone ."
    }

    Process {
        foreach ( $LogEntry in $LogEntries ) {
            
            $LogEntry.TimeStamp = ($LogEntry.TimeStamp).ToLocalTime()
            Write-Output $LogEntry
        }

    }
    End {}
}

function Measure-ESXiLogTimeSpan {
<#
.SYNOPSIS
    Takes ESXi log entries, piped from the Get-ESXiLogWithDate or Convert-ESXiLogToLocalTime cmdlets and measures the duration covered by the logs.

.DESCRIPTION
    Takes ESXi log entries, piped from the Get-ESXiLogWithDate or Convert-ESXiLogToLocalTime cmdlets and measures the duration covered by the logs.
    This duration is presented as a timespan object and the precision is to the second.


.PARAMETER LogEntries
    One or more ESXi log entries, preferably piped from the Get-ESXiLogWithDate or Convert-ESXiLogToLocalTime cmdlets

.EXAMPLE
    Get-ESXiLogWithDate -LogFiles C:\esx-esx2-4\var\log\vmkernel.log | Convert-ESXiLogToLocalTime
    Measures the duration covered by the logs in the file vmkernel.log.

.EXAMPLE
    $MyLogs = Get-ESXiLogWithDate -LogFiles C:\esx-esx2-4\var\log
    $MyLogs | Convert-ESXiLogToLocalTime

    Retrieves all log entries from all files in  C:\esx-esx2-4\var\log\ and stores them in the variable MyLog.
    Then, it measures the duration covered by the logs stored in the variable MyLog.

.OUTPUTS
    One object of the type : System.TimeSpan
#>
[CmdletBinding()]
    
    Param(
        
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   HelpMessage="Specify one or more ESXi log entries to convert to local time.`
                   The log entries can be piped from Get-ESXiLogWithDate or from Convert-ESXiLogToLocalTime",
                   Position=0)]
        [PSObject]$LogEntries
    )

    Begin {
    $LogEntryCollection = @()
    }

    Process {
        foreach ( $LogEntry in $LogEntries ) {
        $LogEntryCollection += $LogEntry

        }
    }
    End {
        $FirstAndLastEntry = $LogEntryCollection | Sort-Object -Property TimeStamp | Select-Object -first 1 -Last 1

        $FirstTimeStamp = $FirstAndLastEntry[0].Timestamp
        Write-Verbose "`$FirstTimeStamp : $FirstTimeStamp "

        $LastTimeStamp = $FirstAndLastEntry[1].Timestamp
        Write-Verbose "`$LastTimeStamp : $LastTimeStamp "

        New-TimeSpan -Start $FirstTimeStamp -End $LastTimeStamp
    }
}