--***PROTOTYPE***
--Intention is to catch only severe errors and startup failures
--Specifically because before Service Broker starts, some error Alerts may not send emails. This script waits one minute, checks log, sends email regardless.

--Find two TODO's for changing the name of the DBALogging db local to the server
--Find two TODO's for mail profile and recipient near bottom of job

USE DBALogging   --TODO verify this database name
GO
--DROP table dbo.startup_readerrorlog_found 

IF NOT EXISTS (select * from sys.objects where name = 'startup_readerrorlog_found') 
CREATE table dbo.startup_readerrorlog_found 
( ID int not null IDENTITY(1,1) CONSTRAINT PK_startup_readerrorlog_found PRIMARY KEY
, LogDate datetime2(2) not null  
, LogProcessInfo nvarchar(255)  null 
, [LogMessageText] nvarchar(4000) not null 
, When_Inserted datetime2(2) not null CONSTRAINT DF_startup_readerrorlog_found_When_Inserted DEFAULT (sysdatetime())
, When_Startup_Detected datetime2(2) not null 
)

USE [msdb]
GO
declare @startup_job_id uniqueidentifier
select @startup_job_id = job_id from  msdb.dbo.sysjobs where name = 'Startup error check'

IF @startup_job_id is not null
EXEC msdb.dbo.sp_delete_job @job_id=@startup_job_id, @delete_unused_schedule=1
GO

DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'Startup error check', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'Startup error check', @server_name = N'(local)'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Startup error check', @step_name=N'check for errors', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Intention is to catch only severe errors and startup failures
--Specifically because before Service Broker starts, some error Alerts may not send emails.
--Version# Q419 Rev01

declare @When_Startup_Detected datetime2(2)
select @When_Startup_Detected = sysdatetime()

WAITFOR DELAY ''00:01'';  --wait one minute

declare @readerrorlog table 
( LogDate datetime2(2) not null   
, LogProcessInfo nvarchar(255)  null 
, [LogMessageText] nvarchar(4000) not null 
)

declare @readerrorlog_found table 
( LogDate datetime2(2) not null  
, LogProcessInfo nvarchar(255)  null 
, [LogMessageText] nvarchar(4000) not null 
)

INSERT INTO @readerrorlog (LogDate, LogProcessInfo, LogMessageText)
	EXEC master.dbo.xp_readerrorlog  
	  0					--current log file
	, 1					--SQL Error Log
	, N''''				--search string 1, must be unicode. Leave empty on purpose, as we do filtering later on.
	, N''''				--search string 2, must be unicode. Leave empty on purpose, as we do filtering later on.
	, null, null --time filter. Should be @oldestdate < @now
	, N''desc''			--sort

--select * from @readerrorlog order by LogDate asc

INSERT INTO @readerrorlog_found  (LogDate, LogProcessInfo, LogMessageText)
select LogDate, LogProcessInfo, LogMessageText from @readerrorlog
where 
LogDate > dateadd(mi, -10, sysdatetime()) and
(LogMessageText like ''%Error%''
or LogMessageText like ''%corruption%''
or LogMessageText like ''%prevent%''
or LogMessageText like ''%could not register the Service Principal Name%''
or LogMessageText like ''%could not be decrypted%''
or LogMessageText like ''%warning%''
or LogMessageText like ''%Could not open file%''
or LogMessageText like ''%Unable to open%''
or LogMessageText like ''%cannot be opened%''
or LogMessageText like ''%insufficient%''
or LogMessageText like ''%exception%''
or LogMessageText like ''%transaction log for database%is full%''
or LogMessageText like ''%non-yielding%''
or LogMessageText like ''%Stack signature%''
or LogMessageText like ''%aborted%''
or LogMessageText like ''%Access is denied%''
or LogMessageText like ''%Run DBCC%.''
or LogMessageText like ''%Attempt to fetch%failed%''
or LogMessageText like ''%An error occurred during recovery%''
or LogMessageText like ''%marked SUSPECT%''
or LogMessageText like ''%I/O error%''
or LogMessageText like ''%could not redo%''
or LogMessageText like ''%* DBCC database corruption%''

)
and (LogMessageText not like ''Registry startup parameters%''
and LogMessageText not like ''Logging SQL Server messages in file%''
and LogMessageText not like ''%without errors%''
and LogMessageText not like ''%found 0 errors%''
and LogMessageText not like ''Login failed%''
and LogMessageText not like ''%informational message only%''
and LogMessageText not like ''%no user action is required%''
and LogMessageText not like ''Error: 18456, Severity: 14%''
and LogMessageText not like ''%because it is read-only.%''
and LogMessageText not like ''%Could not find a login matching the name provided%''

and LogMessageText not like ''%The server will automatically attempt to re-establish listening.%''
and LogMessageText not like ''%Error: 26050, Severity: 17%''

and LogMessageText not like ''%Database%cannot be opened because it is offline.%''
and LogMessageText not like ''Error: 942, Severity: 14, State: 4.''

and LogMessageText not like ''The login packet used to open the connection is structurally invalid%''
and LogMessageText not like ''Error: 17832, Severity: 20, State: 18.''

and LogMessageText not like ''Error: 3041, Severity: 16, State: 1.''

and LogMessageText not like ''Setting database option ANSI_%''

and LogMessageText not like ''%Wait a few minutes%''
and LogMessageText not like ''Error: 17187, Severity: 16%''

and LogMessageText not like ''The login packet used to open the connection is structurally invalid%''
and LogMessageText not like ''Error: 17832, Severity: 20%''

and LogMessageText not like ''Length specified in network packet payload did not match number of bytes read%''
and LogMessageText not like ''Error: 17836, Severity: 20%.''

and LogMessageText not like ''Could not connect because the maximum number of % dedicated administrator connections already exists%''
and LogMessageText not like ''Error: 17810, Severity: 20%''

and LogMessageText not like ''READ UNCOMMITTED%''
and LogMessageText not like ''Error: 7886, Severity: 20%''

and LogMessageText not like ''%Windows return code: 0x2098, state: 15%''
and LogMessageText not like ''The SQL Server Network Interface library could not register the Service Principal Name (SPN)%''

and LogMessageText not like ''Machine supports memory error recovery. SQL memory protection is enabled to recover from memory corruption.''

and LogMessageText not like ''The state of the local availability replica%''
and LogMessageText not like ''Error: 35262%'' --informational only
and LogMessageText not like ''Error: 41145%'' --informational only


)
order by LogDate


