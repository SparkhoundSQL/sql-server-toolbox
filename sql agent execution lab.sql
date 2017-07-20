--Create job to test out how the jobs execute.

USE [msdb]
GO

/****** Object:  Job [CredTest]    Script Date: 2/10/2016 10:08:28 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 2/10/2016 10:08:28 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CredTest', 
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
/****** Object:  Step [A_TSQL]    Script Date: 2/10/2016 10:08:28 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'A_TSQL', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON  
SELECT   
 CAST(ORIGINAL_LOGIN() AS VARCHAR(20)) AS Original_login 
,CAST(SUSER_SNAME() AS VARCHAR(20)) AS Effective_user 
,CAST(USER_NAME() AS VARCHAR(20)) AS Db_user', 
		@database_name=N'master', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [B_OS]    Script Date: 2/10/2016 10:08:28 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'B_OS', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'whoami.exe', 
		@flags=8, 
		@proxy_name=N'ssis_cmdexec_proxy'
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


--Testing 

--TODO: Create cred for a sysadmin called ssiscred

USE [msdb]
GO

/****** Object:  ProxyAccount [ssis_cmdexec_proxy]    Script Date: 2/10/2016 10:05:34 AM ******/
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'ssis_cmdexec_proxy',@credential_name=N'ssiscred', 
		@enabled=1
GO

EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'ssis_cmdexec_proxy', @subsystem_id=3
GO

EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'ssis_cmdexec_proxy', @login_name=N'SPARKHOUND\shawn.usher'
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_update_proxy @proxy_name=N'ssis_cmdexec_proxy',@credential_name=N'ssiscred', 
		@description=N''
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'ssis_cmdexec_proxy', @login_name=N'SPARKHOUND\shawn.usher'
GO

select * from msdb..sysjobstepslogs 

--- owned by sa, no proxy on cmdexec (run as SQL Server Service Account), SQLAgent svcaccount is NT Service\SQLAgent$SQL2K14
Job 'CredTest' : Step 1, 'A_TSQL' : Began Executing 2016-02-10 09:18:38

Original_login       Effective_user       Db_user             
-------------------- -------------------- --------------------
SPARKHOUND\CORP-8KJT NT SERVICE\SQLAgent$ dbo


nt service\sqlagent$sql2k14


--owned by sparkhound\shawn.usher (not a sysadmin), no proxy on cmdexec (run as SQL Server Service Account), SQLAgent svcaccount is NT Service\SQLAgent$SQL2K14

Job 'CredTest' : Step 1, 'A_TSQL' : Began Executing 2016-02-10 09:27:41

Original_login       Effective_user       Db_user             
-------------------- -------------------- --------------------
SPARKHOUND\CORP-8KJT NT SERVICE\SQLAgent$ dbo

nt service\sqlagent$sql2k14

--owned by sparkhound\william.assaf (in the sysadmin role), no proxy on cmdexec (run as SQL Server Service Account), SQLAgent svcaccount is NT Service\SQLAgent$SQL2K14

Job 'CredTest' : Step 1, 'A_TSQL' : Began Executing 2016-02-10 09:25:12

Original_login       Effective_user       Db_user             
-------------------- -------------------- --------------------
SPARKHOUND\CORP-8KJT NT SERVICE\SQLAgent$ dbo

nt service\sqlagent$sql2k14



--- owned by sa,  with proxy ssis_cmdexec_proxy on the cmdexec step, SQLAgent svcaccount is NT Service\SQLAgent$SQL2K14

Job 'CredTest' : Step 1, 'A_TSQL' : Began Executing 2016-02-10 10:02:45

Original_login       Effective_user       Db_user             
-------------------- -------------------- --------------------
SPARKHOUND\CORP-8KJT NT SERVICE\SQLAgent$ dbo

sparkhound\william.assaf

--owned by sparkhound\shawn.usher (not a sysadmin),  with proxy ssis_cmdexec_proxy on the cmdexec step, SQLAgent svcaccount is NT Service\SQLAgent$SQL2K14. Fails unless non-sysadmin has permission to use the Proxy.

Job 'CredTest' : Step 1, 'A_TSQL' : Began Executing 2016-02-10 10:05:56

