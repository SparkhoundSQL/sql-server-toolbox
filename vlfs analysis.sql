
--TODO: Rewrite this for SQL 2016 SP2+ and SQL 2017 using sys.dm_db_log_stats instead of DBCC LOGINFO

--If no TSQL scripts generated in the Messages tab, then no log files found with need for VLF maint.

--shows the number of VLF's. CreateLSN=0 for the original created files.
--filesize /1024, *8 to get MB 
--Ideally 1 VLF per 500MB. 
--IF log >8 GB, Recreate log in 8000 MB increments.

--Shrink/regrow step only works for databases with one log file. Why do you have more than one log file anyway? Stop. Think. Ask yourself.

BEGIN TRY
IF EXISTS (select * from tempdb.sys.objects where name like '#Log%')
DROP TABLE #Log
END TRY
BEGIN CATCH
END CATCH

SET NOCOUNT ON

Create Table #Log(
	RecoveryUnitId bigint  null,--SQL 2012 and above only, comment out for <=SQL 2008
    FileID      int not null
  , FileSize_KB    bigint not null
  , StartOffset bigint not null
  , FSeqNo      bigint not null
  , [Status]    int not null
  , Parity      bigint not null
  , CreateLSN   decimal(30,0) not null
);
 
Exec sp_MSforeachdb N'Use [?]; 
Insert Into #Log  
Exec sp_executesql N''DBCC LogInfo([?]) with no_infomsgs''; 
declare @VLFCo bigint, @Avg_MB decimal(19,2), @LCnt int, @Log_MB decimal(19,2) , @T nvarchar(4000) 
select @Log_MB =sum(convert(bigint, mf.size))*8/1024 FROM sys.master_files mf where type=1 and state=0 and db_id()=mf.database_id
select @VLFCo=Count_big(StartOffset) ,	@Avg_MB=@Log_MB / Count_big(StartOffset) from #Log
if ((@Avg_MB <= 64 OR @Avg_MB > 4000) AND @Log_MB > 1024) AND (@Log_MB<8000) AND (@VLFCo>100) AND EXISTS 
(select 1 FROM sys.databases WHERE is_read_only = 0 and state=0 and db_id()=database_id)
BEGIN
		select DBName= db_name(), VLFCount=@VLFCo, Size_MB=@Log_MB, Avg_MB=@Avg_MB
SELECT @T= ''
USE [''+d.name+'']
GO
CHECKPOINT
GO
DBCC SHRINKFILE (N''''''+mf.name+'''''' , 0, TRUNCATEONLY);
GO
USE [master]
--Original Size ''+convert(varchar(1000), @Log_MB) +'' MB
ALTER DATABASE [''+d.name+''] MODIFY FILE ( NAME=N''''''+mf.name+'''''', SIZE=''+convert(varchar(30), mf.size*8/1024)+''MB );
GO
''
FROM sys.databases d inner join sys.master_files mf on d.database_id=mf.database_id where type_desc=''log'' and db_name()=d.name
IF @T IS NOT NULL BEGIN
	set @T=@T+''
''
	IF @VLFCo  > (@Log_MB / 100)
	SELECT DB_NAME()+'' log file too many VLFs.''
	IF @Avg_MB > 1024 
	SELECT DB_NAME()+'' log file VLFs too large.''
	IF (@Avg_MB < 64 AND @Log_MB > 1024)
	SELECT DB_NAME()+'' log file VLFs too small.''
	print  @T
END	
END
Truncate Table #Log;'
--Had to split this out because of sp_MSforeachdb char limits
Exec sp_MSforeachdb N'Use [?]; 
Insert Into #Log  
Exec sp_executesql N''DBCC LogInfo([?]) with no_infomsgs''; 
DECLARE @VLFCo bigint, @Avg_MB decimal(19,2), @LCnt int, @Log_MB decimal(19,2) , @Log_curr bigint, @T nvarchar(4000), @LNeed int, @Accu bigint
SELECT @Log_MB=sum(convert(bigint, mf.size))*8./1024. FROM sys.master_files mf where type=1 and state=0 and db_id()=mf.database_id
SELECT @VLFCo=Count_big(StartOffset) , @Avg_MB=@Log_MB / Count_big(StartOffset) from #Log

IF ( (@Avg_MB>1024) OR (@Avg_MB<64 AND @Log_MB > 1024)) AND (@Log_MB>8000) AND (@VLFCo>100) AND EXISTS (select 1 FROM sys.databases WHERE is_read_only = 0 and state=0 and db_id()=database_id)
BEGIN
SELECT DBName= db_name(), VLFCount=@VLFCo, Size_MB=@Log_MB, Avg_MB=@Avg_MB
SELECT @LCnt=1, @Accu=0
SELECT top 1 @T=''
USE [''+d.name+'']
GO
CHECKPOINT
GO
DBCC SHRINKFILE (N''''''+mf.name+'''''' , 0, TRUNCATEONLY);
GO
USE master
GO
--Original Size ''+convert(varchar(1000), @Log_MB) +'' MB
''
FROM sys.databases d join sys.master_files mf on d.database_id=mf.database_id where type_desc=''log'' and db_name()=d.name
select @LNeed=@Log_MB/8000
IF (@Log_MB%8000)>=0 
SELECT @LNeed=@LNeed+1 

