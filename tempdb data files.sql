--TempDB data files should all be the same size, same autogrowth settings
--Only displays TempDB data files.
USE tempdb
GO
DECLARE @cpu_count int;
SELECT @cpu_count = cpu_count from sys.dm_os_sys_info;

--data files
select mf.name
, CurrentSize_MB = (d.size*8.)/1024. --actual current file size
, InitialSize_MB = (mf.size*8.)/1024. --initial file size
, GrowthMb = (mf.growth*8.)/1024.
, mf.is_percent_growth
, MaxFileSizeMB = CASE WHEN mf.max_size > -1 THEN cast((mf.max_size*8.)/1024. as varchar(100)) ELSE 'Unlimited' END -- "-1" is unlimited
, Recommendation = CASE WHEN d.size > mf.size THEN 'Increase TempDB Data files size to match or exceed current size.' + CHAR(10) ELSE '' END +
CASE WHEN mf.size <> AVG(mf.size) OVER (PARTITION BY mf.database_id) THEN 'Set all TempDB Data files to the same initial size.' + CHAR(10) ELSE '' END + 
CASE WHEN d.size <> AVG(d.size) OVER (PARTITION BY mf.database_id) THEN 'Grow TempDB Data files to the same current size.' + CHAR(10) ELSE '' END +
CASE WHEN mf.growth <> AVG(mf.growth) OVER (PARTITION BY mf.database_id) THEN 'Match all TempDB Data files autogrowth rates.' + CHAR(10) ELSE '' END +
CASE WHEN mf.max_size <> AVG(mf.max_size) OVER (PARTITION BY mf.database_id) THEN 'Match all TempDB Data files max file size.' + CHAR(10) ELSE '' END +
CASE WHEN count(mf.file_id) OVER (PARTITION BY mf.database_id) > @cpu_count THEN 'Too many TempDB Data files, reduce to '+cast(@cpu_count as varchar(3)) + ' or lower.' + CHAR(10) ELSE '' END
, mf.physical_name
, volume_letter = UPPER(vs.volume_mount_point)
, file_system_type
, drive_size_GB = (CONVERT(decimal(19,2), vs.total_bytes/1024./1024./1024. ))
, drive_free_space_GB = (CONVERT(decimal(19,2), vs.available_bytes/1024./1024./1024. ))
, drive_pct_free = (CONVERT(DECIMAL(5,2), vs.available_bytes * 100.0 / vs.total_bytes))
from sys.master_files mf
inner join tempdb.sys.database_files d
on mf.file_id = d.file_id
and mf.database_id = db_id()
cross apply sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs --only return volumes where there is database file (data or log)
where d.type_desc = 'rows'
order by mf.file_id asc

--log file
select mf.name
, CurrentSize_MB = (d.size*8.)/1024. --actual current file size
, InitialSize_MB = (mf.size*8.)/1024. --initial file size
, GrowthMb = (mf.growth*8.)/1024.
, mf.is_percent_growth
, MaxFileSizeMB = CASE WHEN mf.max_size > -1 THEN cast((mf.max_size*8.)/1024. as varchar(100)) ELSE 'Unlimited' END -- "-1" is unlimited
, Recommendation = CASE WHEN d.size > mf.size THEN 'Increase TempDB Log file size to match or exceed current size.' + CHAR(10) ELSE '' END
, mf.physical_name
, volume_letter = UPPER(vs.volume_mount_point)
, file_system_type
, drive_size_GB = (CONVERT(decimal(19,2), vs.total_bytes/1024./1024./1024. ))
, drive_free_space_GB = (CONVERT(decimal(19,2), vs.available_bytes/1024./1024./1024. ))
, drive_pct_free = (CONVERT(DECIMAL(5,2), vs.available_bytes * 100.0 / vs.total_bytes))
from sys.master_files mf
inner join tempdb.sys.database_files d
on mf.file_id = d.file_id
and mf.database_id = db_id() 
cross apply sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs --only return volumes where there is database file (data or log)
where d.type_desc = 'log'
order by mf.file_id asc;

SELECT servicename, status_desc, last_startup_time FROM sys.dm_server_services;
GO
--To resize tempdb: 

/*
USE [master]
GO
ALTER DATABASE [tempdb]   MODIFY FILE ( NAME = N'<tempdfilename>'  , SIZE = <Desired File Size>);
GO

USE [tempdb]
GO
CHECKPOINT
GO
DBCC SHRINKFILE (N'<tempdfilename>' , 0, TRUNCATEONLY);
GO
*/
