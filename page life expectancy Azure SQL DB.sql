--For Azure SQL DB only 

select 
	p.InstanceName
,	c.Version 
,	Min_Server_Mem_MB = c.[Min_Server_Mem_MB]
,	Max_Server_Mem_MB = c.[Max_Server_Mem_MB] --2147483647 means unlimited, just like it shows in SSMS
,	p.PLE_s --300s is only an arbitrary rule for smaller memory servers (<16gb), for larger, it should be baselined and measured.
,	'Churn (MB/s)'			=	cast((p.Total_Server_Mem_GB)/1024./NULLIF(p.PLE_s,0) as decimal(19,2))
,	p.Total_Server_Mem_GB --May be more or less than memory_in_use 
,	p.Target_Server_Mem_GB	
,	Target_vs_Total = CASE WHEN p.Total_Server_Mem_GB < p.Target_Server_Mem_GB	 
							THEN 'Target >= Total. SQL wants more memory than it has, or is building up to that point.'
							ELSE 'Total >= Target. SQL has enough memory to do what it wants.' END
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
