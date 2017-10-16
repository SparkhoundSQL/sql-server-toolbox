$NumDays = -7
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

@( $EventLog_System; $EventLog_Application) | Out-GridView;

 