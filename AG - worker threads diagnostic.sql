
/*
References:
https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-worker-threads-server-configuration-option

*/
EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE ;  
GO  
EXEC sp_configure 'max worker threads' --shows current setting, see below for script to change
--Configuration of 0 is default, means it is automatically calculated by SQL according to formula in this link: https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-worker-threads-server-configuration-option
--Manually overriding the setting may be needed for replicas of Availability Groups with many databases, but obviously has an upper limit in terms of system stability.
GO
select
	max_workers_count		= (select max_workers_count  FROM sys.dm_os_sys_info) --current running config setting
,	active_workers_sum		= sum(active_workers_count) --active_workers_sum should maintain < max_workers_count 
,	work_queue_count_avg	= avg(work_queue_count*1.) --Should not be above 1. If it is, probably need to override the worker threads formula (see above) and/or increase server processors.
,	current_workers_sum		= sum(current_workers_count) --total, informative only
FROM sys.dm_os_schedulers
WHERE status = 'VISIBLE ONLINE'
GO



/*
--sample below, to run on all replicas

EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE ;  
GO  
EXEC sp_configure 'max worker threads', 960;  
GO 
RECONFIGURE ;  
GO 

*/