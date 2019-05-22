--Aggregate waits stats since last server startup
--See FROM switch for Azure SQL DB (defaulted to SQL Server)

SELECT 
	wait_type
,	wait_time_s				=	wait_time_ms / 1000 
,	Pct						=	100 * wait_time_ms/sum(wait_time_ms) OVER()
FROM 
	(SELECT *, pcttile = NTILE(20) OVER (ORDER BY wait_time_ms desc) 
	FROM 
		sys.dm_os_wait_stats --for SQL Server, returns a lot of noise for Azure SQL DB
	--	sys.dm_db_wait_stats --for Azure SQL DB
	)	 AS wt
WHERE	wt.pcttile = 1 --display only the top 5% of waits)
AND		wt.[wait_type] NOT IN (
		-- updated list from: https://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts/
		-- These wait types are almost 100% never a problem and so they are
        -- filtered out to avoid them skewing the results. Click on the URL
        -- for more information.
        N'BROKER_EVENTHANDLER', -- https://www.sqlskills.com/help/waits/BROKER_EVENTHANDLER
        N'BROKER_RECEIVE_WAITFOR', -- https://www.sqlskills.com/help/waits/BROKER_RECEIVE_WAITFOR
        N'BROKER_TASK_STOP', -- https://www.sqlskills.com/help/waits/BROKER_TASK_STOP
        N'BROKER_TO_FLUSH', -- https://www.sqlskills.com/help/waits/BROKER_TO_FLUSH
        N'BROKER_TRANSMITTER', -- https://www.sqlskills.com/help/waits/BROKER_TRANSMITTER
        N'CHECKPOINT_QUEUE', -- https://www.sqlskills.com/help/waits/CHECKPOINT_QUEUE
        N'CHKPT', -- https://www.sqlskills.com/help/waits/CHKPT
        N'CLR_AUTO_EVENT', -- https://www.sqlskills.com/help/waits/CLR_AUTO_EVENT
        N'CLR_MANUAL_EVENT', -- https://www.sqlskills.com/help/waits/CLR_MANUAL_EVENT
        N'CLR_SEMAPHORE', -- https://www.sqlskills.com/help/waits/CLR_SEMAPHORE
        N'CXCONSUMER', -- https://www.sqlskills.com/help/waits/CXCONSUMER
 
        -- Maybe comment these four out if you have mirroring issues
        N'DBMIRROR_DBM_EVENT', -- https://www.sqlskills.com/help/waits/DBMIRROR_DBM_EVENT
        N'DBMIRROR_EVENTS_QUEUE', -- https://www.sqlskills.com/help/waits/DBMIRROR_EVENTS_QUEUE
        N'DBMIRROR_WORKER_QUEUE', -- https://www.sqlskills.com/help/waits/DBMIRROR_WORKER_QUEUE
        N'DBMIRRORING_CMD', -- https://www.sqlskills.com/help/waits/DBMIRRORING_CMD
 
        N'DIRTY_PAGE_POLL', -- https://www.sqlskills.com/help/waits/DIRTY_PAGE_POLL
        N'DISPATCHER_QUEUE_SEMAPHORE', -- https://www.sqlskills.com/help/waits/DISPATCHER_QUEUE_SEMAPHORE
        N'EXECSYNC', -- https://www.sqlskills.com/help/waits/EXECSYNC
        N'FSAGENT', -- https://www.sqlskills.com/help/waits/FSAGENT
        N'FT_IFTS_SCHEDULER_IDLE_WAIT', -- https://www.sqlskills.com/help/waits/FT_IFTS_SCHEDULER_IDLE_WAIT
        N'FT_IFTSHC_MUTEX', -- https://www.sqlskills.com/help/waits/FT_IFTSHC_MUTEX
 
        -- Maybe comment these six out if you have AG issues
        N'HADR_CLUSAPI_CALL', -- https://www.sqlskills.com/help/waits/HADR_CLUSAPI_CALL
        N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', -- https://www.sqlskills.com/help/waits/HADR_FILESTREAM_IOMGR_IOCOMPLETION
        N'HADR_LOGCAPTURE_WAIT', -- https://www.sqlskills.com/help/waits/HADR_LOGCAPTURE_WAIT
        N'HADR_NOTIFICATION_DEQUEUE', -- https://www.sqlskills.com/help/waits/HADR_NOTIFICATION_DEQUEUE
        N'HADR_TIMER_TASK', -- https://www.sqlskills.com/help/waits/HADR_TIMER_TASK
        N'HADR_WORK_QUEUE', -- https://www.sqlskills.com/help/waits/HADR_WORK_QUEUE
 
        N'KSOURCE_WAKEUP', -- https://www.sqlskills.com/help/waits/KSOURCE_WAKEUP
        N'LAZYWRITER_SLEEP', -- https://www.sqlskills.com/help/waits/LAZYWRITER_SLEEP
        N'LOGMGR_QUEUE', -- https://www.sqlskills.com/help/waits/LOGMGR_QUEUE
        N'MEMORY_ALLOCATION_EXT', -- https://www.sqlskills.com/help/waits/MEMORY_ALLOCATION_EXT
        N'ONDEMAND_TASK_QUEUE', -- https://www.sqlskills.com/help/waits/ONDEMAND_TASK_QUEUE
        N'PARALLEL_REDO_DRAIN_WORKER', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_DRAIN_WORKER
        N'PARALLEL_REDO_LOG_CACHE', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_LOG_CACHE
        N'PARALLEL_REDO_TRAN_LIST', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_TRAN_LIST
        N'PARALLEL_REDO_WORKER_SYNC', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_WORKER_SYNC
        N'PARALLEL_REDO_WORKER_WAIT_WORK', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_WORKER_WAIT_WORK
        N'PREEMPTIVE_OS_FLUSHFILEBUFFERS', -- https://www.sqlskills.com/help/waits/PREEMPTIVE_OS_FLUSHFILEBUFFERS 
        N'PREEMPTIVE_XE_GETTARGETSTATE', -- https://www.sqlskills.com/help/waits/PREEMPTIVE_XE_GETTARGETSTATE
        N'PWAIT_ALL_COMPONENTS_INITIALIZED', -- https://www.sqlskills.com/help/waits/PWAIT_ALL_COMPONENTS_INITIALIZED
        N'PWAIT_DIRECTLOGCONSUMER_GETNEXT', -- https://www.sqlskills.com/help/waits/PWAIT_DIRECTLOGCONSUMER_GETNEXT
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', -- https://www.sqlskills.com/help/waits/QDS_PERSIST_TASK_MAIN_LOOP_SLEEP
        N'QDS_ASYNC_QUEUE', -- https://www.sqlskills.com/help/waits/QDS_ASYNC_QUEUE
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', -- https://www.sqlskills.com/help/waits/QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP
        N'QDS_SHUTDOWN_QUEUE', -- https://www.sqlskills.com/help/waits/QDS_SHUTDOWN_QUEUE
        N'REDO_THREAD_PENDING_WORK', -- https://www.sqlskills.com/help/waits/REDO_THREAD_PENDING_WORK
        N'REQUEST_FOR_DEADLOCK_SEARCH', -- https://www.sqlskills.com/help/waits/REQUEST_FOR_DEADLOCK_SEARCH
        N'RESOURCE_QUEUE', -- https://www.sqlskills.com/help/waits/RESOURCE_QUEUE
        N'SERVER_IDLE_CHECK', -- https://www.sqlskills.com/help/waits/SERVER_IDLE_CHECK
        N'SLEEP_BPOOL_FLUSH', -- https://www.sqlskills.com/help/waits/SLEEP_BPOOL_FLUSH
        N'SLEEP_DBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_DBSTARTUP
        N'SLEEP_DCOMSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_DCOMSTARTUP
        N'SLEEP_MASTERDBREADY', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERDBREADY
        N'SLEEP_MASTERMDREADY', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERMDREADY
        N'SLEEP_MASTERUPGRADED', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERUPGRADED
        N'SLEEP_MSDBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_MSDBSTARTUP
        N'SLEEP_SYSTEMTASK', -- https://www.sqlskills.com/help/waits/SLEEP_SYSTEMTASK
        N'SLEEP_TASK', -- https://www.sqlskills.com/help/waits/SLEEP_TASK
        N'SLEEP_TEMPDBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_TEMPDBSTARTUP
        N'SNI_HTTP_ACCEPT', -- https://www.sqlskills.com/help/waits/SNI_HTTP_ACCEPT
        N'SOS_WORK_DISPATCHER', -- https://www.sqlskills.com/help/waits/SOS_WORK_DISPATCHER
        N'SP_SERVER_DIAGNOSTICS_SLEEP', -- https://www.sqlskills.com/help/waits/SP_SERVER_DIAGNOSTICS_SLEEP
        N'SQLTRACE_BUFFER_FLUSH', -- https://www.sqlskills.com/help/waits/SQLTRACE_BUFFER_FLUSH
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', -- https://www.sqlskills.com/help/waits/SQLTRACE_INCREMENTAL_FLUSH_SLEEP
        N'SQLTRACE_WAIT_ENTRIES', -- https://www.sqlskills.com/help/waits/SQLTRACE_WAIT_ENTRIES
        N'VDI_CLIENT_OTHER', -- https://www.sqlskills.com/help/waits/VDI_CLIENT_OTHER
        N'WAIT_FOR_RESULTS', -- https://www.sqlskills.com/help/waits/WAIT_FOR_RESULTS
        N'WAITFOR', -- https://www.sqlskills.com/help/waits/WAITFOR
        N'WAITFOR_TASKSHUTDOWN', -- https://www.sqlskills.com/help/waits/WAITFOR_TASKSHUTDOWN
        N'WAIT_XTP_RECOVERY', -- https://www.sqlskills.com/help/waits/WAIT_XTP_RECOVERY
        N'WAIT_XTP_HOST_WAIT', -- https://www.sqlskills.com/help/waits/WAIT_XTP_HOST_WAIT
        N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', -- https://www.sqlskills.com/help/waits/WAIT_XTP_OFFLINE_CKPT_NEW_LOG
        N'WAIT_XTP_CKPT_CLOSE', -- https://www.sqlskills.com/help/waits/WAIT_XTP_CKPT_CLOSE
        N'XE_DISPATCHER_JOIN', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_JOIN
        N'XE_DISPATCHER_WAIT', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_WAIT
        N'XE_TIMER_EVENT' -- https://www.sqlskills.com/help/waits/XE_TIMER_EVENT
        )
