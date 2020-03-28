--Worst query plans in cache

--TODO Set @targetdb database if desired.
--TODO BEFORE running, go to settings in SSMS, Query Results, SQL Server, Results to Grid, set Maximum Characters Retrieved for XML to Unlimited. Then open this file in a new query window.

USE [tempdb]
GO
DECLARE @targetdb sysname = null --Set to NULL to return ALL databases. Change database name to target database if desired  
--Example, DECLARE @targetdb sysname = 'WideWorldImporters'

--To find the worst queries and their plan(s), strongly advised to use the superior Query Store feature in SQL 2016+
--Table to capture this data at bottom

IF OBJECT_ID('tempdb..#worstqueryplans') IS NOT NULL
    BEGIN
		print 'dropping temp table'
	   DROP TABLE [#worstqueryplans];
    END;


CREATE TABLE [dbo].[#worstqueryplans](
	[rownum] bigint NULL,
	[CpuRank] [bigint] NULL,
	[PhysicalReadsRank] [bigint] NULL,
	[DurationRank] [bigint] NULL,
	[dbname] [nvarchar](128) NULL,
	[cacheobjtype] [nvarchar](35) NULL,
	[usecounts] [int] NOT NULL,
	[size_in_kb] [int] NULL,
	[tot_cpu_ms] [bigint] NULL,
	[tot_duration_ms] [bigint] NULL,
	[total_physical_reads] [bigint] NOT NULL,
	[total_logical_writes] [bigint] NOT NULL,
	[total_logical_reads] [bigint] NOT NULL,
	[last_execution_time] [datetimeoffset](2) NULL,
	[objectid] [int] NULL,
	[Procedure_name] [nvarchar](75) NULL,
	[stmt_text] [nvarchar](max) NULL,
	[ReasonforEarlyTermination] varchar(50) NULL,
	[Average_cpu_ms] [decimal](19, 2) NULL,
	[Average_Duration_ms] [decimal](19, 2) NULL,
	[DeleteQueryPlan_SQL2016_above]	varchar(500) NULL,
	[DeleteQueryPlan_SQL2014_below]	varchar(500) NULL,	
	[PlanHandle] varbinary(64) NULL,
	[QueryPlan] [xml] NULL,
	[ObservedWhen] [datetimeoffset](2) NOT NULL 
	
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

INSERT INTO #worstqueryplans
SELECT TOP 15 
  rownum = row_number() OVER(ORDER BY CpuRank + PhysicalReadsRank + DurationRank asc)
, x.CpuRank
, x.PhysicalReadsRank
, x.DurationRank
, x.dbname
, x.cacheobjtype
, x.usecounts
, x.size_in_kb
, x.tot_cpu_ms
, x.tot_duration_ms
, x.total_physical_reads
, x.total_logical_writes
, x.total_logical_reads
, x.last_execution_time
, x.objectid
, x.[Procedure_name]
, x.stmt_text
, x.ReasonforEarlyTermination
, Average_cpu_ms						=	convert(decimal(19,2), tot_cpu_ms)/convert(decimal(19,2),usecounts)
, Average_Duration_ms					=	convert(decimal(19,2),tot_duration_ms)/convert(decimal(19,2),usecounts)
, DeleteQueryPlan_SQL2016_above		= 'ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE '+convert(varchar(512),PlanHandle,1) +';'--delete just this plan, works in Azure SQL or SQL 2016+
, DeleteQueryPlan_SQL2014_below		= 'DBCC FREEPROCCACHE ('+convert(varchar(512),PlanHandle,1) +');'--delete just this plan, older syntax
, x.PlanHandle
, x.QueryPlan
, [ObservedWhen] = SYSDATETIMEOFFSET()
FROM 
(
	SELECT 
		  PlanStats.CpuRank, PlanStats.PhysicalReadsRank, PlanStats.DurationRank --ranks, 1 = worst offender with highest number in this category
		, dbname = db_name(convert(int, pa.value))
		, cacheobjtype = LEFT(p.cacheobjtype + ' (' + p.objtype + ')', 35) 
	    , p.usecounts, p.size_in_bytes / 1024 AS size_in_kb,
		  PlanStats.total_worker_time/1000 AS tot_cpu_ms, PlanStats.total_elapsed_time/1000 AS tot_duration_ms, 
		  PlanStats.total_physical_reads, PlanStats.total_logical_writes, PlanStats.total_logical_reads,
		  PlanStats.last_execution_time
		, sql.objectid --if it's an object with the cached plan, look it up in the database name
		, [Procedure_name]	= CONVERT (nvarchar(75), CASE	WHEN sql.objectid IS NULL THEN NULL 
															ELSE --Find the procedure name even in the comments block
																	REPLACE (REPLACE (
																	substring(sql.[text], charindex('CREATE',sql.[text],0),100)
																	, CHAR(13), ' '), CHAR(10), ' ')
															END)
		, stmt_text			 = 	REPLACE (REPLACE (SUBSTRING (sql.[text], PlanStats.statement_start_offset/2 + 1, 
								  CASE WHEN PlanStats.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), sql.[text])) 
									ELSE PlanStats.statement_end_offset/2 - PlanStats.statement_start_offset/2 + 1
								  END), CHAR(13), ' '), CHAR(10), ' ') 
		, ReasonforEarlyTermination = CASE WHEN tqp.query_plan LIKE '%StatementOptmEarlyAbortReason%' 
											THEN substring(substring(tqp.query_plan, charindex('EarlyAbortReason', tqp.query_plan,1)+18, 21), 1, ISNULL(ABS(charindex('"',substring(tqp.query_plan, charindex('EarlyAbortReason', tqp.query_plan,1)+18, 21),1)-1),0))
											ELSE NULL END 
		, PlanHandle		=	p.plan_handle
		, QueryPlan			=	qp.query_plan
		FROM 
		(
		  SELECT 
			stat.plan_handle, statement_start_offset, statement_end_offset, 
			stat.total_worker_time, stat.total_elapsed_time, stat.total_physical_reads, 
			stat.total_logical_writes, stat.total_logical_reads, stat.last_execution_time, 
			ROW_NUMBER() OVER (ORDER BY stat.total_worker_time DESC) AS CpuRank, 
			ROW_NUMBER() OVER (ORDER BY stat.total_physical_reads DESC) AS PhysicalReadsRank, 
			ROW_NUMBER() OVER (ORDER BY stat.total_elapsed_time DESC) AS DurationRank 
		  FROM sys.dm_exec_query_stats stat 
		  where creation_time > '1/16/2014 7:00'
  
		) AS PlanStats 
		INNER JOIN sys.dm_exec_cached_plans p ON p.plan_handle = PlanStats.plan_handle 
		OUTER APPLY sys.dm_exec_plan_attributes (p.plan_handle) pa 
		OUTER APPLY sys.dm_exec_sql_text (p.plan_handle) AS sql
		inner join sys.databases d on d.database_id = pa.value
		OUTER APPLY sys.dm_exec_query_plan (p.plan_handle) qp
		OUTER APPLY sys.dm_exec_text_query_plan(p.plan_handle, 
                                                PlanStats.statement_start_offset, 
                                                PlanStats.statement_end_offset) AS tqp 
		WHERE 1=1
		  AND pa.attribute = 'dbid' 
		  and usecounts > 1 --ignore once-used plans in plan cache
		  AND (CONVERT(nvarchar(max), sql.[text])) not like '%StatementOptmEarlyAbortReason%'
		  --and (sql.text like '%SH_View_Utilization_Detail%' )
		  --AND (tqp.query_plan LIKE '%StatementOptmEarlyAbortReason="TimeOut%' or tqp.query_plan LIKE '%StatementOptmEarlyAbortReason="Memory Limit%')
) x
WHERE dbname = @targetdb or @targetdb is null
ORDER BY CpuRank + PhysicalReadsRank + DurationRank asc; 

