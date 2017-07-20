--dbcc memorystatus
;with cte as (
select 'InstanceName' = @@SERVERNAME , Version = @@VERSION, 
'min server memory (MB)'  = max(case when name = 'min server memory (MB)' then value_in_use end) ,
'max server memory (MB)' = max(case when name = 'max server memory (MB)' then value_in_use end) 
from sys.configurations)
select 
	p.InstanceName
,	c.Version 
,	'LogicalCPUCount'		= os.cpu_count
,	os.[Server Physical Memory MB] -- SQL2012+ only
,	c.[min server memory (MB)]
,	c.[max server memory (MB)]
,	p.[Target Server Memory (MB)]	
,	p.[Total Server Memory (MB)]	
,	p.[Page Life Expectancy (s)] --300s is only a rule for smaller memory servers (<16gb)
,	'ChurnMB/s'				=	cast((p.[Total Server Memory (MB)])/1024./NULLIF(p.[Page Life Expectancy (s)],0) as decimal(19,2))
from(
select 
	InstanceName = @@SERVERNAME 
,	'Target Server Memory (MB)' =	max(case when counter_name = 'Target Server Memory (KB)' then convert(decimal(19,2), cntr_value/1024.)end)
,	'Total Server Memory (MB)'	=	max(case when counter_name = 'Total Server Memory (KB)' then convert(decimal(19,2), cntr_value/1024.) end) 
,	'Page Life Expectancy (s)'	=	max(case when counter_name = 'Page life expectancy'  then cntr_value end) 
from sys.dm_os_performance_counters) 
as p
inner join cte c on p.InstanceName = c.InstanceName
inner join (SELECT 'InstanceName' = @@SERVERNAME 
, cpu_count , hyperthread_ratio AS 'HyperthreadRatio',
cpu_count/hyperthread_ratio AS 'PhysicalCPUCount'
, 'Server Physical Memory MB' = cast(physical_memory_kb/1024. as decimal(19,2))   -- SQL2012+ only
FROM sys.dm_os_sys_info ) as os
on c.InstanceName=os.InstanceName



--adapted from http://www.datavail.com/category-blog/max-server-memory-300-second-rule/

