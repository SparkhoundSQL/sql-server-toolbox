--https://msdn.microsoft.com/en-us/library/dn800981.aspx
--Run in the master Azure SQL server database
select 
	Database_Name
,	sku --Basic, Standard, Premium
,	TierDTU	= dtu_limit
,	Storage_in_mb			=	MAX(Storage_in_megabytes)
,	'Average CPU Utilization In %'			=	AVG(avg_cpu_percent)			
,	'Maximum CPU Utilization In %'			=	MAX(avg_cpu_percent)			
,	'Average Data IO In %'					=	AVG(avg_data_io_percent)		
,	'Maximum Data IO In %'					=	MAX(avg_data_io_percent)		
,	'Average Log Write Utilization In %'	=	AVG(avg_log_write_percent)		   
,	'Maximum Log Write Utilization In %'	=	MAX(avg_log_write_percent)		   
,	'Average Requests In %'					=	AVG(max_worker_percent)	
,	'Maximum Requests In %'					=	MAX(max_worker_percent)	
,	'Average Sessions In %'					=	AVG(max_session_percent)	
,	'Maximum Sessions In %'					=	MAX(max_session_percent)	
--select *
from 
master.sys.resource_stats as rs  --past 14 days 
group by Database_Name, sku, dtu_limit
order by Database_Name desc

select 
	Timestamp				=	datetimefromparts(year(rs.end_time), month(rs.end_time), day(rs.end_time), datepart(hh,rs.end_time), 0,0,0)
,	Database_Name
,	sku --Basic, Standard, Premium
,	TierDTU					= dtu_limit
,	Storage_in_mb			=	MAX(Storage_in_megabytes)
,	'Average CPU Utilization In %'			=	AVG(avg_cpu_percent)			
,	'Maximum CPU Utilization In %'			=	MAX(avg_cpu_percent)			
,	'Average Data IO In %'					=	AVG(avg_data_io_percent)		
,	'Maximum Data IO In %'					=	MAX(avg_data_io_percent)		
,	'Average Log Write Utilization In %'	=	AVG(avg_log_write_percent)		   
,	'Maximum Log Write Utilization In %'	=	MAX(avg_log_write_percent)		   
,	'Average Requests In %'					=	AVG(max_worker_percent)	
,	'Maximum Requests In %'					=	MAX(max_worker_percent)	
,	'Average Sessions In %'					=	AVG(max_session_percent)	
,	'Maximum Sessions In %'					=	MAX(max_session_percent)	
--select *
from 
master.sys.resource_stats as rs  --past 14 days only
group by Database_Name, sku, dtu_limit, datetimefromparts(year(rs.end_time), month(rs.end_time), day(rs.end_time), datepart(hh,rs.end_time), 0,0,0)
order by Database_Name desc, TimeStamp DESC 

