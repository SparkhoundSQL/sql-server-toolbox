--Most resource intensive database 


Select DatabaseName = db_name(st.dbid) 
, TotalIO			= sum(qs.total_logical_reads + qs.total_logical_writes) 
, TotalCPU			= sum(qs.total_worker_time)
, TotalQueryDuration= sum(qs.total_elapsed_time)
, TotalReads		= sum(qs.total_logical_reads)
, TotalWrites		= sum(qs.total_logical_writes)
, OldestCachedPlan	= min(creation_time)
--select *
FROM sys.dm_exec_query_stats qs
Cross apply sys.dm_exec_sql_text (qs.plan_handle) st
where st.dbid <> 32767
Group by db_name (st.dbid)
Order by TotalIO desc