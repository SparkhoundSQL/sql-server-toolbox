--Assumes Server Audit Spec already exists using the below naming convention. See toolbox\audit setup.sql
--This loop creates the database audit spec for any database that does not have one
--Naming convention of the database audit spec is important.

--This loop can be scheduled as is in a SQL agent job.
exec sp_msforeachdb 'USE [?];

DECLARE @tsql nvarchar(4000) = null
, @Server_Audit_Name nvarchar(256) = '''' + replace(@@SERVERNAME,''\'','''') + N''-Audit''
, @DB_Audit_Name nvarchar(256) = ''Database-''+replace(''?'',N'' '',N'''')+ N''-Audit-Spec'';

IF (NOT EXISTS (select * from sys.database_audit_specifications where name = @DB_Audit_Name)
			and (''?'' not in (''tempdb'',''msdb'',''distribution''))
			)
BEGIN
select @tsql = N''
	--?
	CREATE DATABASE AUDIT SPECIFICATION ['' + @DB_Audit_Name + N'']
	FOR SERVER AUDIT [''+@Server_Audit_Name+N'']
	--catch all activity, period.
	ADD (UPDATE ON  DATABASE::[?] BY [public]),
	ADD (INSERT ON  DATABASE::[?] BY [public]),
	ADD (DELETE ON  DATABASE::[?] BY [public]),
	ADD (EXECUTE ON DATABASE::[?] BY [public]),
	ADD (SELECT ON  DATABASE::[?] BY [public])
	WITH (STATE = OFF);

	ALTER DATABASE AUDIT SPECIFICATION ['' + @DB_Audit_Name + N'']
	FOR SERVER AUDIT [''+@Server_Audit_Name+N'']
	WITH (STATE = ON);
	
	'';

print @tsql 
execute (@tsql)
END;
';

----Job:

--TODO: Change job owner to a reasonable service account, not sa.
--TODO: Create desired schedule, notifications once created.

USE [msdb]
GO

/****** Object:  Job [Create Database audit Specs]    Script Date: 8/10/2018 10:15:43 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 8/10/2018 10:15:43 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Create Database audit Specs', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [create database audit spec]    Script Date: 8/10/2018 10:15:43 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'create database audit spec', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Assumes Server Audit Spec already exists
--This loop creates the database audit spec for any database that does not have one
--Naming convention of the database audit spec is important.

--This loop can be scheduled as is in a SQL agent job.
exec sp_msforeachdb ''USE [?];

DECLARE @tsql nvarchar(4000) = null
, @Server_Audit_Name nvarchar(256) = '''''''' + replace(@@SERVERNAME,''''\'''','''''''') + N''''-Audit''''
, @DB_Audit_Name nvarchar(256) = ''''Database-''''+replace(''''?'''',N'''' '''',N'''''''')+ N''''-Audit-Spec'''';

IF (NOT EXISTS (select * from sys.database_audit_specifications where name = @DB_Audit_Name)
			and (''''?'''' not in (''''tempdb'''',''''msdb'''',''''distribution''''))
			)
BEGIN
select @tsql = N''''
	--?
	CREATE DATABASE AUDIT SPECIFICATION ['''' + @DB_Audit_Name + N'''']
	FOR SERVER AUDIT [''''+@Server_Audit_Name+N'''']
	--catch all activity, period.
	ADD (UPDATE ON  DATABASE::[?] BY [public]),
	ADD (INSERT ON  DATABASE::[?] BY [public]),
	ADD (DELETE ON  DATABASE::[?] BY [public]),
	ADD (EXECUTE ON DATABASE::[?] BY [public]),
	ADD (SELECT ON  DATABASE::[?] BY [public])
	WITH (STATE = OFF);

	ALTER DATABASE AUDIT SPECIFICATION ['''' + @DB_Audit_Name + N'''']
	FOR SERVER AUDIT [''''+@Server_Audit_Name+N'''']
	WITH (STATE = ON);
	
	'''';

print @tsql 
execute (@tsql)
END;
'';
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
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


--This loop REMOVES the database audit spec from any database that has one.
--Obviously, do not schedule this one! For testing/maintenance only.
exec sp_msforeachdb 'USE [?];

DECLARE @tsql nvarchar(4000) = null
, @Server_Audit_Name nvarchar(256) = '''' + replace(@@SERVERNAME,''\'','''') + N''-Audit''
, @DB_Audit_Name nvarchar(256) = ''Database-''+replace(''?'',N'' '',N'''')+ N''-Audit-Spec'';

IF ( EXISTS (select * from sys.database_audit_specifications where name = @DB_Audit_Name)
			and (''?'' not in (''tempdb'',''msdb'',''distribution'')))
BEGIN
select @tsql = N''
	ALTER DATABASE AUDIT SPECIFICATION ['' + @DB_Audit_Name + N'']
	WITH (STATE = OFF);
	DROP DATABASE AUDIT SPECIFICATION ['' + @DB_Audit_Name + N'']
'';
print @tsql 
execute (@tsql)
END;
';






*/