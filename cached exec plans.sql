select 
	eqp.query_plan
,	o.name
,	DBName = DB_NAME(eps.database_id)
,	eps.TYPE_desc
,	cached_time
,	last_execution_time,	execution_count
,	total_worker_time,	last_worker_time,	min_worker_time,	max_worker_time
,	total_physical_reads,	last_physical_reads,	min_physical_reads,	max_physical_reads
,	total_logical_writes,	last_logical_writes,	min_logical_writes,	max_logical_writes
,	total_logical_reads,	last_logical_reads,	min_logical_reads,	max_logical_reads
,	total_elapsed_time,	last_elapsed_time,	min_elapsed_time,	max_elapsed_time
,	'DBCC FREEPROCCACHE('+convert(varchar(max),plan_handle,1)+')' as DeleteQueryPlan --delete just this plan
,	st.text
from sys.objects o
LEFT OUTER JOIN sys.dm_exec_procedure_stats eps on eps.object_id = o.object_id
CROSS APPLY sys.dm_exec_query_plan (eps.plan_handle) eqp 
CROSS APPLY sys.dm_exec_sql_text(plan_handle)  st
where 1=1
and eps.database_id = db_id()
and last_execution_time >= '2014-09-29'
and st.text like '%[dbo].[pt_time_time_entry]%'

--order by total_worker_time/execution_count desc
order by cached_time desc

