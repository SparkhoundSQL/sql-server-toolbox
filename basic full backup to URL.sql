--Basic job script to backup to URL, SQL 2016+.
--Performs full backups on user databases 

--This script assumes that an SAS Credential is in place for the storage container.
--Verify: select * from sys.credentials where credential_identity = 'Shared Access Signature'
--If you need to create an SAS Credential, see toolbox\sas credential.sql
--SAS Credentials only work for SQL 2016+.
--More info: https://techcommunity.microsoft.com/t5/DataCAT/SQL-Server-Backup-to-URL-a-cheat-sheet/ba-p/346358?advanced=false&collapse_discussion=true&q=MAXTRANSFERSIZE&search_type=thread
--Note that WITH CERTIFICATE to use a storage account credential is not needed in the script, this was for behavior <2016+ and is still needed for those older versions.
--See: https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/sql-server-backup-to-url?view=sql-server-2017#credential

DECLARE @BackupLoc VARCHAR(512) -- path for backup files 
-- specify database backup container location
SET @BackupLoc = 'https://storageaccountwhatever.blob.core.windows.net/containerwhatever/servername/';

DECLARE @DB_name VARCHAR(255) -- database name 
DECLARE @BackupfileName VARCHAR(1024) -- filename for backup 
DECLARE @fileDate VARCHAR(20) -- used for file name
DECLARE @backupSetId int
DECLARE @errormessage nvarchar(2000) 

DECLARE db_cursor CURSOR FOR 
SELECT name FROM master.sys.databases 
WHERE database_id > 4 --USER databases only. Should be another job for system databases.
and state_desc='ONLINE' and is_read_only = 0
and is_in_standby = 0
 
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DB_name  
WHILE @@FETCH_STATUS = 0  
BEGIN  
	SET @BackupfileName = @BackupLoc + @DB_name + '_full_' + 
	+ convert(varchar, datepart(year, sysdatetime())) + Right(Replicate('0',2) 
	+ convert(varchar(2), datepart(month, sysdatetime())),2) + Right(Replicate('0',2) 
	+ convert(varchar(2), datepart(day, sysdatetime())),2) + Right(Replicate('0',2) 
	+ convert(varchar(2), datepart(hour, sysdatetime())),2) + Right(Replicate('0',2) 
	+ convert(varchar(2), datepart(minute, sysdatetime())),2) +
					 + '.bak' 

	select @BackupfileName
	BEGIN TRY
       BACKUP DATABASE @DB_name TO URL = @BackupfileName  
		WITH  
		COMPRESSION, CHECKSUM, FORMAT, MAXTRANSFERSIZE = 4194304, BLOCKSIZE = 65536;

		--verify the backup
		select @backupSetId = position from msdb..backupset where database_name= @DB_name and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name= @DB_name )
		select @errormessage = N'Verify failed. Backup information for database  '+@DB_name+' not found.'
		if @backupSetId is null begin raiserror(@errormessage, 16, 1) end
		RESTORE VERIFYONLY FROM  URL = @BackupfileName WITH  
		   FILE = @backupSetId,  NOUNLOAD,  NOREWIND

    END TRY
	BEGIN CATCH
	THROW --to actually cause a failure. Reports both error codes 4208 and 3013, SQL Agent job handles the capture.

	END CATCH

	FETCH NEXT FROM db_cursor INTO @DB_name  

END  
CLOSE db_cursor  
DEALLOCATE db_cursor
