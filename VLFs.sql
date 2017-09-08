

--displays each transaction log size and space used. 
--Dbcc sqlperf (logspace)  --replaced, look for "space in log files.sql"

--Shows transactions in the log
--Dbcc log ([tempdb], 0) 

--shows the number of VLF's. CreateLSN = 0 for the original created files.
--filesize /1024, *8 to get MB 
--Ideally <50 VLF's per tlog
--If too many VLF's truncate the log and recreate in 8gb increments.
----http://www.sqlskills.com/blogs/kimberly/transaction-log-vlfs-too-many-or-too-few/
----http://www.sqlskills.com/blogs/kimberly/8-steps-to-better-transaction-log-throughput/
----https://www.red-gate.com/simple-talk/sql/database-administration/sql-server-transaction-log-fragmentation-a-primer/

---"If you need a 2GB log then just create that as one step. 
---If you need a 20GB log, create that as 8GB, then extend it to 16GB and then to 20GB"

--If no TSQL scripts generated in the Messages tab, then no log files of a significant size were found with >50 VLF's.

--Shrink/regrow step only works for databases with one log file. Why do you have more than one log file anyway?

BEGIN TRY
IF EXISTS (select * from tempdb.sys.objects where name like '#LogInfo%')
DROP TABLE #LogInfo
IF EXISTS (select * from tempdb.sys.objects where name like '#VLFCount%')
DROP TABLE #VLFCount
END TRY
BEGIN CATCH
END CATCH

SET NOCOUNT ON

Create Table #LogInfo(
	RecoveryUnitId bigint not null--SQL 2012 and above only, comment out for <=SQL 2008
  , FileID      bigint not null
  , FileSize    bigint not null
  , StartOffset bigint not null
  , FSeqNo      bigint not null
  , [Status]    bigint not null
  , Parity      bigint not null
  , CreateLSN   decimal(28,0) not null
);
 
Create Table #VLFCount(
    Database_Name   sysname not null 
  , Recovery_model_desc nvarchar(60) not null
  , VLFCount       bigint not null
  , log_size_KB			bigint not null
);

Exec sp_MSforeachdb N'Use [?]; 
Insert Into #LogInfo  
Exec sp_executesql N''DBCC LogInfo([?]) with no_infomsgs''; 

Insert Into #VLFCount 
Select d.name, d.Recovery_model_desc, VLFCount = Count_big(distinct l.CreateLSN), log_size_KB = sum(convert(bigint, l.FileSize))
From #LogInfo l
inner join sys.databases d on db_name() = d.name
--inner join sys.master_files mf on db_id() = mf.database_id WHERE type_desc = ''log''
group by d.name, Recovery_model_desc

declare @VLFCount bigint 
select @VLFCount = Count_big(distinct l.CreateLSN) from #LogInfo l
if (@VLFCount  > 50)
BEGIN
	DECLARE @LogFileSize_MB_To_Allocate bigint, @loopcounter int, @LogFileSize_MB bigint , @TSQL nvarchar(4000) 
	select @LogFileSize_MB  = sum(convert(bigint, mf.size))*8/1024 FROM sys.master_files mf where type_desc = ''log'' and db_id() = mf.database_id

	IF (@LogFileSize_MB < (8000)) BEGIN
		select DBName= db_name(), VLFCount = @VLFCount, Size_GB = sum(log_size_KB)/1024./1024.
		, LogFileSize_MB = @LogFileSize_MB
		from  #VLFCount where database_name = db_name();

		SELECT @TSQL =  ''
		USE [''+d.name+'']
		DBCC SHRINKFILE (N''''''+mf.name+'''''' , 0, TRUNCATEONLY)
		GO
		USE [master]
		ALTER DATABASE [''+d.name+''] MODIFY FILE ( NAME = N''''''+mf.name+'''''', SIZE = ''+convert(varchar(30), mf.size*8/1024)+''MB )
		GO
		''
		FROM sys.databases d inner join sys.master_files mf on d.database_id = mf.database_id where type_desc = ''log'' and db_name() = d.name

		IF @TSQL IS NOT NULL
		BEGIN
		set @TSQL = @TSQL + ''
		--Returns file to original size.''
		SELECT DB_NAME() + '' log file excessive VLFs. See messages.''
		print  @TSQL
		END
	END

