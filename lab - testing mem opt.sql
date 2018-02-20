--In-memory table demo
--Drops/recreates a database called w_memopt
--In this demo, we'll insert 8.2 million rows into a table, then read 7 million sequential rows out of the table.
--Compare disk-based tables and in-memory tables, with or without columnstore, and also non-durable in-memory tables.
--20180214 WDA

EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'w_memopt'
GO
USE [master]
GO
ALTER DATABASE [w_memopt] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE [w_memopt]
GO
USE [master]
GO
print '------Starting'
print sysdatetime()
CREATE DATABASE [w_memopt]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'w_memopt', FILENAME = N'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\DATA\w_memopt.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'w_memopt_log', FILENAME = N'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\DATA\w_memopt_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [w_memopt] SET RECOVERY SIMPLE 
GO
ALTER DATABASE w_memopt
ADD FILEGROUP [w_memopt_mod_fg] CONTAINS MEMORY_OPTIMIZED_DATA; 
GO
ALTER DATABASE w_memopt
ADD FILE (NAME='TestDB_mod_dir', FILENAME='E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\DATA\w_memopt-mo') 
	TO FILEGROUP [w_memopt_mod_fg];
GO
use [w_memopt]
go

--First, let's test a disk-based table with a clustered index on an IDENTITY column.
CREATE TABLE dbo.not_memopt1
(	id int NOT NULL IDENTITY(1,1) PRIMARY KEY
,	just_a_bigint bigint NOT NULL
)
GO

INSERT INTO dbo.not_memopt1 (just_a_bigint) VALUES (1234567890)
GO
SET STATISTICS TIME ON
GO
INSERT INTO dbo.not_memopt1 (just_a_bigint) select just_a_bigint from dbo.not_memopt1  OPTION (MAXDOP 1)
GO 22
print '---------Final population insert, disk-based table'
INSERT INTO dbo.not_memopt1 (just_a_bigint) select just_a_bigint from dbo.not_memopt1  OPTION (MAXDOP 1)
GO
SET STATISTICS TIME OFF
/*
 SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 12 ms.

(2048 rows affected)
...
 SQL Server Execution Times:
   CPU time = 5047 ms,  elapsed time = 7354 ms.

(1048576 rows affected)
....
---------Final population insert, disk-based table

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 17937 ms,  elapsed time = 23705 ms.

(4194304 rows affected)


*/

print '---------Now, let''s test reading from a disk-based without a columnstore index.'
GO
SET STATISTICS TIME ON
--SELECT m1.[just_a_bigint] FROM dbo.not_memopt1 m1 inner join dbo.not_memopt1 m2 on m1.id = m2.id
SELECT m1.[just_a_bigint] FROM dbo.not_memopt1 m1 where id < 7000000

GO 3
SET STATISTICS TIME OFF
GO

/*

(6999999 rows affected)

 SQL Server Execution Times:
   CPU time = 1812 ms,  elapsed time = 32714 ms.
Batch execution completed 3 times.
*/

CREATE COLUMNSTORE INDEX IDX_CS_not_memopt_just_a_bigint ON dbo.not_memopt1 (id, just_a_bigint)
GO

print '---------Now, let''s test reading from a disk-based with a columnstore index.'
GO
SET STATISTICS TIME ON
--SELECT m1.[just_a_bigint] FROM dbo.not_memopt1 m1 inner join dbo.not_memopt1 m2 on m1.id = m2.id
SELECT m1.[just_a_bigint] FROM dbo.not_memopt1 m1 where id < 7000000
GO 3
SET STATISTICS TIME OFF
GO
/*
(6999999 rows affected)

 SQL Server Execution Times:
   CPU time = 875 ms,  elapsed time = 22629 ms.
Batch execution completed 3 times.

*/



--Second, let's test a memory-optimized table with a memory-optimized hash index on an IDENTITY column.
--Warning, this is going to take a lot of memory. Reduce the GO line to add less data.

--We'll do three different in-memory scenarios. First, a non-durable in-memory table.

