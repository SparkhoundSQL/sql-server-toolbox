-------------------------------------------------------------
----  DBA Hound First Byte
-- Works only for SQL 2008+
-------------------------------------------------------------
DECLARE @Results TABLE
(severity varchar(15) null
,Category varchar(50) null
,MostRecent datetime2(0) null
,Issue varchar(max) null
,Details varchar(max) null
);


-------------------------------------------------------------
---  Severity 'Critical'
-------------------------------------------------------------

------------------  Disaster Recovery / Backups -------------
--  This should return a row for every database, if there are no rows then
--  backups have been failing or never done
--------------------------------------------------------------
INSERT INTO @Results(severity,Category,MostRecent,Issue,Details)
SELECT  
    '(1) Critical' 
    ,Category	=	'Backup Gap'  
	,MostRecent	=	MAX(b.backup_finish_date)
    ,'Backups out of date for ' + d.name + N' ' AS Issue 
    ,'Database last had a full backup: ' + COALESCE(CAST(MAX(b.backup_finish_date) AS VARCHAR(25)),'never') AS Details
FROM    master.sys.databases d
LEFT OUTER JOIN msdb.dbo.backupset b ON d.name COLLATE SQL_Latin1_General_CP1_CI_AS = b.database_name COLLATE SQL_Latin1_General_CP1_CI_AS
    AND b.type = 'D'
    AND b.server_name = SERVERPROPERTY('ServerName') 
WHERE  d.database_id <> 2 
AND d.state NOT IN(1, 6, 10) 
AND d.is_in_standby = 0 
AND d.source_database_id IS NULL 
GROUP BY d.name
HAVING  MAX(b.backup_finish_date) <= DATEADD(dd, -7, sysdatetime()) OR MAX(b.backup_finish_date) IS NULL;

INSERT INTO @Results(severity,Category,Issue,Details)
SELECT DISTINCT
   '(1) Critical'
   ,Category	=	'Backup Gap'  
   ,[Issue]		=	'Database '+ d.name + N' is in FULL Recovery mode w/o a recent Log Backup' 
   ,Details		=	 ( 'The log file has not been backed up for at least two days, is ' + CAST(CAST((SELECT ((SUM([mf].[size]) * 8.) / 1024.) FROM sys.[master_files] AS [mf] WHERE [mf].[database_id] = d.[database_id] AND [mf].[type_desc] = 'LOG') AS DECIMAL(18,2)) AS VARCHAR) + 'MB and growing unchecked' ) 
FROM    master.sys.databases d
WHERE   d.recovery_model IN ( 1, 2 )
    AND d.database_id NOT IN ( 2, 3 )
    AND d.source_database_id IS NULL
    AND d.state NOT IN(1, 6, 10) /* Not currently offline or restoring, like log shipping databases */
    AND d.is_in_standby = 0 /* Not a log shipping target database */
    AND d.source_database_id IS NULL /* Excludes database snapshots */
    AND NOT EXISTS ( SELECT * FROM   msdb.dbo.backupset b
				    WHERE  d.name COLLATE SQL_Latin1_General_CP1_CI_AS = b.database_name COLLATE SQL_Latin1_General_CP1_CI_AS
				    AND b.type = 'L'
				    AND b.backup_finish_date >= DATEADD(dd,-2, sysdatetime()) ); 

insert into @Results(severity,Category,Issue,Details)
SELECT  
	   '(1) Critical' ,
	   'Database Performance' ,
	   'Auto Closed Enabled on a database',
	  ( 'Database [' + [name]
	   + '] has auto-close enabled.  This setting can dramatically decrease performance.' ) AS Details
FROM    sys.databases d
WHERE   is_auto_close_on = 1
union All

SELECT  
	   '(1) Critical',
	   'Database Performance' ,
	   'Auto-Shrink Enabled on a database' ,
	   ( 'Database [' + [name]
	   + '] has auto-shrink enabled.  This setting can dramatically decrease performance.' ) AS Details