END
Truncate Table #LogInfo;'

--Had to split up this foreachdb because of char limits
Exec sp_MSforeachdb N'Use [?]; 
Insert Into #LogInfo  
Exec sp_executesql N''DBCC LogInfo([?]) with no_infomsgs''; 
declare @VLFCount bigint 
select @VLFCount = Count_big(distinct CreateLSN) from #LogInfo
if (@VLFCount  > 50)
BEGIN
DECLARE @LogFileSize_MB_To_Allocate bigint, @loopcounter int, @LogfileSize_MB bigint , @logFileSize_MB_Current bigint, @TSQL nvarchar(4000) 
select @LogfileSize_MB  = sum(convert(bigint, mf.size))*8/1024. FROM sys.master_files mf where type_desc = ''log'' and db_id() = mf.database_id
IF (@LogfileSize_MB >= (8000)) BEGIN
select DBName= db_name(), VLFCount = sum(VLFCount),  Size_GB = sum(log_size_KB)/1024./1024.
from  #VLFCount where database_name = db_name();
SET @LogFileSize_MB_To_Allocate = (@LogfileSize_MB - 8000)
SET @loopcounter = 1
select top 1 @TSQL =  ''USE [''+d.name+'']
DBCC SHRINKFILE (N''''''+mf.name+'''''' , 0, TRUNCATEONLY)
GO
USE [master]
ALTER DATABASE [''+d.name+''] MODIFY FILE ( NAME = N''''''+mf.name+'''''', SIZE = 8000MB )  --INITIAL FILE at 8000MB (See Paul Randal blog). EXTEND IN 8GB  
GO
''
FROM sys.databases d inner join sys.master_files mf on d.database_id = mf.database_id where type_desc = ''log''  and db_name() = d.name

WHILE (@LogFileSize_MB_To_Allocate> 0)
BEGIN
SET @LogFileSize_MB_current = CASE WHEN  (8000 + (@loopCounter * 8192)) > @LogfileSize_MB THEN @LogfileSize_MB ELSE  (8000 + (@loopCounter * 8192))  END
select top 1 @TSQL = @TSQL + ''ALTER DATABASE [''+d.name+''] MODIFY FILE ( NAME = N''''''+mf.name+'''''', SIZE = '' + convert(varchar(1000), @LogFileSize_MB_current) +''MB )
GO
''
FROM sys.databases d inner join sys.master_files mf on d.database_id = mf.database_id where type_desc = ''log''  and db_name() = d.name
SET @LoopCounter = @LoopCounter + 1
SET @LogFileSize_MB_To_Allocate = @LogfileSize_MB - @LogFileSize_MB_current
END
set @TSQL = @TSQL + ''
''
END
IF @TSQL is not null
BEGIN
SELECT DB_NAME() + '' log file excessive VLFs. See messages.''
print  @TSQL
END
END
Truncate Table #LogInfo;'

select * from #VLFCount

Drop Table #LogInfo;
Drop Table #VLFCount;


/*
--print ''At '' + convert(varchar(100), @LogFileSize_MB_current) +'', '' + convert(varchar(100), @LogFileSize_MB_To_Allocate) + '' left of '' + convert(varchar(100), @LogfileSize_MB)

USE [w]
GO
DBCC SHRINKFILE (N'w_log' , 0, TRUNCATEONLY)
GO
USE [master]
GO
ALTER DATABASE [w] MODIFY FILE ( NAME = N'w_log', SIZE = 8000MB ) --INITIAL FILE SIZE CAPPED at 8000MB (See Paul Randal blog). EXTEND IN 8GB INCREMENTS 
GO
--like this:
ALTER DATABASE [w] MODIFY FILE ( NAME = N'w_log', SIZE = 8001MB ) --... and so on up to current size = 8001MB

*/


	