SELECT 
	'kill'
,	SPID	=	wt.session_id
,	wt.wait_type
,	er.wait_resource
,	wt.wait_duration_ms
,	st.text
,	s.host_name
,	s.program_name
,	[User] = COALESCE(NULLIF(s.login_name,''), s.nt_user_name, s.original_login_name)
,	s.status
,	er.start_time
,	er.group_id
,	s.login_name, s.nt_user_name, s.original_login_name
,	er.*, s.*
FROM 
	sys.dm_os_waiting_tasks wt 
INNER JOIN 
	sys.dm_exec_requests er
on wt.waiting_task_address = er.task_address 
INNER JOIN 
	sys.dm_exec_sessions s 
on er.session_id = s.session_id
OUTER APPLY
	sys.dm_exec_sql_text(er.sql_handle) st
where 
	wt.wait_type NOT LIKE '%SLEEP%' 
and wt.session_id >= 50
and wt.wait_type <> 'SQLTRACE_BUFFER_FLUSH' -- system trace, not a cause for concern
and wt.wait_type not in ('REQUEST_FOR_DEADLOCK_SEARCH', 'ONDEMAND_TASK_QUEUE','BROKER_TRANSMITTER','BROKER_EVENTHANDLER','LOGMGR_QUEUE','CHECKPOINT_QUEUE','BROKER_TO_FLUSH','DISPATCHER_QUEUE_SEMAPHORE') -- background task that handles requests, not a cause for concern
and wt.wait_type not in ('KSOURCE_WAKEUP','XE_DISPATCHER_WAIT','FT_IFTS_SCHEDULER_IDLE_WAIT','FT_IFTSHC_MUTEX','XE_TIMER_EVENT','FSAGENT','CLR_AUTO_EVENT') -- other waits that can be safely ignored
and (st.text is null or ltrim(st.text) not like 'SELECT%wt.wait_type%')
and wt.wait_type not in ('QDS_ASYNC_QUEUE','QDS_SHUTDOWN_QUEUE') --Query Store, can ignore
--and st.text like '%billing_report%'
ORDER BY wt.wait_duration_ms desc
go