Original_login       Effective_user       Db_user             
-------------------- -------------------- --------------------
SPARKHOUND\CORP-8KJT SPARKHOUND\shawn.ush guest

sparkhound\william.assaf


--owned by sparkhound\william.assaf (in the sysadmin role), with proxy ssis_cmdexec_proxy on the cmdexec step, SQLAgent svcaccount is NT Service\SQLAgent$SQL2K14
Job 'CredTest' : Step 1, 'A_TSQL' : Began Executing 2016-02-10 10:06:31

Original_login       Effective_user       Db_user             
-------------------- -------------------- --------------------
SPARKHOUND\CORP-8KJT NT SERVICE\SQLAgent$ dbo

sparkhound\william.assaf


--Create and switch SQL Agent service account to a local machine user in the local administrators group called (local machine name)\svc_local_SQLAgent


select * from msdb..sysjobstepslogs 

--- owned by sa, no proxy on cmdexec (run as SQL Server Service Account), SQLAgent svcaccount is NT Service\SQLAgent$SQL2K14
Job 'CredTest' : Step 1, 'A_TSQL' : Began Executing 2016-02-10 10:21:35

Original_login       Effective_user       Db_user             
-------------------- -------------------- --------------------
CORP-8KJTYZ1\svc_loc CORP-8KJTYZ1\svc_loc dbo

corp-8kjtyz1\svc_local_sqlagent

--owned by sparkhound\shawn.usher (not a sysadmin), no proxy on cmdexec (run as SQL Server Service Account), SQLAgent svcaccount is NT Service\SQLAgent$SQL2K14
Job 'CredTest' : Step 1, 'A_TSQL' : Began Executing 2016-02-10 10:22:05

Original_login       Effective_user       Db_user             
-------------------- -------------------- --------------------
CORP-8KJTYZ1\svc_loc SPARKHOUND\shawn.ush guest

!!!Non-SysAdmins have been denied permission to run CmdExec job steps without a proxy account.  The step failed.

--owned by sparkhound\william.assaf (in the sysadmin role), no proxy on cmdexec (run as SQL Server Service Account), SQLAgent svcaccount is NT Service\SQLAgent$SQL2K14

Job 'CredTest' : Step 1, 'A_TSQL' : Began Executing 2016-02-10 10:23:06

Original_login       Effective_user       Db_user             
-------------------- -------------------- --------------------
CORP-8KJTYZ1\svc_loc CORP-8KJTYZ1\svc_loc dbo

corp-8kjtyz1\svc_local_sqlagent


--- owned by sa,  with proxy ssis_cmdexec_proxy on the cmdexec step, SQLAgent svcaccount is NT Service\SQLAgent$SQL2K14

Job 'CredTest' : Step 1, 'A_TSQL' : Began Executing 2016-02-10 10:24:22

Original_login       Effective_user       Db_user             
-------------------- -------------------- --------------------
CORP-8KJTYZ1\svc_loc CORP-8KJTYZ1\svc_loc dbo

sparkhound\william.assaf


--owned by sparkhound\shawn.usher (not a sysadmin),  with proxy ssis_cmdexec_proxy on the cmdexec step, SQLAgent svcaccount is NT Service\SQLAgent$SQL2K14. Fails unless non-sysadmin has permission to use the Proxy.
Job 'CredTest' : Step 1, 'A_TSQL' : Began Executing 2016-02-10 10:25:34

Original_login       Effective_user       Db_user             
-------------------- -------------------- --------------------
CORP-8KJTYZ1\svc_loc SPARKHOUND\shawn.ush guest

sparkhound\william.assaf

--owned by sparkhound\william.assaf (in the sysadmin role),  with proxy ssis_cmdexec_proxy on the cmdexec step, SQLAgent svcaccount is NT Service\SQLAgent$SQL2K14

Job 'CredTest' : Step 1, 'A_TSQL' : Began Executing 2016-02-10 10:26:04

Original_login       Effective_user       Db_user             
-------------------- -------------------- --------------------
CORP-8KJTYZ1\svc_loc CORP-8KJTYZ1\svc_loc dbo

sparkhound\william.assaf

