
select top 10

	wait_type
,	wait_time_s =  wait_time_ms / 1000.  
,	Pct			=	100. * wait_time_ms/sum(wait_time_ms) OVER()
from sys.dm_os_wait_stats wt
where wt.wait_type NOT LIKE '%SLEEP%' 
and wt.wait_type <> 'REQUEST_FOR_DEADLOCK_SEARCH'
and wt.wait_type not in ('CLR_AUTO_EVENT','CLR_MANUAL_EVENT','DIRTY_PAGE_POLL','CLR_SEMAPHORE','BROKER_TASK_STOP')
and wt.wait_type not in ('HADR_FILESTREAM_IOMGR_IOCOMPLETION','QDS_SHUTDOWN_QUEUE')
and wt.wait_type <> 'SQLTRACE_BUFFER_FLUSH' -- system trace, not a cause for concern
and wt.wait_type not in ('ONDEMAND_TASK_QUEUE','BROKER_TRANSMITTER','BROKER_EVENTHANDLER','LOGMGR_QUEUE','CHECKPOINT_QUEUE','BROKER_TO_FLUSH','DISPATCHER_QUEUE_SEMAPHORE') -- background task that handles requests, not a cause for concern
and wt.wait_type not in ('KSOURCE_WAKEUP','XE_DISPATCHER_WAIT','FT_IFTS_SCHEDULER_IDLE_WAIT','FT_IFTSHC_MUTEX','XE_TIMER_EVENT') -- other waits that can be safely ignored
order by Pct desc

/*

--Script to setup capturing these statistics over time
--Assumes a DBAAdmin database has been created

drop table dbaadmin.dbo.sys_dm_os_wait_stats 

create table dbaadmin.dbo.sys_dm_os_wait_stats 
(	id int not null primary key IDENTITY(1,1)
,	datecapture datetime2(2)
,	wait_Type nvarchar(512)
,	wait_time_s  decimal(19,1)
,	Pct decimal(9,1) 
)

insert into dbaadmin.dbo.sys_dm_os_wait_stats  (datecapture, wait_type,	wait_time_s, Pct)
select top 100
	datecapture =	convert(datetime2(2), getdate())
,	wait_type
,	wait_time_s =	convert(decimal(19,1), round( wait_time_ms / 1000.0,1))
,	Pct			=	wait_time_ms/sum(wait_time_ms) OVER() 
from sys.dm_os_wait_stats wt
Where round(wait_time_ms,0) > 0.0
order by wait_time_s

DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR);
go

declare @x int = 1
while (@x<30)
Begin
	insert into dbaadmin.dbo.sys_dm_os_wait_stats (datecapture, wait_type, wait_time_s)
	select 
		datecapture = dateadd(day, -@x, datecapture)
	,	wait_type
	,	wait_time_s = wait_time_s - ((.1 * @x) * wait_time_s)
	 from dbaadmin.dbo.sys_dm_os_wait_stats where id <= 31
	set @x = @x +1

	DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR);

END





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