WHILE (@LCnt<=@LNeed) BEGIN
SET @Log_curr=CASE WHEN @LCnt=1 and @Log_MB<=8000 THEN @Log_MB
WHEN @Log_MB-(8000*@LCnt)>0 THEN 8000 
WHEN @Log_MB-(8000*@LCnt)<0 THEN @Log_MB-(8000*(@LCnt-1))
END				
select @Accu=@Accu+@Log_curr
if @Log_curr>0
select top 1 @T=@T+''ALTER DATABASE [''+d.name+''] MODIFY FILE ( NAME=N''''''+mf.name+'''''', SIZE =''+convert(varchar(1000), @Accu)+'' MB );
GO
''
FROM sys.databases d join sys.master_files mf on d.database_id=mf.database_id where type_desc=''log'' and db_name()=d.name
SELECT @LCnt=@LCnt+1 
END 
END
IF @T IS NOT NULL BEGIN
set @T=@T+''
''
IF @VLFCo  > (@Log_MB / 100) SELECT DB_NAME()+'' excessive VLF count.'';
IF @Avg_MB > 1024 SELECT DB_NAME()+'' VLFs too large''; --Not sure if actually possible 
IF @Avg_MB < 64 SELECT DB_NAME()+'' VLFs too small'';
print @T;
END
Truncate Table #Log;'

Drop Table #Log;

--CitizensBilling_QA	291	1744.00	5.99
--RAPID_be_Phase2_UAT	96	1151.00	11.99

--RAPID_be_Phase2_UAT	20	1151.00	57.55

/*
More reference
----http://www.sqlskills.com/blogs/kimberly/transaction-log-vlfs-too-many-or-too-few/
----http://www.sqlskills.com/blogs/kimberly/8-steps-to-better-transaction-log-throughput/
----https://www.red-gate.com/simple-talk/sql/database-administration/sql-server-transaction-log-fragmentation-a-primer/
---"If you need a 2GB log then just create that as one step. 
---If you need a 20GB log, create that as 8GB, then extend it to 16GB and then to 20GB"
--Optimal size for Avg_MB for VLF's is 500MB.

--displays each transaction log size and space used. 
--Dbcc sqlperf (logspace)  --replaced, look for "space in log files.sql"


*/

/*

--Script to test database, create suboptimal VLF's
USE [w]
GO
DBCC SHRINKFILE (N'w2016_log' , 0, TRUNCATEONLY)
GO

USE [master]
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1001MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1002MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1003MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1004MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1005MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1006MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1007MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1008MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1009MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1010MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1011MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1012MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1013MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1014MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1015MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1016MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1017MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1018MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1019MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1020MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1021MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1022MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1023MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1024MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1025MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1026MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1027MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1028MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1029MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1030MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1031MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1032MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1033MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1034MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1035MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1036MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1037MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1038MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1039MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1040MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1041MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1042MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1043MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1044MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1045MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1046MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1047MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1048MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1049MB );
GO
--Won't show up in query above until here
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=1050MB );
GO
--further testing the 8 GB growth pattern
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=8000MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=8001MB );
GO
ALTER DATABASE [w] MODIFY FILE ( NAME=N'w2016_log', SIZE=16001MB );
GO
*/

/*

--Sample usage

USE [Tfs_Warehouse]
DBCC SHRINKFILE (N'Tfs_Warehouse_log' , 0, TRUNCATEONLY);
GO
USE [master]
--Original Size 1024.00 MB
ALTER DATABASE [Tfs_Warehouse] MODIFY FILE ( NAME=N'Tfs_Warehouse_log', SIZE=1024MB );
GO



USE [Tfs_SparkyBox]
DBCC SHRINKFILE (N'Tfs_SparkyBox_log' , 0, TRUNCATEONLY);
GO
USE [master]
--Original Size 356.00 MB
ALTER DATABASE [Tfs_SparkyBox] MODIFY FILE ( NAME=N'Tfs_SparkyBox_log', SIZE=356MB );
GO


USE [Tfs_Configuration]
DBCC SHRINKFILE (N'Tfs_Configuration_log' , 0, TRUNCATEONLY);
GO
USE [master]
--Original Size 1024.00 MB
ALTER DATABASE [Tfs_Configuration] MODIFY FILE ( NAME=N'Tfs_Configuration_log', SIZE=1024MB );
GO



*/
	
