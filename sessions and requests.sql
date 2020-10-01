--!!! Note: Different version of this query for Azure SQL DB !!!
-- See also toolbox\blocked processes report xevents.sql to capture blocking chains using the blocked process report.
--	print 'start ' + cast(sysdatetime() as varchar(20))
	declare @showallspids bit, @showinternalgroup bit 
	select	@showallspids = 1-- 1= show all sessions, 0= show only active requests
		,	@showinternalgroup = 1 -- 1= show internal sessions, 0= ignore internal sessions based on RG group_id
	;								-- The @showinternalgroup flag does NOT work for Standard edition because all queries show in the same Resource Group

	WITH cteSR AS (
	SELECT s.session_id, r.request_id, request_start_time= r.start_time, s.login_time, s.login_name, s.client_interface_name, session_status = s.status, request_status= r.status,command,sql_handle,statement_start_offset,statement_end_offset,plan_handle,r.database_id,user_id,blocking_session_id,wait_type,r.last_wait_type, wait_time_s = r.wait_time/1000.,r.wait_resource ,cpu_time_s = r.cpu_time/1000.,tot_time_s = r.total_elapsed_time/1000.,r.reads,r.writes,r.logical_reads,percent_complete,estimated_completion_time	,s.[host_name], s.[program_name], session_transaction_isolation_level= s.transaction_isolation_level, request_transaction_isolation_level = r.transaction_isolation_level, Governor_Group_Id = s.group_id
	, EndPointName= E.name, Protocol = E.protocol_desc	  -- this line sql2k16+ and patches of 14 and 12 only
	FROM sys.dm_exec_sessions s 
	LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
	LEFT OUTER JOIN sys.endpoints E ON E.endpoint_id = s.endpoint_id  -- this line sql2k16+ and patches of 14 and 12 only
	WHERE 1=1
	and s.session_id >= 50 --retrieve only user spids
	--and s.session_id <> @@SPID --ignore myself
	and	(@showallspids = 1 or r.session_id is not null) 
	and	(@showinternalgroup = 1 or s.group_id > 1)
	),
	cteBL (session_id, blocking_these) AS 
	(		select sr.session_id, blocking_these = x.blocking_these 
			from cteSR as sr cross apply
				(select isnull(convert(varchar(5), er.session_id),'') + ', '  
										from cteSR as er
										where er.blocking_session_id = isnull(sr.session_id ,0)
										and er.blocking_session_id <> 0
										FOR XML PATH('') ) x (blocking_these)
	)
	--Optional Insert statement for retaining this data. See toolbox\sessions and requests table.sql for destination.
	--INSERT INTO dbalogging.dbo.[SessionsAndRequestsLog] 
	SELECT * 
		FROM (
		SELECT		
		  timestamp =	sysdatetimeoffset()
		, r.session_id	, r.host_name	, r.program_name
		, r.session_status
		, r.request_status
		, r.request_id
		, bl.blocking_these
		, blocked_by	=		r.blocking_session_id
		, r.wait_type	
		, r.wait_resource
		, r.last_wait_type
		, DBName = db_name(r.database_id)
		, est.objectid
		, r.command
		, login_time
		, login_name
		, client_interface_name
		, request_start_time
		, r.tot_time_s, r.wait_time_s
		, r.cpu_time_s --cpu_time is not accurate prior to SQL Server 2012 SP2.  http://blogs.msdn.com/b/psssql/archive/2014/11/11/how-come-sys-dm-exec-requests-cpu-time-never-moves.aspx
		, r.reads, r.writes, r.logical_reads
		--, [fulltext]	=	est.[text]
		, r.percent_complete --only available for certain operations
		, estimated_remaining_time_HHMMSS = 
				CASE WHEN r.estimated_completion_time < 36000000 THEN '0' ELSE '' END
				+ RTRIM(r.estimated_completion_time/1000/3600)
				+ ':' + RIGHT('0' + RTRIM((r.estimated_completion_time/1000)%3600/60), 2)
				+ ':' + RIGHT('0' + RTRIM((r.estimated_completion_time/1000)%60), 2)

		, offsettext	=	CASE	WHEN r.statement_start_offset = 0 and r.statement_end_offset= 0 THEN left(est.text, 4000)
									ELSE	SUBSTRING (		est.[text]
													,	r.statement_start_offset/2 + 1, 
														CASE WHEN r.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), est.[text])) 
															ELSE r.statement_end_offset/2 - r.statement_start_offset/2 + 1
														END	)
							END
		, Input_Buffer_Text_Event_Info	= ib.event_info --SQL 2014 SP2+ only
		, Input_Buffer_Event_Type		= ib.event_type --SQL 2014 SP2+ only
		--, r.statement_start_offset, r.statement_end_offset
		, cacheobjtype	=	LEFT (p.cacheobjtype + ' (' + p.objtype + ')', 35)
		, QueryPlan		=	qp.query_plan	
		, request_transaction_isolation_level	=	case request_transaction_isolation_level 
				when 0 then 'Unspecified'
				when 1 then 'ReadUncommitted'
				when 2 then 'ReadCommitted'
				when 3 then 'Repeatable'
				when 4 then 'Serializable'
				when 5 then 'Snapshot' end 
		, session_transaction_isolation_level	=	case session_transaction_isolation_level 
				when 0 then 'Unspecified'
				when 1 then 'ReadUncommitted'
				when 2 then 'ReadCommitted'
				when 3 then 'Repeatable'
				when 4 then 'Serializable'
				when 5 then 'Snapshot' end 
		, p.plan_handle
		, plan_execution_count		= stat.execution_count
		, plan_total_worker_time_s	= stat.total_worker_time/1000./1000.
		, plan_last_worker_time_s	= stat.last_worker_time/1000./1000.
		, plan_total_elapsed_time_s = stat.total_elapsed_time/1000./1000.
		, plan_last_elapsed_time_s	= stat.last_elapsed_time/1000./1000.
		, plan_total_physical_reads = stat.total_physical_reads
		, plan_total_logical_writes = stat.total_logical_writes
		, plan_total_logical_reads	= stat.total_logical_reads
		, Governor_Group_Name	=	wg.name
		, Governor_Group_ID		=	r.Governor_Group_Id
		, Governor_Pool_Name	=	wp.name 
		, Governor_Pool_ID		=	wg.pool_id
		, EndPointName
		, Protocol
		, tempdb.Outstanding_TempDB_Session_Internal_Alloc_pages 
		, tempdb.Outstanding_TempDB_Session_User_Alloc_pages 
		, tempdb.Outstanding_TempDB_Task_Internal_Alloc_pages 
		, tempdb.Outstanding_TempDB_Task_User_Alloc_pages 
		, stat.total_rows --SQL 2012 only
		, stat.last_rows --SQL 2012 only
		from cteSR as r
		INNER JOIN cteBL as bl on r.session_id = bl.session_id
		LEFT OUTER JOIN sys.dm_exec_cached_plans p ON p.plan_handle = r.plan_handle 
		OUTER APPLY sys.dm_exec_query_plan (r.plan_handle) qp
		OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) est
		LEFT OUTER JOIN sys.dm_exec_query_stats stat on stat.plan_handle = r.plan_handle
													and r.statement_start_offset = stat.statement_start_offset  
													and r.statement_end_offset = stat.statement_end_offset
		LEFT OUTER JOIN sys.resource_governor_workload_groups  wg on wg.group_id = r.Governor_Group_Id
		LEFT OUTER JOIN sys.resource_governor_resource_pools wp on wp.pool_id = wg.pool_id
		LEFT OUTER JOIN (SELECT SU.session_id
							, Outstanding_TempDB_Session_Internal_Alloc_pages = sum (SU.internal_objects_alloc_page_count) - sum (SU.internal_objects_dealloc_page_count)
							, Outstanding_TempDB_Session_User_Alloc_pages = sum (SU.user_objects_alloc_page_count)	 - sum (SU.user_objects_dealloc_page_count)
							, Outstanding_TempDB_Task_Internal_Alloc_pages = sum (TS.internal_objects_alloc_page_count) - sum (TS.internal_objects_dealloc_page_count)
							, Outstanding_TempDB_Task_User_Alloc_pages = sum (TS.user_objects_alloc_page_count) - sum (TS.user_objects_dealloc_page_count)
							FROM tempdb.sys.dm_db_session_space_usage SU
							inner join tempdb.sys.dm_db_task_space_usage TS
							on SU.session_id = TS.session_id
							where SU.session_id > 50    
							GROUP BY SU.session_id) as tempdb
		on tempdb.session_id = r.session_id	 
		CROSS APPLY sys.dm_exec_input_buffer(r.session_id, r.request_id) AS ib   --this line SQL 2014 SP2+ only
	) a
	ORDER BY len(blocking_these) - len(replace(blocking_these,',','')) desc, blocking_these desc, blocked_by desc, session_id;

	--PRINT 'done ' + cast(sysdatetime() as varchar(20))
	go
	