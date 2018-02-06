
select 
	p.InstanceName
,	c.Version 
,	'LogicalCPUCount'		= os.cpu_count
,	Server_Physical_Mem_MB = os.[Server Physical Mem (MB)] -- SQL2012+ only
,	Min_Server_Mem_MB = c.[Min_Server_Mem_MB]
,	Max_Server_Mem_MB = c.[Max_Server_Mem_MB] --2147483647 means unlimited, just like it shows in SSMS
,	p.PLE_s --300s is only an arbitrary rule for smaller memory servers (<16gb), for larger, it should be baselined and measured.
,	'Churn (MB/s)'			=	cast((p.Total_Server_Mem_GB)/1024./NULLIF(p.PLE_s,0) as decimal(19,2))
,	Server_Available_physical_mem_GB = (SELECT cast(available_physical_memory_kb / 1024. / 1024. as decimal(19,2)) from sys.dm_os_sys_memory) 
,	SQL_Physical_memory_in_use_GB = (SELECT cast(physical_memory_in_use_kb / 1024. / 1024. as decimal(19,2)) from sys.dm_os_process_memory)
,	p.Total_Server_Mem_GB --May be more or less than memory_in_use because it 
,	p.Target_Server_Mem_GB	
,	si.LPIM -- Works on SQL 2016 SP1 and above only
from(
select 
	InstanceName = @@SERVERNAME 
,	Target_Server_Mem_GB =	max(case counter_name when 'Target Server Memory (KB)' then convert(decimal(19,3), cntr_value/1024./1024.) end)
,	Total_Server_Mem_GB	=	max(case counter_name when  'Total Server Memory (KB)' then convert(decimal(19,3), cntr_value/1024./1024.) end) 
,	PLE_s	=	max(case counter_name when 'Page life expectancy'  then cntr_value end) 
--select * 
from sys.dm_os_performance_counters
--This only looks at one NUMA node. https://www.sqlskills.com/blogs/paul/page-life-expectancy-isnt-what-you-think/
)  as p
inner join (select 'InstanceName' = @@SERVERNAME, Version = @@VERSION, 
			min_Server_Mem_MB  = max(case when name = 'min server memory (MB)' then convert(bigint, value_in_use) end) ,
			max_Server_Mem_MB = max(case when name = 'max server memory (MB)' then convert(bigint, value_in_use) end) 
			from sys.configurations) as c on p.InstanceName = c.InstanceName
inner join (SELECT 'InstanceName' = @@SERVERNAME 
			, cpu_count , hyperthread_ratio AS 'HyperthreadRatio',
			cpu_count/hyperthread_ratio AS 'PhysicalCPUCount'
			, 'Server Physical Mem (MB)' = cast(physical_memory_kb/1024. as decimal(19,2))   -- SQL2012+ only
			FROM sys.dm_os_sys_info ) as os
on c.InstanceName=os.InstanceName


-- SQL 2016 SP1 and above only
cross apply (select LPIM = CASE sql_memory_model_Desc 
					WHEN  'Conventional' THEN 'Lock Pages in Memory privilege is not granted'
					WHEN 'LOCK_PAGES' THEN 'Lock Pages in Memory privilege is granted'
					WHEN 'LARGE_PAGES' THEN 'Lock Pages in Memory privilege is granted in Enterprise mode with Trace Flag 834 ON'
					END from sys.dm_os_sys_info 
				) as si

--adapted from http://www.datavail.com/category-blog/max-server-memory-300-second-rule/

