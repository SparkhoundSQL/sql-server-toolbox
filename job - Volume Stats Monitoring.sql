-- Create Table
USE [DBAHound]
GO

/****** Object:  Table [dbo].[VolumeStats]    Script Date: 11/20/2017 10:01:45 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[VolumeStats](
	[ID] int IDENTITY(1,1) NOT NULL,
	[DiskDrive] nvarchar (512) NULL,
	[FileSystemType] nvarchar (512) NULL,
	[LogicalVolumeName] nvarchar (512) NULL,
	[DriveSize] DECIMAL(19,2) NULL,
	[DriveFreeSpace] DECIMAL(19,2) NULL,
	[DrivePercentFree] DECIMAL(19,2) NULL,
	[DateTimePerformed] datetimeoffset(2) NULL,
 CONSTRAINT [PK_VolumeStats] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

--Create Sproc
USE [DBAHound]
GO

/****** Object:  StoredProcedure [dbo].[usp_GetVolumeStats]    Script Date: 11/20/2017 10:02:37 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
USE DBAHound;
GO

CREATE TABLE [dbo].[VolumeStats](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[volume_mount_point] [nvarchar](512) NULL,
	[file_system_type] [nvarchar](512) NULL,
	[logical_volume_name] [nvarchar](512) NULL,
	[Total_Size] [DECIMAL(19,2)] NULL,
	[Available_Size] [DECIMAL(19,2)] NULL,
	[Space_Free] [DECIMAL(19,2)] NULL,
	[DateTimeStamp] datetimeoffset(2) NULL,
 CONSTRAINT [PK_VolumeStats] PRIMARY KEY CLUSTERED 
(	[ID] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
*/

CREATE PROCEDURE [dbo].[usp_GetVolumeStats]
@Threshold int
AS
BEGIN
--Changed all floats and decimal(18,2) to decimal(19,2) - WDA 20170312
if object_id('tempdb..#VolumeStats') is not null begin drop table #VolumeStats end;
Create table #VolumeStats
(ID int identity(1,1),
volume_mount_point nvarchar(512),
file_system_type nvarchar(512),
logical_volume_name nvarchar(512),
Total_Size DECIMAL(19,2),
Available_Size DECIMAL(19,2),
Space_Free DECIMAL(19,2),
DateTimePerformed datetimeoffset(2)
)


DECLARE @TimeStamp datetimeoffset(2) = sysdatetimeoffset()
DECLARE VolumeInfo cursor
FOR 
SELECT	  MAX(vs.volume_mount_point)
		, MAX(vs.file_system_type)
		, MAX(vs.logical_volume_name)
		, [Total Size (GB)] = CONVERT(DECIMAL(19,2), MIN(vs.total_bytes/1073741824.0)) 
		, [Available Size (GB)] = CONVERT(DECIMAL(19,2), MIN(vs.available_bytes/1073741824.0)) 
		, [Space Free %] = CONVERT(DECIMAL(19,2), MIN(vs.available_bytes * 1. / vs.total_bytes * 100.))
		, @TimeStamp
FROM sys.master_files AS f WITH (NOLOCK)
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs
GROUP BY vs.volume_mount_point --group by was added 20171107 CLL

DECLARE @volume nvarchar(512),@file_system_type nvarchar(512),@logical_name nvarchar(512)
DECLARE @TotalSize DECIMAL(19,2),@AvailableSize DECIMAL(19,2), @percent DECIMAL(19,2)
DECLARE @MyTime datetimeoffset(2)

OPEN VolumeInfo

FETCH NEXT FROM VolumeInfo INTO @volume,@file_system_type,@logical_name,@TotalSize,@AvailableSize,@percent,@MyTime
WHILE (@@FETCH_STATUS <> -1)
BEGIN

--if @percent > 20 -- changed 20170312 WDA
if @percent <= @Threshold --If free space % is less than 20% --- changed by to @Threshold parameter which is passed via the Agent Job.  This way you don't have to change the Sproc just the job
BEGIN
    INSERT INTO dbo.VolumeStats(
DiskDrive,FileSystemType, LogicalVolumeName,DriveSize,DriveFreeSpace,DrivePercentFree,DateTimePerformed
)
    values(@volume,@file_system_type,@logical_name,@TotalSize,@AvailableSize,@percent,@TimeStamp)
    insert into #VolumeStats(volume_mount_point,file_system_type,logical_volume_name,Total_Size,Available_Size,Space_Free,DateTimePerformed)
    VALUES(@volume,@file_system_type,@logical_name,@TotalSize,@AvailableSize,@percent,@TimeStamp)
END
else
BEGIN
    INSERT INTO dbo.VolumeStats(
DiskDrive,FileSystemType, LogicalVolumeName,DriveSize,DriveFreeSpace,DrivePercentFree,DateTimePerformed
)
    values(@volume,@file_system_type,@logical_name,@TotalSize,@AvailableSize,@percent,@TimeStamp)

END

FETCH NEXT FROM VolumeInfo INTO @volume,@file_system_type,@logical_name,@TotalSize,@AvailableSize,@percent,@MyTime
END
CLOSE VolumeInfo
DEALLOCATE VolumeInfo

if (SELECT COUNT(*) FROM #VolumeStats 
where logical_volume_name <> 'TempDBdata' --added to ignore the tempdb drive - 20170311 WDA 
) > 0
BEGIN --added BEGIN/END wrap on IF - WDA 20170312 
	DECLARE @tableHTML  NVARCHAR(MAX) ;  
  
	SET @tableHTML =  
		N'<h2>Server: ' + @@SERVERNAME + '</h2>' +
		N'<H3>Drive Space Alert</H3>' +  
		N'<table border="1">' +  
		N'<tr><th>Volume</th><th>File Sytem Type</th>' +  
		N'<th>Logical Name</th><th>Total Size</th><th>Available Size</th>' +  
		N'<th>Percent Free</th></tr>' +  
		CAST ( ( SELECT
				 td = v.volume_mount_point,  '',
				 td = v.file_system_type, '',
				 td = v.logical_volume_name, '',
				 td = convert(varchar(8),v.Total_Size), '',
				 td = convert(varchar(8),v.Available_Size), '',
				 td = convert(varchar(8),v.Space_Free), ''
				from #VolumeStats v
				order by v.volume_mount_point
				  FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ;  
  
	BEGIN
	--if @percent < @Threshold -- removed WDA 20170418
	--BEGIN
		EXEC msdb.dbo.sp_send_dbmail  
		   @recipients = 'sql.alerts@sparkhound.com',  
		   @body = @tableHTML, 
		   @importance = 'HIGH', 
		   @body_format ='HTML',
		   @subject = 'Volume Size Report' ;  
	--END
	END
	END
END;

GO


--Create SQL Agent Job
USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'Volume Stats_Daily Insert', 
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
EXEC msdb.dbo.sp_add_jobserver @job_name=N'Volume Stats_Daily Insert', @server_name = N'(LOCAL)'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Volume Stats_Daily Insert', @step_name=N'Exec Get Volume Stats', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbo.usp_GetVolumeStats @Threshold = 14;', 
		@database_name=N'DBAHound', --make sure db name matches
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'Volume Stats_Daily Insert', 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'Volume Stats_Daily Insert', @name=N'Every 4 Hours', 
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
