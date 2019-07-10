#Must launch PowerShell as an Administrator to read from the Security log

##Run this block first to enter the remote session
##Execute this block with F8 not F5
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
$target = "CA-SQL2017"
Enter-PSSession -ComputerName $target

##Because you lose scope when you enter the remote session, this must be executed separately. The entire remoting can't be in a single script execution.
##Execute this block with F8 not F5
##This one takes a while
$target = "CA-SQL2017"
$loglocalfile = "C:\temp\"+$target+" log export.csv"
$NumDays = -90
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
@( $EventLog_System; $EventLog_Application; $EventLog_Security) |  Export-Csv -Path $loglocalfile -Encoding ascii -NoTypeInformation;
Exit-PSSession

##Run this block outside of the remote session
##Execute this block with F8 not F5
$timestamp = Get-Date -Format "FileDateTime"
$logtargetfile = "\\"+$target+"\C$\temp\"+$target+" log export.csv"
$loglocalfile = "C:\temp\"+$target+" log export "+$timestamp+".csv"
copy-item $logtargetfile $loglocalfile
