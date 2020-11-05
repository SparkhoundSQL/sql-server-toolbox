##Get Block size per 
##Look for Bytes Per Cluster. By default 4096, should be 65536 for SQL data, logs, and tempdb volumes.
Fsutil fsinfo ntfsinfo d: 
Fsutil fsinfo ntfsinfo e: 
##Run once per volume, etc.

##Get Starting Offset
##wmic partition get BlockSize, StartingOffset, Name, Index

## May be inaccurate:
##$WMIQuery = "SELECT Label, Blocksize, Name FROM Win32_Volume WHERE FileSystem='NTFS'"
##Get-WmiObject -Query $WMIQuery | Select-Object Label,  @{Name="Blocksize_KB";Expression={$_.Blocksize}} , Name
