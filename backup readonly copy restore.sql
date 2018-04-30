--Backup/Copy/Restore user db's

--Must have ending \
declare @old_server_path_data nvarchar(4000)	= 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\DATA\';
declare @old_server_path_log nvarchar(4000)		= 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\DATA\';
declare @new_server_path_data nvarchar(4000)	= 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\DATA\';
declare @new_server_path_log nvarchar(4000)		= 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\DATA\';
declare @old_server_path_backup nvarchar(4000)	= 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\Backup\';
declare @new_server_path_backup nvarchar(4000)	= 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\Backup\';


with ctefiles_data (database_id, file_id, type_desc, name, physical_name, new_physical_name)
AS (
select database_id, file_id, type_desc, name, physical_name
	, new_physical_name = replace(physical_name, @old_server_path_data, @new_server_path_data)
from sys.master_files where type_desc = 'ROWS')

, ctefiles_log (database_id, file_id, type_desc, name, physical_name, new_physical_name)
AS (
select database_id, file_id, type_desc, name, physical_name, new_physical_name = replace(physical_name, 
	@old_server_path_log, @new_server_path_log)
from sys.master_files where type_desc = 'LOG')


select 
ReadOnly_On = '
ALTER DATABASE ['+db_name(d.database_id)+'] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
ALTER DATABASE ['+db_name(d.database_id)+'] SET  READ_ONLY WITH NO_WAIT;
ALTER DATABASE ['+db_name(d.database_id)+'] SET  MULTI_USER;
GO',
TakeBackups = '
BACKUP DATABASE ['+db_name(d.database_id)+'] TO  DISK = N'''+@old_server_path_backup+db_name(d.database_id)+'_migration_20180418.bak'' 
WITH NOFORMAT, NOINIT,  NAME = N'''+db_name(d.database_id)+'-Migration 20180418 Full Database Backup'', SKIP, NOREWIND, NOUNLOAD,  STATS = 10, CHECKSUM, COMPRESSION
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'''+db_name(d.database_id)+''' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'''+db_name(d.database_id)+''' )
if @backupSetId is null begin raiserror(N''Verify failed. Backup information for database '''''+db_name(d.database_id)+''''' not found.'', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'''+@old_server_path_backup+db_name(d.database_id)+'_migration_20180418.bak'' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO',
Restores = 'USE [master]
RESTORE DATABASE ['+db_name(d.database_id)+'] 
FROM  DISK = N'''+@new_server_path_backup+ db_name(d.database_id) +'_migration_20180418.bak''
WITH  FILE = 1
,  MOVE N'''+d.name+''' TO N'''+d.new_physical_name+'''
,  MOVE N'''+l.name+''' TO N'''+l.new_physical_name+'''
,  NOUNLOAD,  STATS = 5
GO
',
ReadOnly_Off = '
ALTER DATABASE ['+db_name(d.database_id)+'] SET  READ_WRITE WITH NO_WAIT;
GO',
*
FROM ctefiles_data d 
inner join ctefiles_log l
on d.database_id = l.database_id
where d.database_id > 4


/*
 
*/