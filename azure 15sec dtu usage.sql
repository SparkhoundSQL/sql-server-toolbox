--https://msdn.microsoft.com/en-us/library/dn800981.aspx
--Run in the user Azure database
SELECT SYSDATETIMEOFFSET()
GO

SELECT  
	Database_Name = DB_NAME()
,	TierDTU	= rs.dtu_limit
,	'Average CPU Utilization In %'				=	AVG(rs.avg_cpu_percent)			
,	'Maximum CPU Utilization In %'				=	MAX(rs.avg_cpu_percent)			
,	'Average Data IO In %'						=	AVG(rs.avg_data_io_percent)		
,	'Maximum Data IO In %'						=	MAX(rs.avg_data_io_percent)		
,	'Average Log Write Utilization In %'		=	AVG(rs.avg_log_write_percent)		   
,	'Maximum Log Write Utilization In %'		=	MAX(rs.avg_log_write_percent)		
,   'Average Memory Usage In %'					=	AVG(rs.avg_memory_usage_percent)  
,   'Maximum Memory Usage In %'   				=	MAX(rs.avg_memory_usage_percent)  
FROM sys.dm_db_resource_stats as rs  --past hour only
group by rs.dtu_limit

GO
select 
	Database_Name = DB_NAME()
,	UTC_time = end_time
,	'CPU Utilization In % of Limit'  			=	rs.avg_cpu_percent
,	'Data IO In % of Limit'						=	rs.avg_data_io_percent
,	'Log Write Utilization In % of Limit'		=	rs.avg_log_write_percent
,	'Memory Usage In % of Limit'				=	rs.avg_memory_usage_percent 
,	'In-Memory OLTP Storage in % of Limit'		=	rs.xtp_storage_percent
,	'Concurrent Worker Threads in % of Limit'	=	rs.max_worker_percent
,	'Concurrent Sessions in % of Limit'			=	rs.max_session_percent
from 
sys.dm_db_resource_stats as rs  --past hour only
order by rs.end_time desc


  