FROM    sys.databases
WHERE   is_auto_shrink_on = 1

if (select value from sys.configurations c where c.name='optimize for ad hoc workloads') <> 1
BEGIN
    INSERT INTO @Results(severity,Category,Issue,Details)
    SELECT
	   '(2) High'
	   ,'Server Performance'
	   ,'Optimze for Ad Hoc Workload is not enabled'
	   ,'SQL Server typicall performas better when ' + CHAR(39) + 'Optimze for Ad Hoc Workloads' +  CHAR(39) +' is enabled'
END

if(SELECT COUNT(*)
							 FROM   tempdb.sys.database_files
							 WHERE  type_desc = 'ROWS') = 1
BEGIN
    INSERT INTO @Results(Severity,Category,Issue,Details)
    SELECT
	   '(2) High'
	   ,'Server Performance'
	   ,'TempDB has only 1 data file'
	   ,'SQL Server typically performs better when the TempDB has more than one Data file, perhaps up to the same # of data files as logical processors (' + cast(cpu_count as varchar(3)) + '), up to 8.'
	    FROM sys.dm_os_sys_info
END

IF ( SELECT COUNT (distinct [size])
							FROM   tempdb.sys.database_files
							WHERE  type_desc = 'ROWS'
							) <> 1
BEGIN
    INSERT INTO @Results(severity,Category,Issue,Details)
    SELECT
	   '(2) High'
	   ,'Server Performance'
	   ,'TempDB File Size'
	   ,'TempDB data files are not configured with the same size.'
END
---------------  MAX Memory Setting ------------------
DECLARE @MaxMemorySetting bigint
DECLARE @PhysicalMemory bigint
SELECT @PhysicalMemory = (SELECT m.total_physical_memory_kb/1024	  from sys.dm_os_sys_memory m)
SELECT @MaxMemorySetting=(SELECT CAST(value_in_use as BIGINT) FROM sys.configurations WHERE name = 'max server memory (MB)')

if @MaxMemorySetting=2147483647
insert into @Results(severity,Category,Issue,Details)
    select 
	   '(2) High'
	   ,'Server Performance'
	   ,'MAX Memory Setting is uncapped (default) and should be changed'
	   ,'Based on available physical memory of ' + cast(@PhysicalMemory as varchar(20))  + ' MB'
	   + ' this server should have a maximum setting of ' + cast(cast(@PhysicalMemory*.90 as decimal(6,0)) as varchar(10)) + ' MB'
-------------------- SQL Server Error Log ---------------------------------------------
DECLARE @LogError TABLE
(LogDate datetime2(0),ProcessInfo varchar(50),Details varchar(max), severity varchar(1000) null, Category varchar(1000) null)
INSERT INTO @LogError (LogDate, ProcessInfo, Details)
exec sp_readerrorlog 0,1,'Severity'

INSERT INTO @LogError (LogDate, ProcessInfo, Details)
exec sp_readerrorlog 0,1,'Error'

DELETE A
FROM @LogError A
where a.Details LIKE '%CHECKDB%'

DELETE A
FROM @LogError A
where a.Details like '%registry%'

DELETE A
FROM @LogError A
where a.Details LIKE '%Logging SQL Server messages in file%'

/*
select * from sys.messages m
inner join sys.syslanguages l on l.msglangid= m.language_id
and l.langid = @@LANGID
WHERE message_id = 18456
*/

UPDATE @LogError
SET Severity = CASE	WHEN  (ProcessInfo like '%Backup%' 
				or	Details like '%Backup%' 
				or	Details like '%18210%'
				or	Details like '%18204%'
				or	Details like '%3041%' )
				and LogDate >= dateadd(day, -7, getdate()) 
				THEN '(2) High' 
				WHEN  (ProcessInfo like '%Backup%' 
				or	Details like '%Backup%' 
				or	Details like '%18210%'
				or	Details like '%18204%'
				or	Details like '%3041%' )
				and LogDate < dateadd(day, -7, getdate()) 
				THEN '(3) Medium' 
				WHEN  ProcessInfo like '%Logon%' 
				or	Details like '%Severity: 20%'
				THEN '(4) Low' 
				WHEN  Details like '%Severity: 16%'
				THEN '(3) Medium' 
				ELSE '(2) High' 
				END
