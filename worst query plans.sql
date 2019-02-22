--Worst query plans
--To find the worst queries and their plan(s), use Query Store (SQL 2016+)
--Table to capture this data at bottom

--INSERT INTO dbo.worstqueries
select top 15 
*
, Average_cpu		=	convert(decimal(19,2), tot_cpu_ms)/convert(decimal(19,2),usecounts)
, Average_Duration	=	convert(decimal(19,2),tot_duration_ms)/convert(decimal(19,2),usecounts)
, WorstQueriesObservedWhen		=	sysdatetime()
, DeleteQueryPlan	= 'DBCC FREEPROCCACHE('+convert(varchar(512),PlanHandle,1)+')'  --delete just this plan
 from 
(
	SELECT 
		  PlanStats.CpuRank, PlanStats.PhysicalReadsRank, PlanStats.DurationRank
		, dbname = db_name( convert(int, pa.value) )
		, cacheobjtype = LEFT (p.cacheobjtype + ' (' + p.objtype + ')', 35) 
	    , p.usecounts, p.size_in_bytes / 1024 AS size_in_kb,
		  PlanStats.total_worker_time/1000 AS tot_cpu_ms, PlanStats.total_elapsed_time/1000 AS tot_duration_ms, 
		  PlanStats.total_physical_reads, PlanStats.total_logical_writes, PlanStats.total_logical_reads,
		  PlanStats.last_execution_time
		, sql.objectid
		, Procedure_name = CONVERT (nvarchar(75), CASE 
											WHEN sql.objectid IS NULL THEN NULL 
											ELSE --Find the procedure name even in the comments block
												REPLACE (REPLACE (
												substring(sql.[text], charindex('CREATE',sql.[text],0),100)
												, CHAR(13), ' '), CHAR(10), ' ')
										  END)  
		, stmt_text = 	REPLACE (REPLACE (SUBSTRING (sql.[text], PlanStats.statement_start_offset/2 + 1, 
						  CASE WHEN PlanStats.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), sql.[text])) 
							ELSE PlanStats.statement_end_offset/2 - PlanStats.statement_start_offset/2 + 1
						  END), CHAR(13), ' '), CHAR(10), ' ') 
		, ReasonforEarlyTermination = CASE WHEN tqp.query_plan LIKE '%StatementOptmEarlyAbortReason%' THEN substring(substring(tqp.query_plan, charindex('EarlyAbortReason', tqp.query_plan,1)+18, 21), 1, ISNULL(ABS(charindex('"',substring(tqp.query_plan, charindex('EarlyAbortReason', tqp.query_plan,1)+18, 21),1)-1),0))
											ELSE NULL END 
		, QueryPlan		=	qp.query_plan	
		, PlanHandle	=	p.plan_handle
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

		 --and (PlanStats.CpuRank < 10 OR PlanStats.PhysicalReadsRank < 10 OR PlanStats.DurationRank < 10)
		  AND pa.attribute = 'dbid' 
		  --and usecounts > 1
		  --and (sql.text like '%SH_View_Utilization_Detail%' )
		  AND (CONVERT(nvarchar(max), sql.[text])) not like '%StatementOptmEarlyAbortReason%'
		  --AND (tqp.query_plan LIKE '%StatementOptmEarlyAbortReason="TimeOut%' or tqp.query_plan LIKE '%StatementOptmEarlyAbortReason="Memory Limit%')
) x
--where dbname = N'ram_tax'
ORDER BY CpuRank + PhysicalReadsRank + DurationRank asc


--select * from dbo.worstqueries

/*----------------
SQL 2000 only
SELECT 
UseCounts, RefCounts,CacheObjtype, ObjType, DB_NAME(dbid) as DatabaseName, SQL
FROM sys.syscacheobjects
where sql like '%mtblFeeEndorsement%'
ORDER BY dbid,usecounts DESC,objtype
GO
-----------------*/
/*
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE; --sql 2016+

DBCC FREEPROCCACHE


*/
/*
--table to capture this data

USE [tempdb]
GO
DROP TABLE IF EXISTS [dbo].[worstqueries]
CREATE TABLE [dbo].[worstqueries](
	[CpuRank] [bigint] NULL,
	[PhysicalReadsRank] [bigint] NULL,
	[DurationRank] [bigint] NULL,
	[cacheobjtype] [nvarchar](35) NULL,
	[usecounts] [int] NOT NULL,
	[size_in_kb] [int] NULL,
	[tot_cpu_ms] [bigint] NULL,
	[tot_duration_ms] [bigint] NULL,
	[total_physical_reads] [bigint] NOT NULL,
	[total_logical_writes] [bigint] NOT NULL,
	[total_logical_reads] [bigint] NOT NULL,
	[last_execution_time] [datetimeoffset] NULL,
	[dbname] [nvarchar](128) NULL,
	[objectid] [int] NULL,
	[procname] [nvarchar](75) NULL,
	[stmt_text] [nvarchar](max) NULL,
	[ReasonforEarlyTermination] varchar(50) NULL,
	[QueryPlan] [xml] NULL,
	[Average_cpu] [decimal](38, 19) NULL,
	[Average_Duration] [decimal](38, 19) NULL,
	[ObservedWhen] [datetimeoffset] NOT NULL CONSTRAINT DF_worstqueries_ObservedWhen DEFAULT (SYSDATETIMEOFFSET())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

*/

