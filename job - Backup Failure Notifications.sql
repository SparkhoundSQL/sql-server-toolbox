--TODO: See TODO items below
--      Update Stored procedure verion after modification

--create proc
USE [DBALogging]
GO  

CREATE PROCEDURE [dbo].[BackupFailureNotification] 
as
-- Version# July 2020 Rev01
--	  @database_name nvarchar(512)
--	, @backuptype nvarchar(50)
--	, @recovery_model_desc nvarchar(50)
--	, @LatestBackupDate datetime2
--	, @LatestBackupLocation nvarchar(512)
--	, @state_desc nvarchar(50)
--AS
--BEGIN TRY
--BEGIN TRANSACTION
--	 DECLARE @MyDatabaseName nvarchar(512)
--	 DECLARE @MyBackupType nvarchar(50)
--	 DECLARE @MyRecoveryModelDesc nvarchar(50)
--	 DECLARE @MyLatestBackupDate datetime2
--	 DECLARE @MyLatestBackupLocation nvarchar(512)
--	 DECLARE @MyStateDesc nvarchar(50)

--	 SET @MyDatabaseName = @database_name 
--	 SET @MyBackupType = @backuptype 
--	 SET @MyRecoveryModelDesc = @recovery_model_desc 
--	 SET @MyLatestBackupDate = @LatestBackupDate 
--	 SET @MyLatestBackupLocation = @LatestBackupLocation 
--	 SET @MyStateDesc = @state_desc 
IF OBJECT_ID('tempdb..#BackupFailureFULL') IS NOT NULL
    BEGIN
	   DROP TABLE #BackupFailureFULL;
    END;

IF OBJECT_ID('tempdb..#RecentFailover') IS NOT NULL
    BEGIN
	   DROP TABLE #RecentFailover;
    END;

DECLARE @FileName NVARCHAR(4000)
SELECT @FileName = target_data.value('(EventFileTarget/File/@name)[1]', 'nvarchar(4000)')
    FROM (
           SELECT CAST(target_data AS XML) target_data
            FROM sys.dm_xe_sessions s
            JOIN sys.dm_xe_session_targets t
                ON s.address = t.event_session_address
            WHERE s.name = N'AlwaysOn_health'
         ) ft;

WITH    base
          AS (
               SELECT XEData.value('(event/@timestamp)[1]', 'datetime2(3)') AS event_timestamp
                   ,XEData.value('(event/data/text)[1]', 'VARCHAR(255)') AS previous_state
                   ,XEData.value('(event/data/text)[2]', 'VARCHAR(255)') AS current_state
				   ,XEData.value('(event/data)[3]', 'VARCHAR(255)') AS availability_group_id
				   ,XEData.value('(event/data)[4]', 'VARCHAR(255)') AS availability_group_name
				   ,XEData.value('(event/data)[5]', 'VARCHAR(255)') AS availability_replica_id
				   ,XEData.value('(event/data)[6]', 'VARCHAR(255)') AS availability_replica_name
                   ,ar.replica_server_name
                FROM (
                       SELECT CAST(event_data AS XML) XEData
                           ,*
                        FROM sys.fn_xe_file_target_read_file(@FileName, NULL, NULL, NULL)
                        WHERE object_name = 'availability_replica_state_change'
                     ) event_data
                JOIN sys.availability_replicas ar
                    ON ar.replica_id = XEData.value('(event/data/value)[5]', 'VARCHAR(255)')
             )

		SELECT availability_replica_id 
		INTO #RecentFailover
		FROM base 
		Where event_timestamp > DATEADD (DAY, -1, getdate())
		and previous_state ='SECONDARY_NORMAL'
		and current_state = 'RESOLVING_PENDING_FAILOVER'
        ORDER BY event_timestamp DESC;

DECLARE @TimeStampFULL datetime2 = GETDATE()
SELECT  
	  a.database_name
	, a.backuptype
	, d.recovery_model_desc
	, LatestBackupDate = max(a.BackupFinishDate)
	, LatestBackupLocation = max(a.physical_device_name)
	, d.state_desc
