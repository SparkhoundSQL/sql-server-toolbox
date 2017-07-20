CREATE procedure dbo.CaptureLongRunningQueries  as
begin

	If	Exists (	select 1 from sys.dm_exec_requests where blocking_session_id > 0)
					or
		Exists (	select 1 from sys.dm_exec_requests where total_elapsed_time > 10000 and session_id >= 50 ) --10s
	BEGIN

		create table #ExecRequests  (
			id int IDENTITY(1,1) PRIMARY KEY
		,	session_id	smallint not null 
		,	request_id	int null
		,	request_start_time	datetime null
		,	login_time datetime not null
		,	login_name nvarchar(256) null
		,	client_interface_name nvarchar(64)
		,	session_status	nvarchar(60) null
		,	request_status	nvarchar(60) null
		,	command	nvarchar(32) null
		,	sql_handle	varbinary(64) null
		,	statement_start_offset	int null
		,	statement_end_offset	int null
		,	plan_handle	varbinary (64) null
		,	database_id	smallint null
		,	user_id	int null
		,	blocking_session_id	smallint null
		,	wait_type	nvarchar (120) null
		,	wait_time_s	int null
		,	wait_resource nvarchar(120) null
		,	last_wait_type nvarchar(120) null
		,	cpu_time_s	int null
		,	tot_time_s	int null
		,	reads	bigint null
		,	writes	bigint null
		,	logical_reads	bigint null
		,	[host_name] nvarchar(256) null
		,	[program_name] nvarchar(256) null
		,	blocking_these varchar(1000) NULL
		,	percent_complete int null
		,	session_transaction_isolation_level varchar(20) null
		,	request_transaction_isolation_level varchar(20) null
		)

		insert into #ExecRequests (session_id,request_id, request_start_time, login_time, login_name, client_interface_name, session_status, request_status, command,sql_handle,statement_start_offset,statement_end_offset,plan_handle,database_id,user_id,blocking_session_id,wait_type,last_wait_type,wait_time_s,wait_resource,cpu_time_s,tot_time_s,reads,writes,logical_reads,[host_name], [program_name] ,	session_transaction_isolation_level ,	request_transaction_isolation_level )
						  select s.session_id,request_id, r.start_time, s.login_time, s.login_name, s.client_interface_name, s.status, r.status,command,sql_handle,statement_start_offset,statement_end_offset,plan_handle,r.database_id,user_id,blocking_session_id,wait_type,r.last_wait_type, r.wait_time/1000.,r.wait_resource ,r.cpu_time/1000.,r.total_elapsed_time/1000.,r.reads,r.writes,r.logical_reads,s.[host_name], s.[program_name], s.transaction_isolation_level, r.transaction_isolation_level
		from sys.dm_exec_sessions s 
		left outer join sys.dm_exec_requests r on r.session_id = s.session_id
		where 1=1
		and s.session_id >= 50 --retrieve only user spids
		and s.session_id <> @@SPID --ignore myself
	
		update #ExecRequests 
		set blocking_these = LEFT((select isnull(convert(varchar(5), er.session_id),'') + ', ' 
								from #ExecRequests er
								where er.blocking_session_id = isnull(#ExecRequests.session_id ,0)
								and er.blocking_session_id <> 0
								FOR XML PATH('') 
								),1000)
	

	
		INSERT INTO DBALogging.dbo.SessionsAndRequestsLog
		select * 
		from 
		(
			select		
				timestamp =	getdate()
			, r.session_id	, r.host_name	, r.program_name
			, r.session_status
			, r.request_status
			, r.blocking_these
			, blocked_by	=		r.blocking_session_id
			, r.wait_type	
			, r.wait_resource
			, r.last_wait_type
			, DBName = db_name(r.database_id)
			, r.command
			, login_time
			, login_name
			, client_interface_name
			, request_start_time
			, r.tot_time_s, r.wait_time_s, r.cpu_time_s, r.reads, r.writes, r.logical_reads
			--, [fulltext]	=	est.[text]
			, offsettext	=	CASE	WHEN r.statement_start_offset = 0 and r.statement_end_offset= 0 THEN NULL
										ELSE	SUBSTRING (		est.[text]
														,	r.statement_start_offset/2 + 1, 
															CASE WHEN r.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), est.[text])) 
																ELSE r.statement_end_offset/2 - r.statement_start_offset/2 + 1
															END	)
								END
			, r.statement_start_offset, r.statement_end_offset
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
			, stat.execution_count, stat.total_worker_time, stat.last_worker_time, stat.total_elapsed_time, stat.last_elapsed_time, stat.total_physical_reads, stat.total_logical_writes, stat.total_logical_reads, stat.total_rows, stat.last_rows
			from #ExecRequests r
			LEFT OUTER JOIN sys.dm_exec_cached_plans p ON p.plan_handle = r.plan_handle 
			OUTER APPLY sys.dm_exec_query_plan (r.plan_handle) qp
			OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) est
			LEFT OUTER JOIN sys.dm_exec_query_stats stat on stat.plan_handle = r.plan_handle or stat.sql_handle = r.sql_handle
			WHERE 
				(	r.blocking_these is not null 
				or	r.blocking_session_id is not null 
				or	r.request_status is not null 
				)

		) a
	
		order by session_id asc

		drop table #ExecRequests  

	END
end
go
--drop table DBALogging.dbo.SessionsAndRequestsLog
exec CaptureLongRunningQueries  
select * from DBALogging.dbo.SessionsAndRequestsLog order by timestamp desc