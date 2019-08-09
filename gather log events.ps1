#This script is intended to pull logs from a local server.
#INSTEAD, consider "gather log events - remting.ps1" in the toolbox to pull these logs down using PowerShell Remoting.

#Must launch PowerShell as an Administrator to read from the Security log
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force

<#
$NumDays = -30
$EventLog_Application = Get-EventLog -LogName "Application" -After (Get-Date).AddDays($NumDays) | 
    ? { $_.entryType -Match "Error" -and "Critical" -and "Warning" } | Group-Object -Property EventID |
    ForEach-Object { $_.Group[0] | Add-Member -PassThru -NotePropertyName Count -NotePropertyValue $_.Count | Add-Member -PassThru -NotePropertyName LogSource -NotePropertyValue "Application" } |
    Sort-Object Count -Descending -Unique | 
    Select-Object LogSource, Count, @{name="Latest";expression={$_.TimeGenerated}}, EventID, Source, Message ;
$EventLog_System = Get-EventLog -LogName "System" -After (Get-Date).AddDays($NumDays) | 
    ? { $_.entryType -Match "Error" -and "Critical" -and "Warning" } |  Group-Object -Property EventID |
    ForEach-Object { $_.Group[0] | Add-Member -PassThru -NotePropertyName Count -NotePropertyValue $_.Count | Add-Member -PassThru -NotePropertyName LogSource -NotePropertyValue "System" } |
    Sort-Object Count -Descending -Unique | 
    Select-Object LogSource, Count, @{name="Latest";expression={$_.TimeGenerated}}, EventID, Source, Message ;
$EventLog_Security = Get-EventLog -LogName "Security" -After (Get-Date).AddDays($NumDays) | 
    ? { $_.entryType -Match "Error" -and "Critical"  } |  Group-Object -Property EventID |
    ForEach-Object { $_.Group[0] | Add-Member -PassThru -NotePropertyName Count -NotePropertyValue $_.Count | Add-Member -PassThru -NotePropertyName LogSource -NotePropertyValue "Security" } |
    Sort-Object Count -Descending -Unique | 
    Select-Object LogSource, Count, @{name="Latest";expression={$_.TimeGenerated}}, EventID, Source, Message ;
@( $EventLog_System; $EventLog_Application; $EventLog_Security) | Out-GridView;
#>

## Version that works on PowerShell 2.0 because of Add-Member and Out-Gridview dependencies aren't supported until 3.0

clear-host
 $numDays = -90
 $timestamp = (Get-Date).ToString('yyyyMMddTHHmmss')
 $exportpath = "C:\temp\"+$env:computername+" log export " +$timestamp+".csv"
$eventLog_Application = @()
Get-EventLog -LogName "Application" -After (Get-Date).AddDays($numDays) | 
    Where-Object {$_.EntryType -match "Error" -or "Critical" -or "Warning"} | 
    Group-Object -Property EventID | ForEach {
    $currentGroup = $_.Group
    $latestMessage = $currentGroup | Sort-Object -Property Time -Descending | Select-Object -First 1
    $obj = "" | Select-Object -Property Count, LogSource, Latest, EventID, Source, Message
    $obj.Count = $currentGroup.Count
    $obj.LogSource = "Application"
    $obj.Latest = $latestMessage.TimeGenerated
    $obj.EventID = $latestMessage.EventID
    $obj.Source = $latestMessage.Source
    $obj.Message = $latestMessage.Message
    $eventLog_Application += $obj
    }
Get-EventLog -LogName "System" -After (Get-Date).AddDays($numDays) | 
    Where-Object {$_.EntryType -match "Error" -or "Critical" -or "Warning"} | 
    Group-Object -Property EventID | ForEach {
    $currentGroup = $_.Group
    $latestMessage = $currentGroup | Sort-Object -Property Time -Descending | Select-Object -First 1
    $obj = "" | Select-Object -Property Count, LogSource, Latest, EventID, Source, Message
    $obj.Count = $currentGroup.Count
    $obj.LogSource = "System"
    $obj.Latest = $latestMessage.TimeGenerated
    $obj.EventID = $latestMessage.EventID
    $obj.Source = $latestMessage.Source
    $obj.Message = $latestMessage.Message
    $eventLog_Application += $obj
    }
Get-EventLog -LogName "Security" -After (Get-Date).AddDays($numDays) | 
    Where-Object {$_.EntryType -match "Failure*"} | 
    Group-Object -Property EventID | ForEach {
    $currentGroup = $_.Group
    $latestMessage = $currentGroup | Sort-Object -Property Time -Descending | Select-Object -First 1
    $obj = "" | Select-Object -Property Count, LogSource, Latest, EventID, Source, Message
    $obj.Count = $currentGroup.Count
    $obj.LogSource = "Security"
    $obj.Latest = $latestMessage.TimeGenerated
    $obj.EventID = $latestMessage.EventID
    $obj.Source = $latestMessage.Source
    $obj.Message = $latestMessage.Message
    $eventLog_Application += $obj
    }
$eventLog_Application  | Sort-Object -Property Count, Latest -Descending  | Export-Csv -Path $exportpath -Encoding ascii -NoTypeInformation


