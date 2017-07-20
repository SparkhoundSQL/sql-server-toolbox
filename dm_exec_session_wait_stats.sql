select * from sys.dm_exec_session_wait_stats wt
where  session_id = 69
	--wt.wait_type NOT LIKE '%SLEEP%' 
--and wt.session_id >= 50
--and wt.wait_type <> 'SQLTRACE_BUFFER_FLUSH' -- system trace, not a cause for concern
--and wt.wait_type not in ('REQUEST_FOR_DEADLOCK_SEARCH','HADR_FILESTREAM_IOMGR_IOCOMPLETION','QDS_SHUTDOWN_QUEUE''ONDEMAND_TASK_QUEUE','BROKER_TRANSMITTER','BROKER_EVENTHANDLER','LOGMGR_QUEUE','CHECKPOINT_QUEUE','BROKER_TO_FLUSH','DISPATCHER_QUEUE_SEMAPHORE') -- background task that handles requests, not a cause for concern
--and wt.wait_type not in ('CLR_AUTO_EVENT','CLR_MANUAL_EVENT','DIRTY_PAGE_POLL','CLR_SEMAPHORE','BROKER_TASK_STOP''KSOURCE_WAKEUP','XE_DISPATCHER_WAIT','FT_IFTS_SCHEDULER_IDLE_WAIT','FT_IFTSHC_MUTEX','XE_TIMER_EVENT') -- other waits that can be safely ignored

order by session_id, wait_time_ms desc