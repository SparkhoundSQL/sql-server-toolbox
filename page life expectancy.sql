--dbcc memorystatus
;with cte as (
select 'InstanceName' = @@SERVERNAME , Version = @@VERSION, 
'min server mem (MB)'  = max(case when name = 'min server memory (MB)' then value_in_use end) ,
'max server mem (MB)' = max(case when name = 'max server memory (MB)' then value_in_use end) 
from sys.configurations)
select 
	p.InstanceName
,	c.Version 
,	'LogicalCPUCount'		= os.cpu_count
,	os.[Server Physical Mem (MB)] -- SQL2012+ only
,	c.[Min Server Mem (MB)]
,	c.[Max Server Mem (MB)]
,	p.[Target Server Mem (MB)]	
,	p.[Total Server Mem (MB)]	
,	p.[PLE (s)] --300s is only a rule for smaller memory servers (<16gb)
,	'Churn (MB/s)'			=	cast((p.[Total Server Mem (MB)])/1024./NULLIF(p.[PLE (s)],0) as decimal(19,2))
,	si.LPIM -- Works on SQL 2016 SP1 and above only
from(
select 
	InstanceName = @@SERVERNAME 
,	'Target Server Mem (MB)' =	max(case when counter_name = 'Target Server Memory (KB)' then convert(decimal(19,2), cntr_value/1024.)end)
,	'Total Server Mem (MB)'	=	max(case when counter_name = 'Total Server Memory (KB)' then convert(decimal(19,2), cntr_value/1024.) end) 
,	'PLE (s)'	=	max(case when counter_name = 'Page life expectancy'  then cntr_value end) 
from sys.dm_os_performance_counters) 
as p
inner join cte c on p.InstanceName = c.InstanceName
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