ORDER BY Pct DESC;


SELECT servicename, status_desc, last_startup_time FROM sys.dm_server_services;
GO


/*

--Script to setup capturing these statistics over time
--Assumes a DBAAdmin database has been created

drop table dbaadmin.dbo.sys_dm_os_wait_stats 

create table dbaadmin.dbo.sys_dm_os_wait_stats 
(	id int not null IDENTITY(1,1) 
,	datecapture datetimeoffset(2) not null
,	wait_Type nvarchar(512) not null
,	wait_time_s  decimal(19,1) not null 
,	Pct decimal(9,1)  not null
,	CONSTRAINT PK_sys_dm_os_wait_stats PRIMARY KEY CLUSTERED (id)
)

insert into dbaadmin.dbo.sys_dm_os_wait_stats  (datecapture, wait_type,	wait_time_s, Pct)
select top 100
	datecapture =	SYSDATETIMEOFFSET()
,	wait_type
,	wait_time_s =	convert(decimal(19,1), round( wait_time_ms / 1000.0,1))
,	Pct			=	wait_time_ms/sum(wait_time_ms) OVER() 
from sys.dm_os_wait_stats wt
Where round(wait_time_ms,0) > 0.0
order by wait_time_s
GO
DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR);
go

*/
/*
--trend wait types over time, each sample
select
	wait_type
,	datecapture
,	wait_time_s 
,	Pct			=	100. * wait_time_s / sum(wait_time_s) OVER (partition by datecapture)
from  dbaadmin.dbo.sys_dm_os_wait_stats wt
where wt.wait_type NOT LIKE '%SLEEP%' 
and wt.wait_type <> 'REQUEST_FOR_DEADLOCK_SEARCH'
and wt.wait_type not in ('CLR_AUTO_EVENT','CLR_MANUAL_EVENT','DIRTY_PAGE_POLL')
and wt.wait_type not in ('HADR_FILESTREAM_IOMGR_IOCOMPLETION')
and wt.wait_type <> 'SQLTRACE_BUFFER_FLUSH' -- system trace, not a cause for concern
and wt.wait_type not in ('ONDEMAND_TASK_QUEUE','BROKER_TRANSMITTER','BROKER_EVENTHANDLER','LOGMGR_QUEUE','CHECKPOINT_QUEUE','BROKER_TO_FLUSH','DISPATCHER_QUEUE_SEMAPHORE') -- background task that handles requests, not a cause for concern
and wt.wait_type not in ('KSOURCE_WAKEUP','XE_DISPATCHER_WAIT','FT_IFTS_SCHEDULER_IDLE_WAIT','FT_IFTSHC_MUTEX','XE_TIMER_EVENT') -- other waits that can be safely ignored
group by wait_Type, wait_time_s, datecapture
order by wait_type asc, datecapture asc

--trend wait types by day
select distinct
	wait_type
,	day = convert(date,datecapture)
,	wait_time_s =	sum(wait_time_s) OVER (partition by wait_Type, convert(date, datecapture))
,	Pct			=	convert(decimal(9,2), round(100.00 * sum(wait_time_s) OVER (partition by wait_Type, convert(date, datecapture))
				/ sum(wait_time_s) OVER (partition by convert(date, datecapture)), 2))
from  dbaadmin.dbo.sys_dm_os_wait_stats wt
where wt.wait_type NOT LIKE '%SLEEP%' 
and wt.wait_type <> 'REQUEST_FOR_DEADLOCK_SEARCH'
and wt.wait_type not in ('CLR_AUTO_EVENT','CLR_MANUAL_EVENT','DIRTY_PAGE_POLL')
and wt.wait_type not in ('HADR_FILESTREAM_IOMGR_IOCOMPLETION')
and wt.wait_type <> 'SQLTRACE_BUFFER_FLUSH' -- system trace, not a cause for concern
and wt.wait_type not in ('ONDEMAND_TASK_QUEUE','BROKER_TRANSMITTER','BROKER_EVENTHANDLER','LOGMGR_QUEUE','CHECKPOINT_QUEUE','BROKER_TO_FLUSH','DISPATCHER_QUEUE_SEMAPHORE') -- background task that handles requests, not a cause for concern
and wt.wait_type not in ('KSOURCE_WAKEUP','XE_DISPATCHER_WAIT','FT_IFTS_SCHEDULER_IDLE_WAIT','FT_IFTSHC_MUTEX','XE_TIMER_EVENT') -- other waits that can be safely ignored
and datecapture >= convert(date, dateadd(d, -7, getdate()))
group by wait_Type, wait_time_s, datecapture 
order by wait_type asc, day asc

--trend wait types month over month
select distinct
	wait_type
,	YYYYMM = convert(char(4),datepart(yyyy,datecapture))+'-'+right('0'+(convert(varchar(2),datepart(m, datecapture))),2)
,	wait_time_s =	sum(wait_time_s) OVER (partition by wait_Type, convert(char(4),datepart(yyyy,datecapture))+'-'+right('0'+(convert(varchar(2),datepart(m, datecapture))),2))
,	Pct			=	100. * sum(wait_time_s) OVER (partition by wait_Type, convert(char(4),datepart(yyyy,datecapture))+'-'+right('0'+(convert(varchar(2),datepart(m, datecapture))),2))
				/ sum(wait_time_s) OVER (partition by convert(char(4),datepart(yyyy,datecapture))+'-'+right('0'+(convert(varchar(2),datepart(m, datecapture))),2))
from  dbaadmin.dbo.sys_dm_os_wait_stats wt
where wt.wait_type NOT LIKE '%SLEEP%' 
and wt.wait_type <> 'REQUEST_FOR_DEADLOCK_SEARCH'
and wt.wait_type not in ('CLR_AUTO_EVENT','CLR_MANUAL_EVENT','DIRTY_PAGE_POLL')
and wt.wait_type not in ('HADR_FILESTREAM_IOMGR_IOCOMPLETION')
and wt.wait_type <> 'SQLTRACE_BUFFER_FLUSH' -- system trace, not a cause for concern
and wt.wait_type not in ('ONDEMAND_TASK_QUEUE','BROKER_TRANSMITTER','BROKER_EVENTHANDLER','LOGMGR_QUEUE','CHECKPOINT_QUEUE','BROKER_TO_FLUSH','DISPATCHER_QUEUE_SEMAPHORE') -- background task that handles requests, not a cause for concern
and wt.wait_type not in ('KSOURCE_WAKEUP','XE_DISPATCHER_WAIT','FT_IFTS_SCHEDULER_IDLE_WAIT','FT_IFTSHC_MUTEX','XE_TIMER_EVENT') -- other waits that can be safely ignored
group by wait_Type, wait_time_s, datecapture 
order by wait_type asc, YYYYMM asc

--total 
select distinct
	wait_type
,	wait_time_s = sum(wait_time_s) over (partition by wait_type) 
,	Pct			=	100. * sum(wait_time_s) over (partition by wait_type) / sum(wait_time_s) OVER ()
from  dbaadmin.dbo.sys_dm_os_wait_stats wt
where wt.wait_type NOT LIKE '%SLEEP%' 
and wt.wait_type <> 'REQUEST_FOR_DEADLOCK_SEARCH'
and wt.wait_type not in ('CLR_AUTO_EVENT','CLR_MANUAL_EVENT','DIRTY_PAGE_POLL')
and wt.wait_type not in ('HADR_FILESTREAM_IOMGR_IOCOMPLETION')
and wt.wait_type <> 'SQLTRACE_BUFFER_FLUSH' -- system trace, not a cause for concern
and wt.wait_type not in ('ONDEMAND_TASK_QUEUE','BROKER_TRANSMITTER','BROKER_EVENTHANDLER','LOGMGR_QUEUE','CHECKPOINT_QUEUE','BROKER_TO_FLUSH','DISPATCHER_QUEUE_SEMAPHORE') -- background task that handles requests, not a cause for concern
and wt.wait_type not in ('KSOURCE_WAKEUP','XE_DISPATCHER_WAIT','FT_IFTS_SCHEDULER_IDLE_WAIT','FT_IFTSHC_MUTEX','XE_TIMER_EVENT') -- other waits that can be safely ignored
order by pct desc

*/