,	Category	=	CASE WHEN	(Details like '%Backup%' 
							or	Details like '%18210%'
							or	Details like '%18204%'
							or	Details like '%3041%')
							and LogDate >= dateadd(day, -7, getdate()) 
							THEN 'Recent Backup Failure'
						WHEN
						(Details like '%Backup%' 
							or	Details like '%18210%'
							or	Details like '%18204%'
							or	Details like '%3041%')
							and LogDate < dateadd(day, -7, getdate()) 
							THEN 'Past Backup Failure'
						 WHEN	Details like '%Logon%' or ProcessInfo = 'Logon' 
							THEN 'Logon Failure'
						 ELSE 'SQL Error Log'
					END
,	ProcessInfo	=	CASE WHEN ProcessInfo like 'spid%' THEN '' ELSE ProcessInfo END --filter out spids which will create dup entries
,	Details		=	Left(Details, CASE WHEN (CHARINDEX(':\', Details)) = 0 THEN 200 ELSE (CHARINDEX(':\', Details)) END)

INSERT INTO @Results(severity,Category,MostRecent,Issue,Details)
select  
    Severity	=	Severity
,	Category	=	Category
,	MostRecent	=	convert(varchar(30), MAX(LogDate))  
,	Issue		=	'Errors in the SQL Server Log'
,	Details		=	cast(count(Details) as varchar(10)) + ' errors of ' +  ProcessInfo  + Details + '... '
from @LogError r
GROUP BY Severity, Category, ProcessInfo, Details

-------------------- Page Life Expectancy -----------------------------------------
DECLARE @PLE int
SELECT @PLE = (
SELECT 
    cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Buffer Node%' -- Handles named instances
AND counter_name = N'Page life expectancy')

if @PLE < 300 
BEGIN
    INSERT INTO @Results(severity,Category,MostRecent,Issue,Details)
    SELECT
	   '(3) Medium'
	   ,'Server Performance'
	   , SYSDATETIME()
	   ,'Page Life Expectancy (PLE)'
	   ,'The current PLE is ' + cast(@PLE as varchar(10)) + ' which is below the "standard" of 300.  This could be an indication of low memory'
END
----------------------------------------------------------------------
if exists (select * from msdb.dbo.suspect_pages )

begin
    INSERT INTO @Results(severity,Category,Issue,Details)
    select
	   '(1) Critical'
	   ,'Database Performance'
	   ,'There appears to be a corrupted page in ' + db_name(sp.database_id)
	   ,'Please execute DBCC CHECKDB to determine the problem and possible result'
    FROM    msdb.dbo.suspect_pages sp
		  INNER JOIN master.sys.databases db ON sp.database_id = db.database_id
		  WHERE   sp.last_update_date >= DATEADD(dd, -30, sysdatetime()) 
end



-------
if (
SELECT 
    COUNT(*)
FROM   msdb.dbo.sysalerts
WHERE  severity >= 19 and severity <= 25) < 6 --OK if 20 is not in place
BEGIN
    INSERT INTO @Results(Severity,Category,Issue,Details)
    SELECT 
	   '(3) Medium'
	   ,'Monitoring'
	   ,'Some SQL Alerts are missing'
	   ,'Please review the SQL Agent Alerts. Some high severity errors are not sending alerts.'
END




if (select count(*) from @Results) > 0
    BEGIN
	   select * FROM @Results r ORDER BY severity asc, MostRecent asc, Issue asc, Details asc
    END
ELSE
    BEGIN
	   SELECT 'There are no critical findings with this SQL Server' as [Congratulations!]
    END
-----------------------------------------------
