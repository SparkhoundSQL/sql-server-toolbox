--https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/sql-server-backup-to-url?view=sql-server-2017

DECLARE @DB_name VARCHAR(50) -- database name 
DECLARE @BackupLoc VARCHAR(256) -- path for backup files 
DECLARE @BackupfileName VARCHAR(256) -- filename for backup 
DECLARE @fileDate VARCHAR(20) -- used for file name
DECLARE @process VARCHAR(2000) -- used for documentation
-- specify database backup container location
SET @BackupLoc = 'https://sphsqlbackup.blob.core.windows.net/prodsqlbak/sh-sp2013-sql/' 

DECLARE db_cursor CURSOR FOR 
SELECT name FROM master.sys.databases WHERE database_id > 4 and state=0 and is_read_only = 0
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DB_name  
WHILE @@FETCH_STATUS = 0  
BEGIN  
	set @fileDate= replace(replace(convert(nvarchar(50),getdate()),' ','_'),':','_')
	SET @BackupfileName = @BackupLoc + @DB_name + '_' + @fileDate + '.DIF' 
    SET @process = 'BACKUP DATABASE '+@DB_name+ ' TO URL ='''+ @BackupfileName  +''' WITH CREDENTIAL = ''https://sphsqlbackup.blob.core.windows.net/prodsqlbak''
		, DIFFERENTIAL
		, COMPRESSION, CHECKSUM, FORMAT, BLOCKSIZE=65536, MAXTRANSFERSIZE=4194304;'
	print @process
	BEGIN TRY
       BACKUP DATABASE @DB_name TO URL = @BackupfileName  
		WITH CREDENTIAL = N'https://sphsqlbackup.blob.core.windows.net/prodsqlbak'
		, DIFFERENTIAL
		, COMPRESSION, CHECKSUM, FORMAT, BLOCKSIZE=65536, MAXTRANSFERSIZE=4194304;
    END TRY
	BEGIN CATCH
		INSERT INTO DBALogging.dbo.errortable ([ErrorNumber], [ErrorSeverity], [ErrorState], [ErrorProcedure], [ErrorLine], [ErrorMessage], [Process])
		SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage,
			Process = @process;
	END CATCH

	WAITFOR DELAY '00:01' -- one minute delay between to not exhaust Azure and create error 3013 errors

	FETCH NEXT FROM db_cursor INTO @DB_name  

END  
CLOSE db_cursor  
DEALLOCATE db_cursor