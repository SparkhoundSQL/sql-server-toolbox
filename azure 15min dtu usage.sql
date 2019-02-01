--https://msdn.microsoft.com/en-us/library/dn800981.aspx
--Run in the master Azure SQL server database
SELECT SYSDATETIMEOFFSET()

SELECT 
	rs.Database_Name
,	rs.sku --Basic, Standard, Premium
,	TierDTU									= rs.dtu_limit
,	Storage_in_mb							=	MAX(rs.Storage_in_megabytes)
,	'Average CPU Utilization In %'			=	AVG(rs.avg_cpu_percent)			
,	'Maximum CPU Utilization In %'			=	MAX(rs.avg_cpu_percent)			
,	'Average Data IO In %'					=	AVG(rs.avg_data_io_percent)		
,	'Maximum Data IO In %'					=	MAX(rs.avg_data_io_percent)		
,	'Average Log Write Utilization In %'	=	AVG(rs.avg_log_write_percent)		   
,	'Maximum Log Write Utilization In %'	=	MAX(rs.avg_log_write_percent)		   
,	'Average Requests In %'					=	AVG(rs.max_worker_percent)	
,	'Maximum Requests In %'					=	MAX(rs.max_worker_percent)	
,	'Average Sessions In %'					=	AVG(rs.max_session_percent)	
,	'Maximum Sessions In %'					=	MAX(rs.max_session_percent)	
FROM  master.sys.resource_stats as rs  --past 14 days 
GROUP BY rs.Database_Name, rs.sku, rs.dtu_limit
ORDER BY rs.Database_Name desc

SELECT 
	Timestamp				=	datetimefromparts(year(rs.end_time), month(rs.end_time), day(rs.end_time), datepart(hh,rs.end_time), datepart(minute, rs.end_time),0,0)
,	rs.Database_Name
,	rs.sku --Basic, Standard, Premium
,	TierDTU									=	rs.dtu_limit
,	Storage_in_mb							=	MAX(rs.Storage_in_megabytes)
,	'Average CPU Utilization In %'			=	AVG(rs.avg_cpu_percent)			
,	'Maximum CPU Utilization In %'			=	MAX(rs.avg_cpu_percent)			
,	'Average Data IO In %'					=	AVG(rs.avg_data_io_percent)		
,	'Maximum Data IO In %'					=	MAX(rs.avg_data_io_percent)		
,	'Average Log Write Utilization In %'	=	AVG(rs.avg_log_write_percent)		   
,	'Maximum Log Write Utilization In %'	=	MAX(rs.avg_log_write_percent)		   
,	'Average Worker Requests In %'			=	AVG(rs.max_worker_percent)	
,	'Maximum Worker Requests In %'			=	MAX(rs.max_worker_percent)	
,	'Average Sessions In %'					=	AVG(rs.max_session_percent)	
,	'Maximum Sessions In %'					=	MAX(rs.max_session_percent)	
FROM master.sys.resource_stats as rs  --past 14 days only
GROUP BY rs.Database_Name, rs.sku, rs.dtu_limit, datetimefromparts(year(rs.end_time), month(rs.end_time), day(rs.end_time), datepart(hh,rs.end_time), datepart(minute, rs.end_time),0,0)
ORDER BY rs.Database_Name desc, TimeStamp DESC 