IF EXISTS  (Select * from sys.databases d where STATE = 4)
INSERT INTO @readerrorlog_found (LogDate, LogProcessInfo, LogMessageText)
select sysdatetime(), NULL, ''Database name '' + d.name + ''is in SUSPECT mode!''
from sys.databases d where STATE = 4;

declare @subject nvarchar(100) = ''SQL Server instance Startup Report''

IF NOT EXISTS  (Select * from @readerrorlog_found) 
	INSERT INTO @readerrorlog_found (LogDate, LogProcessInfo, LogMessageText)
	VALUES (sysdatetime(), NULL, ''No listed startup errors found.'');
ELSE 
	set @subject = ''EMERGENCY '' + @subject;


declare @body nvarchar(4000) = ''SQL Server instance startup detected '' + @@SERVERNAME
select @body = @body + ''
<table border=0>''
select 	@body = @body + ''
<tr><td>'' + convert(nvarchar(30), LogDate) + ''</td>
<td>'' + isnull(LogProcessInfo, '''')+ ''</td>
<td>'' + LogMessageText+ ''</td></tr>''
--, *
from @readerrorlog_found order by LogDate asc;
select @body = @body + ''</table>
''

select @body = LEFT(@body, 4000) --Safety

BEGIN TRY

INSERT INTO dbo.startup_readerrorlog_found ( LogDate , LogProcessInfo , [LogMessageText], When_Startup_Detected )
Select LogDate, LogProcessInfo , [LogMessageText], @When_Startup_Detected 
from @readerrorlog_found  order by LogDate asc;

END TRY 
BEGIN CATCH

	INSERT INTO dbo.startup_readerrorlog_found ( LogDate , LogProcessInfo , [LogMessageText], When_Startup_Detected )
	VALUES (sysdatetime(), ''Error writing log entries to table!'', ''Error number '' + str(ERROR_NUMBER()) + '' Error Message: ''+ ERROR_MESSAGE(), @When_Startup_Detected);

	--THROW;

END CATCH;

BEGIN TRY

	--Send email
	exec msdb.dbo.sp_send_dbmail 
		@profile_name = ''sh-tenroxsql''  --TODO: must configure this server-specific, use the Dbmail profile that Agent is configured to use. (We could do a xp_instance_regread search here but regkey is too variable from server to server)
	, @recipients = ''sql.alerts@sparkhound.com'' --TODO: Must configure this for the sql.alerts@sparkhound.com or internal distribution group
	, @subject = @subject
	, @body = @body, @exclude_query_output = 0
	, @body_format =''html''

END TRY 
BEGIN CATCH

	INSERT INTO dbo.startup_readerrorlog_found ( LogDate , LogProcessInfo , [LogMessageText], When_Startup_Detected )
	VALUES (sysdatetime(), ''Sending email failed!'', ''Error number '' + str(ERROR_NUMBER()) + '' Error Message: ''+ ERROR_MESSAGE(), @When_Startup_Detected);

	THROW;

END CATCH;', 
		@database_name=N'DBALogging', --TODO verify this database name
		@flags=4
GO

EXEC msdb.dbo.sp_update_job @job_name=N'Startup error check', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO
--Configure to run at SQL service startup
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'Startup error check', @name=N'sql startup', 
		@enabled=1, 
		@freq_type=64, 
		@freq_interval=1, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190305, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO

