
--Snapshot
SELECT 
	dbname			=	db_name(a.database_id)
,	logical_file_name = mf.name
,	db_file_type	=	mf.Type_desc 
,	io_stall_s		=	cast((a.io_stall)/60. as decimal(19,2))
,	a.io_stall_read_ms
,	a.io_stall_write_ms
,	num_of_reads	=	(a.num_of_reads)
,	num_of_writes	=	(a.num_of_writes)
,	MB_read		=	( convert(decimal(19,2),( ( a.num_of_bytes_read/ 1024. ) / 1024.  ) )) 
,	MB_written	=	( convert(decimal(19,2),( ( a.num_of_bytes_written/ 1024. ) / 1024.  ) )) 
,	MB_size_on_disk	=	( convert(decimal(19,2),( ( a.size_on_disk_bytes/ 1024. ) / 1024.  ) ))
,	mf.name
,	a.file_id
,	disk_location	=	mf.physical_name

FROM sys.dm_io_virtual_file_stats (NULL, NULL) a 
INNER JOIN sys.master_files mf ON a.file_id = mf.file_id 
AND a.database_id = mf.database_id 
--ORDER BY a.database_id ASC --database list
--ORDER BY io_stall_write_ms desc, io_stall_read_ms desc --io stall info
ORDER BY MB_written desc, MB_read desc --activity level