CHECKPOINT
GO
CREATE TABLE [dbo].[memopt1]
(
  [id] [int] IDENTITY(1,1) NOT NULL 
, [just_a_bigint] bigint NOT NULL
--Can't have a ColumnStore index on a SCHEMA_ONLY memory-optimized table
--, INDEX [memopt1_CS] CLUSTERED COLUMNSTORE -- no key list for a clustered columnstore
, CONSTRAINT [memopt1_primaryKey]  PRIMARY KEY NONCLUSTERED HASH ([id] )	WITH ( BUCKET_COUNT = 8388608)
) WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_ONLY )
GO
INSERT INTO dbo.memopt1 (just_a_bigint) VALUES (1234567890)
GO
SET STATISTICS TIME ON
GO
INSERT INTO dbo.memopt1 (just_a_bigint) select just_a_bigint from dbo.memopt1 OPTION (MAXDOP 1)
GO 22
print '---------Final population insert, memory-optimized non-durable table with a clustered columnstore index'
INSERT INTO dbo.memopt1 (just_a_bigint) select just_a_bigint from dbo.memopt1 OPTION (MAXDOP 1)
SET STATISTICS TIME OFF
GO

/*

 SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 2 ms.

(2048 rows affected)
...
 SQL Server Execution Times:
   CPU time = 1297 ms,  elapsed time = 1296 ms.

(1048576 rows affected)
...
---------Final population insert, memory-optimized non-durable table with a clustered columnstore index

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 5953 ms,  elapsed time = 5956 ms.

(4194304 rows affected)
*/


print '---------Now, let''s test reading from a memory-optimized non-durable table with a clustered columnstore index.'
GO
SET STATISTICS TIME ON
--SELECT m1.[just_a_bigint] FROM dbo.memopt1 m1 inner join dbo.memopt1 m2 on m1.id = m2.id
SELECT m1.[just_a_bigint] FROM dbo.memopt1 m1 where id < 7000000

GO 3
SET STATISTICS TIME OFF
GO

/*


(6999999 rows affected)

 SQL Server Execution Times:
   CPU time = 2875 ms,  elapsed time = 23247 ms.
Batch execution completed 3 times.

*/
   
GO

DROP TABLE IF EXISTS [dbo].[memopt1]
GO

 --Now, a durable in-memory table.

CREATE TABLE [dbo].[memopt1]
(
  [id] [int] IDENTITY(1,1) NOT NULL
, [just_a_bigint] bigint NOT NULL
, CONSTRAINT [memopt1_primaryKey]  PRIMARY KEY NONCLUSTERED HASH ([id] )	WITH ( BUCKET_COUNT = 8388608)
) WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )
GO
INSERT INTO dbo.memopt1 (just_a_bigint) VALUES (1234567890)
GO
SET STATISTICS TIME ON
GO
INSERT INTO dbo.memopt1 (just_a_bigint) select just_a_bigint from dbo.memopt1 OPTION (MAXDOP 1)
GO 22
print '---------Final population insert, memory-optimized table'
INSERT INTO dbo.memopt1 (just_a_bigint) select just_a_bigint from dbo.memopt1 OPTION (MAXDOP 1)
SET STATISTICS TIME OFF
GO
/*
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 2 ms.

(2048 rows affected)
...

 SQL Server Execution Times:
   CPU time = 1344 ms,  elapsed time = 1922 ms.

(1048576 rows affected)
....
---------Final population insert, memory-optimized table

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 6594 ms,  elapsed time = 8957 ms.

(4194304 rows affected)
   */
 
print '---------Now, let''s test reading from a memory-optimized table without a columnstore index.'
GO
SET STATISTICS TIME ON
SELECT m1.[just_a_bigint] FROM dbo.memopt1 m1 where id < 7000000
GO 3
SET STATISTICS TIME OFF
GO

/*

(6999999 rows affected)

 SQL Server Execution Times:
   CPU time = 2704 ms,  elapsed time = 29157 ms.
Batch execution completed 3 times.
*/


--We'll recreate/repopulate the memory optimized table with a columnstore index.
--Unfortunately you cannot currently add an index to a memory-optimized table (SQL 2017), so we have to drop/recreate.

GO
DROP TABLE IF EXISTS [dbo].[memopt1]
GO
CHECKPOINT
GO
CREATE TABLE [dbo].[memopt1]
(
  [id] [int] IDENTITY(1,1) NOT NULL 
, [just_a_bigint] bigint NOT NULL
, INDEX [memopt1_CS] CLUSTERED COLUMNSTORE -- no key list for a clustered columnstore
, CONSTRAINT [memopt1_primaryKey]  PRIMARY KEY NONCLUSTERED HASH ([id] )	WITH ( BUCKET_COUNT = 8388608)
) WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )
GO
INSERT INTO dbo.memopt1 (just_a_bigint) VALUES (1234567890)
GO
SET STATISTICS TIME ON
GO
INSERT INTO dbo.memopt1 (just_a_bigint) select just_a_bigint from dbo.memopt1 OPTION (MAXDOP 1)
GO 22
print '---------Final population insert, memory-optimized table with a clustered columnstore index'
INSERT INTO dbo.memopt1 (just_a_bigint) select just_a_bigint from dbo.memopt1 OPTION (MAXDOP 1)
SET STATISTICS TIME OFF
GO