into #BackupFailureFULL
 from sys.databases d
 inner join (	select * from (
						select  
						  database_name
						, backuptype = case type	WHEN 'D' then 'Database'
												WHEN 'I' then 'Differential database'
												WHEN 'L' then 'Transaction Log'
												WHEN 'F' then 'File or filegroup'
												WHEN 'G' then 'Differential file'
												WHEN 'P' then 'Partial'
												WHEN 'Q' then 'Differential partial' END
						, BackupFinishDate	=	backup_finish_date
						, BackupStartDate = backup_start_date
						, physical_device_name 
						, latest = Row_number() OVER (PARTITION BY database_name, type order by backup_finish_date desc)
						, fn_hadr_backup_is_preferred_replica  = sys.fn_hadr_backup_is_preferred_replica (database_name)
						
						from msdb.dbo.backupset bs					
						left outer join msdb.dbo.[backupmediafamily] bf
						on bs.[media_set_id] = bf.[media_set_id]	
						WHERE backup_finish_date is not null 
						group by  database_name, backup_finish_date, backup_start_date, physical_device_name, type
						) x
						where latest = 1
					 UNION 
					 select 
						db_name(d.database_id)
						, backuptype = 'Database'
						, null, null, null, null, fn_hadr_backup_is_preferred_replica  = sys.fn_hadr_backup_is_preferred_replica (db_name(d.database_id))
						
						FROM master.sys.databases d
						group by db_name(d.database_id)
					 UNION
					 select 
						db_name(d.database_id)
						, backuptype = 'Transaction Log'
						, null, null, null, null, fn_hadr_backup_is_preferred_replica  = sys.fn_hadr_backup_is_preferred_replica (db_name(d.database_id))
						
					  FROM master.sys.databases d
					  where d.recovery_model_desc in ('FULL', 'BULK_LOGGED')
					  group by db_name(d.database_id)
 ) a
 on db_name(d.database_id) = a.database_name
 WHERE a.database_name not in ('tempdb', 'model') 
 and a.database_name not in (Select name From sys.databases where replica_id in (select availability_replica_id from #RecentFailover))
 and d.state_desc ='ONLINE' 
 AND (		(backuptype <> 'Transaction Log' and d.recovery_model_desc = 'SIMPLE')
		OR	(d.recovery_model_desc <> 'SIMPLE')
	)
 and (d.create_date > ( DATEADD(DAY, 1, GETDATE()))) --TODO: change DATEADD value based on client's full backup interval
 and  (d.replica_id IS Null --not in an Ag
		or
			--Select for AG databases that are prefered replicas that fit the criteria for a gap in backup history
(d.replica_id IS Not Null  and  a.fn_hadr_backup_is_preferred_replica = 1) 
			)
group by 
	  a.database_name
	, a.backuptype 
	, d.recovery_model_desc
	, d.state_desc
HAVING (MAX(a.BackupFinishDate) < DATEADD(DAY, -7, @TimeStampFULL) and backuptype = 'Database')
		OR ((MAX(a.BackupFinishDate) IS NULL and backuptype = 'Database') OR (MAX(a.BackupFinishDate) < DATEADD(HOUR, -2, @TimeStampFULL) and backuptype = 'Transaction Log'))
		OR (MAX(a.BackupFinishDate) IS NULL and backuptype = 'Transaction Log')
order by a.backuptype, d.recovery_model_desc, a.database_name asc;


if (SELECT COUNT(*) FROM #BackupFailureFULL
) > 0
BEGIN 
	DECLARE @tableData  NVARCHAR(MAX) ;
	DECLARE @tableLog  NVARCHAR(MAX) ;    
  
	SET @tableData =  
		N'<H3><P>Full Backups (databases without backups in the last 7 days): <P></H3>' +  
		N'<table border="1">' +  
		N'<tr><th>Database </th><th>LatestBackup </th>' +  
		N'<th>RecoveryModel </th><th>BackupType </th>' +  
		CAST ( ( SELECT
				 td = b.database_name ,  ' ',
				 td = ISNULL(b.LatestBackupDate, 0000-00-00),  ' ',
				 td = b.recovery_model_desc  , ' ',
				 td = b.backuptype  
				from #BackupFailureFULL b
				where b.backuptype = 'Database'
				order by b.backuptype, b.LatestBackupDate 
				  FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ;  

	SET @tableLog =  
		N'<H3><P>Transaction Log Backups (databases without Transaction Log Backups in the last 2 hours): <P></H3>' +  
		N'<table border="1">' +  
		N'<tr><th>Database </th><th>LatestBackup </th>' +  
		N'<th>RecoveryModel </th><th>BackupType </th>' +  
		CAST ( ( SELECT
				 td = b.database_name ,  ' ',
				 td = ISNULL(b.LatestBackupDate, 0000-00-00),  ' ',
				 td = b.recovery_model_desc  , ' ',
				 td = b.backuptype  
				from #BackupFailureFULL b
				where b.backuptype = 'Transaction Log'
				order by b.backuptype, b.LatestBackupDate 
				  FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ;  
	
	BEGIN
	
	SET @tablelog = '<h4><p>Local server time ' + convert(varchar(50), SYSDATETIMEOFFSET()) + '</p></h4>
		' + @tablelog 
	declare @nBody nvarchar(max)
	declare @nServer nvarchar(max)
	SET @nBody = CASE 
						WHEN (SELECT COUNT(*) FROM #BackupFailureFULL WHERE backuptype = 'Database') = 0 THEN 'The following databases have recently missed backups and should be investigated:' + @tableLog
						WHEN (SELECT COUNT(*) FROM #BackupFailureFULL WHERE backuptype = 'Transaction Log') = 0 THEN 'The following databases have recently missed backups and should be investigated:' + @tableData
				 ELSE 'The following databases have recently missed backups and should be investigated:
				 <P>' + @tableData + @tableLog END
	SET @nServer = 'Backup Failure on ' + @@SERVERNAME
		EXEC msdb.dbo.sp_send_dbmail 
		   @profile_name  = 'profilename' , --TODO: change profile_name and recipinets below, per server
		   @recipients = 'sql.alerts@sparkhound.com', 
		   @body =  @nBody,
		   @body_format ='HTML',
		   @subject = @nServer ;  

	END
	END
;
GO 
--exec dbo.BackupFailureNotification



--create SQL Agent Job

USE [msdb]
GO

/****** Object:  Job [Backup Failure Notification]    Script Date: 4/19/2019 9:50:11 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/19/2019 9:50:11 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Backup Failure Notification', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Notifies managed.sql of any missed backups within a specified time period', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'sql.alerts@sparkhound.com', @job_id = @jobId OUTPUT --TODO: change this line per server
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run Hourly Backup Checks]    Script Date: 4/19/2019 9:50:12 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Hourly Backup Checks', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbo.BackupFailureNotification;', 
		@database_name=N'DBALogging', --TODO: change this line per server
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Hourly', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20170906, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'47e02677-85cd-4ce0-b8fe-fa2c0e67eeac'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


/*
DROP INDEX [backupsetDate] ON [dbo].[backupset]
--replace
GO
CREATE NONCLUSTERED INDEX [IDX_NC_backupset_backup_finish_date_database_name] ON [dbo].[backupset]
(
	[backup_finish_date] ASC,
	[database_name] ASC
)
INCLUDE([media_set_id],[backup_start_date],[type]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [backupsetuuid] ON [dbo].[backupset]
(
	[backup_set_uuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX_NC_backupset_last_lsn_database_name] ON [dbo].[backupset]
(
	[last_lsn] ASC,
	[database_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX_NC_backupset_name_type_database_name] ON [dbo].[backupset]
(
	[name] ASC,
	[type] ASC,
	[database_name] ASC
)
INCLUDE([backup_set_id],[server_name]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX_NC_backupset_type_database_name_last_lsn] ON [dbo].[backupset]
(
	[type] ASC,
	[database_name] ASC,
	[last_lsn] ASC
)
INCLUDE([time_zone],[backup_finish_date],[server_name]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
*/
