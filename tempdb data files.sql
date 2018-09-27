--TempDB data files should all be the same size, same autogrowth settings
--Only displays TempDB data files.
use tempdb
go
DECLARE @cpu_count int 
select @cpu_count = cpu_count from sys.dm_os_sys_info

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
from sys.master_files mf
inner join tempdb.sys.database_files d
on mf.file_id = d.file_id
and mf.database_id = db_id()
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
from sys.master_files mf
inner join tempdb.sys.database_files d
on mf.file_id = d.file_id
and mf.database_id = db_id()
where d.type_desc = 'log'
order by mf.file_id asc