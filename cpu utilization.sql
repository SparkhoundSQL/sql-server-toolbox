--This is simple, for more CPU and Memory, look at toolbox/sys_dm_os_ring_buffers.sql

--http://sqlblog.com/blogs/ben_nevarez/archive/2009/07/26/getting-cpu-utilization-data-from-sql-server.aspx

declare @ts_now bigint
--select @ts_now = cpu_ticks / convert(float, cpu_ticks_in_ms) from sys.dm_os_sys_info
select @ts_now = cpu_ticks / (cpu_ticks/ms_ticks) from sys.dm_os_sys_info;
select	record_id
	,	EventTime				=  dateadd(ms, -1 * (@ts_now - [timestamp]), GetDate()) 
	,	SQLProcessUtilization
	,	SystemIdle
	,	OtherProcessUtilization	= 100 - SystemIdle - SQLProcessUtilization 
from (
      select
            record_id				=	record.value('(./Record/@id)[1]', 'int')
        ,	SystemIdle				=	record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
        ,	SQLProcessUtilization	=	record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') 
        ,	timestamp
      from (
            select timestamp, convert(xml, record) as record
            from sys.dm_os_ring_buffers
            where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
            and record like '%<SystemHealth>%') as x
      ) as y
order by record_id desc