/*

USE DBALogging
GO
--Setup Logging Table
CREATE TABLE dbo.record_dm_io_virtual_file_stats
(	ID int not null IDENTITY(1,1) CONSTRAINT PK_record_dm_io_virtual_file_stats PRIMARY KEY
,	dbname	sysname not null
,	io_stall_s	bigint not null
,	num_of_reads bigint not null
,	num_of_writes bigint not null
,	MB_Read decimal(19,2) not null
,	MB_Written decimal(19,2) not null
,	MB_size_on_disk decimal(19,2) not null
,	sample_ms bigint
)
GO
CREATE INDEX IDX_NC_record_dm_io_virtual_file_stats_Sample_Ms ON dbo.record_dm_io_virtual_file_stats (Sample_MS DESC) INCLUDE (dbname)
GO
*/
/*
--Capture a Sample
INSERT INTO dbo.record_dm_io_virtual_file_stats
SELECT 
	dbname			=	db_name(a.database_id)
,	io_stall_s		=	sum(a.io_stall)/60.
--,	a.io_stall_read_ms
--,	a.io_stall_write_ms
,	num_of_reads	=	sum(a.num_of_reads)
,	num_of_writes	=	sum(a.num_of_writes)
,	MB_read		=	sum( convert(decimal(19,2),( ( a.num_of_bytes_read/ 1024. ) / 1024.  ) )) 
,	MB_written	=	sum( convert(decimal(19,2),( ( a.num_of_bytes_written/ 1024. ) / 1024.  ) )) 
--,	a.io_stall_write_ms
,	MB_size_on_disk	=	sum( convert(decimal(19,2),( ( a.size_on_disk_bytes/ 1024. ) / 1024.  ) ))
--,	mf.name
--,	a.file_id
--,	db_file_type	=	mf.Type_desc 
--,	disk_location	=	UPPER(SUBSTRING(mf.physical_name, 1, 2)) 
,	a.sample_ms
FROM sys.dm_io_virtual_file_stats (NULL, NULL) a 
INNER JOIN sys.master_files mf ON a.file_id = mf.file_id 
AND a.database_id = mf.database_id 
GROUP BY  a.sample_ms, a.database_id 
ORDER BY a.database_id ASC


--Latest Two Samples
;WITH cteVFS (dbname, sample_ms, sampleset, SampleStart)
AS 
(SELECT 
dbname
,sample_ms
,sampleset = DENSE_RANK() oVER ( ORDER BY sample_ms desc)
,	SampleStart = convert(datetime2(0), dateadd(ms, round(sample_ms  - (select top 1 sample_ms from sys.dm_io_virtual_file_stats(1,null)),0), getdate()))
from dbo.record_dm_io_virtual_file_stats vfs
)
, cteVFS2 (dbname,sampleset,io_stall_s,num_of_reads,num_of_writes,MB_read,MB_written,MB_size_on_disk, SampleTime_Min,SampleStart, SampleEnd)
as (
select 
	vfs.dbname
,	sampleset
,	io_stall_s = io_stall_s - LAG(io_stall_s, 1) OVER (PARTITION BY vfs.dbname ORDER BY c1.sampleset desc)
,	num_of_reads = num_of_reads - LAG(num_of_reads, 1) OVER (PARTITION BY vfs.dbname ORDER BY c1.sampleset desc)
,	num_of_writes = num_of_writes - LAG(num_of_writes, 1) OVER (PARTITION BY vfs.dbname ORDER BY c1.sampleset desc)
,	MB_read = MB_read - LAG(MB_read, 1) OVER (PARTITION BY vfs.dbname ORDER BY c1.sampleset desc)
,	MB_written = MB_written - LAG(MB_written, 1) OVER (PARTITION BY vfs.dbname ORDER BY c1.sampleset desc)
,	MB_size_on_disk = CASE WHEN c1.Sampleset = 1 THEN MB_size_on_disk ELSE NULL END
,	Sample_Duration_Min = convert(decimal(19,2), (vfs.sample_ms - LAG(vfs.sample_ms, 1) OVER (PARTITION BY vfs.dbname ORDER BY c1.sampleset desc))/1000./60.)
,	Sample_Start = min(samplestart) OVER ()
,	Sample_End = max(samplestart) OVER ()
from dbo.record_dm_io_virtual_file_stats vfs
inner join cteVFS c1 on vfs.dbname = c1.dbname 
and vfs.sample_ms = c1.sample_ms 
WHERE Sampleset  in (1,2)
)
select dbname,io_stall_s,num_of_reads,num_of_writes,MB_read,MB_written,MB_size_on_disk, SampleTime_Min, SampleStart, SampleEnd
from cteVFS2 where sampleset = 1
ORDER BY MB_read + MB_Written desc

--First Sample vs Latest Sample
;WITH cteVFS (dbname, sample_ms, sampleset, SampleStart)
AS 
(SELECT 
dbname
,sample_ms
,sampleset = DENSE_RANK() oVER ( ORDER BY sample_ms desc)
,	SampleStart = convert(datetime2(0), dateadd(ms, round(sample_ms  - (select top 1 sample_ms from sys.dm_io_virtual_file_stats(1,null)),0), getdate()))
from dbo.record_dm_io_virtual_file_stats vfs
)
, cteVFS2 (dbname,sampleset,io_stall_s,num_of_reads,num_of_writes,MB_read,MB_written,MB_size_on_disk, SampleTime_Min,SampleStart, SampleEnd)
as (
select 
	vfs.dbname
,	sampleset
,	io_stall_s = io_stall_s - LAG(io_stall_s, 1) OVER (PARTITION BY vfs.dbname ORDER BY c1.sampleset desc)
,	num_of_reads = num_of_reads - LAG(num_of_reads, 1) OVER (PARTITION BY vfs.dbname ORDER BY c1.sampleset desc)
,	num_of_writes = num_of_writes - LAG(num_of_writes, 1) OVER (PARTITION BY vfs.dbname ORDER BY c1.sampleset desc)
,	MB_read = MB_read - LAG(MB_read, 1) OVER (PARTITION BY vfs.dbname ORDER BY c1.sampleset desc)
,	MB_written = MB_written - LAG(MB_written, 1) OVER (PARTITION BY vfs.dbname ORDER BY c1.sampleset desc)
,	MB_size_on_disk = CASE WHEN c1.Sampleset = 1 THEN MB_size_on_disk ELSE NULL END
,	Sample_Duration_Min = convert(decimal(19,2), (vfs.sample_ms - LAG(vfs.sample_ms, 1) OVER (PARTITION BY vfs.dbname ORDER BY c1.sampleset desc))/1000./60.)
,	Sample_Start = min(samplestart) OVER ()
,	Sample_End = max(samplestart) OVER ()
from dbo.record_dm_io_virtual_file_stats vfs
inner join cteVFS c1 on vfs.dbname = c1.dbname 
and vfs.sample_ms = c1.sample_ms 
WHERE Sampleset = 1 OR SampleSet = (SELECT MAX(SampleSet) FROM cteVFS)
)
select dbname,io_stall_s,num_of_reads,num_of_writes,MB_read,MB_written,MB_size_on_disk, SampleTime_Min, SampleStart, SampleEnd
from cteVFS2 where sampleset = 1
ORDER BY MB_read + MB_Written desc

*/