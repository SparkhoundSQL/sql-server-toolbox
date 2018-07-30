--https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/sql-server-backup-to-url?view=sql-server-2017

DECLARE @DB_name VARCHAR(256) -- database name 
DECLARE @BackupLoc VARCHAR(512) -- path for backup files 
DECLARE @BackupfileName VARCHAR(512) -- filename for backup 
DECLARE @fileDate VARCHAR(20) -- used for file name
DECLARE @process VARCHAR(2000) -- used for documentation
-- specify database backup container location
SET @BackupLoc = 'https://whatever.blob.core.windows.net/prodsqlbak/sh-sp2013-sql/' 

DECLARE db_cursor CURSOR FOR 
SELECT name FROM master.sys.databases WHERE database_id > 4 and state=0 and is_read_only = 0
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DB_name  
WHILE @@FETCH_STATUS = 0  
BEGIN  
	set @fileDate= replace(replace(convert(nvarchar(50),getdate()),' ','_'),':','_')
	SET @BackupfileName = @BackupLoc + @DB_name + '_' + @fileDate + '.DIF' 
    SET @process = 'BACKUP DATABASE '+@DB_name+ ' TO URL ='''+ @BackupfileName  +''' WITH CREDENTIAL = ''https://whatever.blob.core.windows.net/prodsqlbak''
		, COMPRESSION, CHECKSUM, FORMAT;'
	--print @process
	BEGIN TRY
       BACKUP DATABASE @DB_name TO URL = @BackupfileName  
		WITH CREDENTIAL = N'https://whatever.blob.core.windows.net/prodsqlbak'
		, COMPRESSION, CHECKSUM, FORMAT;
    END TRY
	BEGIN CATCH
		--Only captures the 3013, not the preceding and actual error message for any backup failure. :(
		--INSERT INTO DBALogging.dbo.errortable ([ErrorNumber], [ErrorSeverity], [ErrorState], [ErrorProcedure], [ErrorLine], [ErrorMessage], [Process])
		--SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage
		--	, Process = 'Testing'; --need the semicolon
	
		THROW --optional, to actually cause a failure. 

	END CATCH
		
	FETCH NEXT FROM db_cursor INTO @DB_name  

END  
CLOSE db_cursor  
DEALLOCATE db_cursor
