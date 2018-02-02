#Retention plan for BACKUP TO URL backups in Azure blob storage
#Breaking lease if necessary: https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/deleting-backup-blob-files-with-active-leases

Clear-Host

#TODO 
$context = New-AzureStorageContext -StorageAccountName "ACCOUNT NAME HERE!" -StorageAccountKey "STORAGE KEY HERE!"
$container = "CONTAINER NAME HERE (subfolder path)!"
$RetentionWeeks = 8

[DateTime]$today = (Get-Date)
[Int]$dateofweek = ($today.DayOfWeek) #get the day of the week (0 = Sunday) so that we're always deleting a whole week at a time, in the case of a weekly full schedule
#Delete whole weeks only
$RetentionDays = ($RetentionWeeks * -7) -1 -$dateofweek
$BackupFileExtension = '*.bak'

write-host (Get-Date)

Get-AzureStorageBlob -Container $container -Context $context  | `
    where-object  { $_.PSIsContainer -ne $true -and $_.LastModified -lt (get-date).AddDays($RetentionDays) -and $_.Name -Like $BackupFileExtension `
         } | Remove-AzureStorageBlob -Verbose #-whatif

$RetentionDays = $RetentionWeeks * -7 -$dateofweek
$BackupFileExtension = '*.dif'

Get-AzureStorageBlob -Container $container -Context $context  | `
    where-object  { $_.PSIsContainer -ne $true -and $_.LastModified -lt (get-date).adddays($RetentionDays) -and $_.Name -Like $BackupFileExtension `
        } | Remove-AzureStorageBlob -Verbose #-whatif

                          
$RetentionDays = $RetentionWeeks * -7 -$dateofweek
$BackupFileExtension = '*.trn'
    
Get-AzureStorageBlob -Container $container -Context $context  | `
    where-object  { $_.PSIsContainer -ne $true -and $_.LastModified -lt (get-date).adddays($RetentionDays) -and $_.Name -Like $BackupFileExtension  `
        } | Remove-AzureStorageBlob -Verbose #-whatif

write-host (Get-Date)