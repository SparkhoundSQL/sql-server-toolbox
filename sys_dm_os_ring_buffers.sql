select
 [Time] =  dateadd(ms, -1 * (dosi.cpu_ticks / (dosi.cpu_ticks/dosi.ms_ticks) - x.[timestamp]), SYSDATETIMEOFFSET ()) 
, CPU_SQL = record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') 
, CPU_Idle = record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
FROM (SELECT timestamp, convert(xml, record) AS record
 FROM sys.dm_os_ring_buffers
 WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR') AS x
CROSS APPLY sys.dm_os_sys_info AS dosi
ORDER by [Time] desc


SELECT
  [Time] =  dateadd(ms, -1 * (dosi.cpu_ticks / (dosi.cpu_ticks/dosi.ms_ticks) - x.[timestamp]), SYSDATETIMEOFFSET ())
, MemoryEvent = record.value('(./Record/ResourceMonitor/Notification)[1]', 'varchar(64)')
, Target_Server_Mem_GB = convert(decimal(19,3), record.value('(./Record/MemoryNode/TargetMemory)[1]', 'bigint')/1024./1024.)
, Physical_Server_Mem_GB = convert(decimal(19,3), record.value('(./Record/MemoryRecord/TotalPhysicalMemory)[1]', 'bigint')/1024./1024.)
, Committed_Mem_GB = convert(decimal(19,3), record.value('(./Record/MemoryNode/CommittedMemory)[1]', 'bigint')/1024./1024.)
, Shared_Mem_GB = convert(decimal(19,3), record.value('(./Record/MemoryNode/SharedMemory)[1]', 'bigint')/1024./1024.)
, MemoryUtilization = record.value('(./Record/MemoryRecord/MemoryUtilization)[1]', 'bigint')
, Available_Server_Mem_GB = convert(decimal(19,3), record.value('(./Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint')/1024./1024.)
FROM (SELECT timestamp, convert(xml, record) AS record
 FROM sys.dm_os_ring_buffers
 WHERE ring_buffer_type = N'RING_BUFFER_RESOURCE_MONITOR') as x
CROSS APPLY sys.dm_os_sys_info AS dosi
ORDER BY [Time] desc

/*

select 
cpu_ticks ,
(cpu_ticks/ms_ticks),
cpu_ticks / (cpu_ticks/ms_ticks)
 from sys.dm_os_sys_info

*/