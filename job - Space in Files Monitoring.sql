-- Create Table
USE DBALogging
GO

CREATE TABLE [dbo].[Space_in_Files](
	[ID] [int] IDENTITY(1,1) NOT NULL
,DatabaseName varchar(128)
,recovery_model_desc varchar(50)
,DatabaseFileName varchar(500)
,FileLocation varchar(500)
,FileId int
,FileSizeMB decimal(19,2)
,SpaceUsedMB decimal(19,2)
,AvailableMB decimal(19,2)
,FreePercent decimal(9,2)
,DateTimePerformed datetimeoffset(2) CONSTRAINT DF_Space_in_Files_DateTimePerformed DEFAULT (sysdatetimeoffset())
 CONSTRAINT [PK_Space_in_Files] PRIMARY KEY CLUSTERED 
(	[ID] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
--Create Sproc
CREATE PROCEDURE [dbo].[Get_Space_in_Files]
@Threshold decimal(9,2)
AS
BEGIN
--Changed all floats and decimal(18,2) to decimal(19,2) - WDA 20170312

DECLARE @TimeStamp datetimeoffset(2) = sysdatetimeoffset()

DECLARE @SpaceInFiles TABLE
( DatabaseName varchar(128)
,recovery_model_desc varchar(50)
,DatabaseFileName varchar(500)
,FileLocation varchar(500)
,FileId int
,FileSizeMB decimal(19,2)
,SpaceUsedMB decimal(19,2)
,AvailableMB decimal(19,2)
,FreePercent decimal(9,2)
)

--Optional filter for small/unused databases at bottom

INSERT INTO @SpaceInFiles
exec sp_MSforeachdb  'use [?]; 
SELECT * FROM (
SELECT 
  DatabaseName		= d.name
, Recovery			= d.recovery_model_desc
, DatabaseFileName	= df.name
, FileLocation		= df.physical_name
, File_ID			= df.File_ID
, FileSizeMB		= CAST(size/128.0 as Decimal(9,2))
, SpaceUsedMB		= CAST(CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0 as Decimal(9,2))
, AvailableMB		= CAST(size/128.0 - CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0 as Decimal(9,2))
, FreePercent		= CAST((((size/128.0) - (CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0)) / (size/128.0) ) * 100. as Decimal(9,2))
 FROM sys.database_files df
 CROSS APPLY sys.databases d
 WHERE d.database_id = DB_ID() 
 AND d.is_read_only = 0 
 AND d.state = 0 --online databases only
 AND df.size > 128 -- databases of significant size only
 ) X
 WHERE AvailableMB < 5120 --@Threshold% free, but override if still more than 5GB free
 ;
'

delete from @SpaceInFiles where [FreePercent] > @Threshold

INSERT INTO [Space_in_Files] (DatabaseName,recovery_model_desc  ,DatabaseFileName  ,FileLocation  ,FileId ,FileSizeMB ,SpaceUsedMB,AvailableMB,FreePercent )
SELECT DatabaseName,recovery_model_desc  ,DatabaseFileName  ,FileLocation  ,FileId ,FileSizeMB ,SpaceUsedMB,AvailableMB,FreePercent  FROM @SpaceInFiles;

if (SELECT COUNT(*) FROM @SpaceInFiles) > 0
BEGIN --added BEGIN/END wrap on IF - WDA 20170312 
	DECLARE @tableHTML  NVARCHAR(MAX) ;  
  
	SET @tableHTML =  
		N'<h2>Server: ' + @@SERVERNAME + '</h2>' +
		N'<H3>Space in File Alert</H3>' +  
		N'<table border="1">' +  
		N'<tr><th>Database Name</th><th>Recovery_Model</th><th>Database File Name</th><th>FileSize_MB</th><th>Available_MB</th><th>Percent Free</th></tr>' +  
		CAST ( ( SELECT
				 td= v.DatabaseName,  '',
				 td= v.Recovery_Model_Desc, '',
				 td= v.DatabaseFileName, '',
				 td= convert(varchar(8),v.FileSizeMB), '',
				 td= convert(varchar(8),v.AvailableMB), '',
				 td= convert(varchar(8),v.FreePercent), ''
				FROM @SpaceInFiles v
				ORDER BY FreePercent asc, DatabaseName, FileId
				  FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ;  
  
	BEGIN
	--if @percent < @Threshold -- removed WDA 20170418
	--BEGIN
		EXEC msdb.dbo.sp_send_dbmail  
		   @recipients = 'managed.sql@sparkhound.com',  
		   @body = @tableHTML, 
		   @importance = 'HIGH', 
		   @body_format ='HTML',
		   @subject = 'Space in Files Alert Report' ;  
	--END
	END
	END
END;

GO


--Create SQL Agent Job
USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'Space In Files Insert', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'Space in Files Insert', @server_name = N'(LOCAL)'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Space in Files Insert', @step_name=N'Exec Get_Space_in_Files', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbo.Get_Space_in_Files @Threshold = 5;', 
		@database_name=N'DBALogging', --make sure db name matches
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'Space in Files Insert', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', --enter operator name
		@notify_netsend_operator_name=N'', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'Space in Files Insert', @name=N'Every 4 Hours', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=4, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20171204, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO




