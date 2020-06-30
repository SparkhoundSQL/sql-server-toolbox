use TempDB;
GO
select 
	[InstanceName]		= @@SERVERNAME
,	[SQL_Version]		= @@VERSION
,	si.*
,	i.[Min_Server_Mem_MB]
,	i.[Max_Server_Mem_MB] --2147483647 means unlimited, just like it shows in SSMS
,	p.PLE_s --300s is only an arbitrary rule for smaller memory servers (<16gb), for larger, it should be baselined and measured.
,	'Churn (MB/s)'			=	cast((si.Total_Server_Memory_GB*1024.)/NULLIF(p.PLE_s,0) as decimal(19,2))
,	OS_Available_physical_mem_GB = (SELECT cast(available_physical_memory_kb / 1024. / 1024. as decimal(19,2)) from sys.dm_os_sys_memory) 
,	SQL_Physical_memory_in_use_GB = (SELECT cast(physical_memory_in_use_kb / 1024. / 1024. as decimal(19,2)) from sys.dm_os_process_memory)
,	Target_vs_Total = CASE  WHEN si.Total_Server_Memory_GB < si.Target_Server_Memory_GB
							THEN 'Target >= Total. SQL wants more memory than it has, or is building up to that point.'
							ELSE 'Total >= Target. SQL has enough memory to do what it wants.' END
FROM 		(SELECT 	InstanceName = @@SERVERNAME  
					,	PLE_s	=	max(case counter_name when 'Page life expectancy'  then cntr_value end) 
			FROM sys.dm_os_performance_counters --This only looks at one NUMA node. https://www.sqlskills.com/blogs/paul/page-life-expectancy-isnt-what-you-think/
			)  as p
cross apply (SELECT		Min_Server_Mem_MB  = max(case when name = 'min server memory (MB)' then convert(bigint, value_in_use) end)
					,	Max_Server_Mem_MB = max(case when name = 'max server memory (MB)' then convert(bigint, value_in_use) end) 
			FROM sys.configurations
			) as i
cross apply (SELECT		sqlserver_start_time
					,	OS_Physical_Mem_MB = convert(bigint, physical_memory_kb /1024.)
					, 	Total_Server_Memory_GB = convert(decimal(19,3), committed_kb / 1024. / 1024.)
					,	Target_Server_Memory_GB = convert(decimal(19,3), committed_target_kb / 1024. / 1024.)
			FROM sys.dm_os_sys_info 
			) as si;

--For LPIM check toolbox\lock Pages in Memory LPIM.sql
--For CPU infor check toolbox\cpu utilization.sql