select 
  rownum  
, CpuRank
, PhysicalReadsRank
, DurationRank
, dbname
, cacheobjtype
, usecounts
, size_in_kb
, tot_cpu_ms
, tot_duration_ms
, total_physical_reads
, total_logical_writes
, total_logical_reads
, last_execution_time
, objectid
, [Procedure_name]
, stmt_text
, ReasonforEarlyTermination
, Average_cpu_ms				
, Average_Duration_ms			
, DeleteQueryPlan_SQL2016_above	
, DeleteQueryPlan_SQL2014_below	
, PlanHandle
, [ObservedWhen]
from #worstqueryplans;

select rownum, [QueryPlan (Open and Save as .sqlplan files individually)] = QueryPlan from #worstqueryplans;

IF OBJECT_ID('tempdb..#worstqueryplans') IS NOT NULL
    BEGIN
		print 'dropping temp table'
	   DROP TABLE [#worstqueryplans];
    END;

/*----------------
--For SQL 2000 only
SELECT 
UseCounts, RefCounts,CacheObjtype, ObjType, DB_NAME(dbid) as DatabaseName, SQL
FROM syscacheobjects
ORDER BY dbid,usecounts DESC,objtype
GO
-----------------*/

/*
--table to capture this data

USE [tempdb]
GO
DROP TABLE IF EXISTS [dbo].[worstqueryplans]
CREATE TABLE [dbo].[worstqueryplans](
	[ObservedWhen] [datetimeoffset](2) NOT NULL CONSTRAINT DF_worstqueryplans_ObservedWhen DEFAULT (SYSDATETIMEOFFSET())
	[CpuRank] [bigint] NULL,
	[PhysicalReadsRank] [bigint] NULL,
	[DurationRank] [bigint] NULL,
	[dbname] [nvarchar](128) NULL,
	[cacheobjtype] [nvarchar](35) NULL,
	[usecounts] [int] NOT NULL,
	[size_in_kb] [int] NULL,
	[tot_cpu_ms] [bigint] NULL,
	[tot_duration_ms] [bigint] NULL,
	[total_physical_reads] [bigint] NOT NULL,
	[total_logical_writes] [bigint] NOT NULL,
	[total_logical_reads] [bigint] NOT NULL,
	[last_execution_time] [datetimeoffset] NULL,
	[objectid] [int] NULL,
	[procname] [nvarchar](75) NULL,
	[stmt_text] [nvarchar](max) NULL,
	[ReasonforEarlyTermination] varchar(50) NULL,
	[Average_cpu_ms] [decimal](38, 19) NULL,
	[Average_Duration_ms] [decimal](38, 19) NULL,
	[DeleteQueryPlan_SQL2016_above]	varchar(500) NULL,
	[DeleteQueryPlan_SQL2014_below]	varchar(500) NULL,	
	[PlanHandle] varbinary(64) NULL
	[QueryPlan] [xml] NULL,

) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
*/

