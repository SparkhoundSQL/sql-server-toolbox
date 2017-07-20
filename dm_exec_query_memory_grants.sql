
--memory grant waits in progress

select 
		mg.session_id
	,	mg.group_id
	,	mg.request_time
	,	mg.grant_time
	,	requested_memory_gb =	mg.requested_memory_kb/1024./1024.
	,	granted_memory_gb	=	mg.granted_memory_kb/1024./1024.
	,	mg.required_memory_kb
	,	used_memory_gb		=	mg.used_memory_kb/1024./1024.
	,	mg.max_used_memory_kb
	,	ideal_memory_gb		=	mg.ideal_memory_kb/1024./1024.
	,	mg.query_cost
	,	r.granted_query_memory
	,	r.status
	,	[db_name] = db_name(r.database_id)
	,	r.wait_time
	,	r.wait_type
	,	r.cpu_time
	,	r.total_elapsed_time
	,	r.reads
	,	r.writes
	,	r.logical_reads
	,	est.objectid
	,	est.text
	,	offsettext	=	CASE WHEN r.statement_start_offset = 0 and r.statement_end_offset= 0 THEN NULL
					ELSE
						SUBSTRING (est.[text], r.statement_start_offset/2 + 1, 
						  CASE WHEN r.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), est.[text])) 
							ELSE r.statement_end_offset/2 - r.statement_start_offset/2 + 1
						  END)
					END
from sys.dm_exec_query_memory_grants mg
inner join sys.dm_exec_requests r on mg.session_id = r.session_id
outer apply sys.dm_exec_sql_text (r.sql_handle) est
order by query_cost desc
GO