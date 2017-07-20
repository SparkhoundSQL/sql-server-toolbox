##Get Block size per 
Fsutil fsinfo ntfsinfo d: 
Fsutil fsinfo ntfsinfo e: 
##...

##Get Starting Offset
##wmic partition get BlockSize, StartingOffset, Name, Index

## May be inaccurate:
##$WMIQuery = "SELECT Label, Blocksize, Name FROM Win32_Volume WHERE FileSystem='NTFS'"
##Get-WmiObject -Query $WMIQuery | Select-Object Label,  @{Name="Blocksize_KB";Expression={$_.Blocksize}} , Name
