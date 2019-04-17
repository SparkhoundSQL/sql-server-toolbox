---based on page life expectancy.sql

--select * from [DBALogging].dbo.MemoryStats

-- Create Table
USE [DBALogging]
GO

/****** Object:  Table [dbo].[MemoryStats]    Script Date: 11/20/2017 10:01:45 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
DROP TABLE IF EXISTS [dbo].[MemoryStats]

CREATE TABLE [dbo].[MemoryStats](
	[ID] int IDENTITY(1,1) NOT NULL,
	DateTimePerformed datetimeoffset(2),
	Server_Physical_Memory_MB decimal(19,2),
	Min_Server_Mem_MB decimal (19,2),
	Max_Server_Mem_MB decimal (19,2),
	PLE_s decimal(19,2),
	Churn_MB_per_s decimal(19,2),
	Server_Available_physical_mem_GB decimal(19,2),
	SQL_Physical_memory_in_use_GB decimal(19,2),
	Target_Server_Mem_GB decimal (19,2),
	Total_Server_mem_GB decimal(19,2)
 CONSTRAINT [PK_MemoryStats] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

--Create Sproc
USE [DBALogging]
GO

/*
USE DBALogging;
GO

CREATE TABLE [dbo].[MemoryStats](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DateTimeStamp] [datetime2](7) NULL,
	[Memory_mount_point] [nvarchar](512) NULL,
	[file_system_type] [nvarchar](512) NULL,
	[logical_Memory_name] [nvarchar](512) NULL,
	[Total_Size] [DECIMAL(19,2)] NULL,
	[Available_Size] [DECIMAL(19,2)] NULL,
	[Space_Free] [DECIMAL(19,2)] NULL,
	
 CONSTRAINT [PK_MemoryStats] PRIMARY KEY CLUSTERED 
(	[ID] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
*/

CREATE PROCEDURE [dbo].[usp_GetMemoryStats] AS
BEGIN
SET NOCOUNT ON
INSERT INTO dbo.MemoryStats(
[DateTimePerformed], [Server_Physical_Memory_MB], [Min_Server_Mem_MB], [Max_Server_Mem_MB], [PLE_s], [Churn_MB_per_s], [Server_Available_physical_mem_GB], [SQL_Physical_memory_in_use_GB], [Target_Server_Mem_GB], [Total_Server_mem_GB]
)

select 
	[DateTimePerformed] = SYSDATETIMEOFFSET()
,	Server_Physical_Mem_MB = os.[Server Physical Mem (MB)] -- SQL2012+ only
,	c.[Min_Server_Mem_MB] 
,	c.[Max_Server_Mem_MB] --2147483647.00 means unlimited, just like it shows in SSMS
,	p.PLE_s --300s is only an arbitrary rule for smaller memory servers (<16gb), for larger, it should be baselined and measured.
,	'Churn (MB/s)'			=	cast((p.Total_Server_Mem_GB)/1024./NULLIF(p.PLE_s,0) as decimal(19,2))
,	Server_Available_physical_mem_GB = (SELECT cast(available_physical_memory_kb / 1024. / 1024. as decimal(19,2)) from sys.dm_os_sys_memory) 
,	SQL_Physical_memory_in_use_GB = (SELECT cast(physical_memory_in_use_kb / 1024. / 1024. as decimal(19,2)) from sys.dm_os_process_memory)
,	p.Total_Server_Mem_GB --May be more or less than memory_in_use because it 
,	p.Target_Server_Mem_GB	
from
( select 
	InstanceName = @@SERVERNAME 
,	Target_Server_Mem_GB =	max(case counter_name when 'Target Server Memory (KB)' then convert(decimal(19,3), cntr_value/1024./1024.) end)
,	Total_Server_Mem_GB	=	max(case counter_name when  'Total Server Memory (KB)' then convert(decimal(19,3), cntr_value/1024./1024.) end) 
,	PLE_s	=	max(case counter_name when 'Page life expectancy'  then cntr_value end) 
from sys.dm_os_performance_counters
--This only looks at one NUMA node. https://www.sqlskills.com/blogs/paul/page-life-expectancy-isnt-what-you-think/
) as p
cross apply (SELECT 'InstanceName' = @@SERVERNAME 
		, cpu_count , hyperthread_ratio AS 'HyperthreadRatio'
		, cpu_count/hyperthread_ratio AS 'PhysicalCPUCount'
		, 'Server Physical Mem (MB)' = cast(physical_memory_kb/1024. as decimal(19,2))   -- SQL2012+ only
		FROM sys.dm_os_sys_info ) as os
cross apply (select  
	  min_Server_Mem_MB = max(case when name = 'min server memory (MB)' then convert(bigint, value_in_use) end) 
	, max_Server_Mem_MB = max(case when name = 'max server memory (MB)' then convert(bigint, value_in_use) end) 
from sys.configurations) as c 

END;

GO

--Create SQL Agent Job
USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'Memory Stats Monitoring', 
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
EXEC msdb.dbo.sp_add_jobserver @job_name=N'Memory Stats Monitoring', @server_name = N'(LOCAL)'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Memory Stats Monitoring', @step_name=N'Exec Get Memory Stats', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbo.usp_GetMemoryStats', 
		@database_name=N'DBALogging', --make sure db name matches
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'Memory Stats Monitoring', 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'Memory Stats Monitoring', @name=N'Every 4 Hours', 
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