/*

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 3 ms.

(2048 rows affected)
...
 SQL Server Execution Times:
   CPU time = 1672 ms,  elapsed time = 2646 ms.

(1048576 rows affected)
...
---------Final population insert, memory-optimized table with a clustered columnstore index

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 6172 ms,  elapsed time = 9009 ms.

(4194304 rows affected)
*/


print '---------Now, let''s test reading from a memory-optimized table with a clustered columnstore index.'
GO
SET STATISTICS TIME ON
--SELECT m1.[just_a_bigint] FROM dbo.memopt1 m1 inner join dbo.memopt1 m2 on m1.id = m2.id
SELECT m1.[just_a_bigint] FROM dbo.memopt1 m1 where id < 7000000

GO 3
SET STATISTICS TIME OFF
GO

/*

(6999999 rows affected)

 SQL Server Execution Times:
   CPU time = 1547 ms,  elapsed time = 22432 ms.
Batch execution completed 3 times.

*/



print '------Done'
print sysdatetime()


/*
Summary

Inserts						final insert of
							4194304	rows
							cpu		total (ms)
disk-based					17937	23705
mem-opt						6579	8780
mem-opt with columnstore	6172	9009
mem-opt schema_only			5953	5956

Reads		
							6999999	rows
							cpu		total (ms)
disk-based					1812	32714
disk-based with columnstore	875		22629
mem-opt						2704	29157
mem-opt with columnstore	1547	22432
mem-opt schema_only			2875	23247


*/
use w_memopt
go

select 
	DBName = db_name(mf.database_id)
,	File_Logical_Name = mf.name
,	File_Physical_Name = mf.physical_name
,	cf.file_type_desc
,	FileCount = count(checkpoint_file_id)
,	Total_Size_mb =	sum(file_size_in_bytes)/1024/1024
,	Used_Size_mb	=	sum(isnull(file_size_used_in_bytes,0)) /1024/1024
from  sys.dm_db_xtp_checkpoint_files cf
inner join sys.master_files mf on cf.container_id = mf.file_id
WHERE mf.database_id = db_id()
group by db_name(mf.database_id), mf.name, mf.physical_name, cf.file_type_desc


select  
	Table_name = object_name(xis.object_id) 
,	xis.index_id
,	xis.xtp_object_id
,	xmc.memory_consumer_desc
,	xhis.total_bucket_count
,	xhis.empty_bucket_count
,	used_buckets	=	xhis.total_bucket_count - xhis.empty_bucket_count
,	xhis.avg_chain_length --want these LOW
,	xhis.max_chain_length --want these LOW
--Scans the table. Could impact performance/run for a long time.
--select object_name(xis.object_id) ,  *
from sys.dm_db_xtp_index_stats as xis
inner join sys.dm_db_xtp_memory_consumers as xmc on xmc.object_id = xis.object_id and xmc.xtp_object_id = xis.xtp_object_id
left outer join sys.dm_db_xtp_hash_index_stats as xhis on xhis.xtp_object_id = xis.xtp_object_id and xhis.object_id = xis.object_id
left outer join sys.dm_db_xtp_nonclustered_index_stats as xnis on xis.xtp_object_id = xnis.xtp_object_id and xis.object_id = xnis.object_id
WHERE object_name(xis.object_id)  is not null
GO


--How much memory (estimated)?
--Q: How much memory does a table use? A: The amount of memory used by the table cannot be calculated exactly.
--https://docs.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/table-and-row-size-in-memory-optimized-tables

select 
  objectname = OBJECT_NAME(ms.object_id)
, memory_allocated_for_table_and_indexes_GB = ((memory_allocated_for_table_kb + memory_allocated_for_indexes_kb)/1024./1024.)
, memory_allocated_for_table_GB = memory_allocated_for_table_kb/1024./1024.
, memory_allocated_for_indexes_GB = memory_allocated_for_indexes_kb/1024./1024.
, Row_Count = p.rows
from sys.dm_db_xtp_table_memory_stats  ms
inner join sys.partitions p 
on p.object_id = ms.object_id
 where ms.object_id = object_id('dbo.memopt1')  
 and p.index_id <= 1
 