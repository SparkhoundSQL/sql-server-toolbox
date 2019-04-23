--On a secondary replica, this view returns a row for every secondary database on the server instance. 
--On the primary replica, this view returns a row for each primary database and an additional row for the corresponding secondary database.

--Updated WDA 20180209


--Monitor Availability Group performance
--On a secondary replica, this view returns a row for every secondary database on the server instance. 
--On the primary replica, this view returns a row for each primary database and an additional row for the corresponding secondary database. Recommended.

IF NOT EXISTS (
SELECT @@SERVERNAME
   FROM sys.dm_hadr_availability_replica_states
   WHERE is_local = 1
   and role_desc = 'PRIMARY'
)
  SELECT 'Recommend: Run This Script on Primary Replica';

DECLARE @BytesFlushed_Start_ms bigint, @BytesFlushed_Start bigint, @BytesFlushed_End_ms bigint, @BytesFlushed_End bigint

DECLARE @TransactionDelay TABLE
(	DB sysname COLLATE SQL_Latin1_General_CP1_CI_AS not null
,	TransactionDelay_Start_ms decimal(19,2) null
,	TransactionDelay_end_ms decimal(19,2) null
,	TransactionDelay_Start decimal(19,2) null
,	TransactionDelay_end decimal(19,2) null
,	MirroredWriteTranspersec_Start_ms decimal(19,2) null
,	MirroredWriteTranspersec_end_ms decimal(19,2) null
,	MirroredWriteTranspersec_Start decimal(19,2) null
,	MirroredWriteTranspersec_end decimal(19,2) null
,	UNIQUE CLUSTERED (DB)
)

INSERT INTO @TransactionDelay (DB, TransactionDelay_Start_ms, TransactionDelay_Start)
select DB = pc.instance_name
,	TransactionDelay_Start_ms = MAX(ms_ticks)
,	TransactionDelay_Start = MAX(convert(decimal(19,2), pc.cntr_value))
from sys.dm_os_sys_info as si
CROSS APPLY sys.dm_os_performance_counters as pc
 where object_name like '%database replica%'
 and counter_name = 'transaction delay' --cumulative transaction delay in ms
 group by pc.instance_name
  
UPDATE t 
SET MirroredWriteTranspersec_Start_ms = t2.MirroredWriteTranspersec_Start_ms
,	MirroredWriteTranspersec_Start = t2.MirroredWriteTranspersec_Start
from @TransactionDelay t
inner join 
(select DB = pc.instance_name
,	MirroredWriteTranspersec_Start_ms = MAX(ms_ticks)
,	MirroredWriteTranspersec_Start = MAX(convert(decimal(19,2), pc.cntr_value))
from sys.dm_os_sys_info as si
CROSS APPLY sys.dm_os_performance_counters as pc
 where object_name like '%database replica%'
 and counter_name = 'mirrored write transactions/sec' --actually a cumulative transactions count, not per sec
 group by pc.instance_name
 ) t2 on t.DB = t2.DB

select @BytesFlushed_Start_ms = MAX(ms_ticks), @BytesFlushed_Start = MAX(cntr_value) --the availability database with the highest Tdata_loss becomes the limiting value for RPO compliance.
from sys.dm_os_sys_info
CROSS APPLY sys.dm_os_performance_counters where counter_name like 'Log Bytes Flushed/sec%'

WAITFOR DELAY '00:00:05' --Adjust sample duration between measurements

UPDATE t 
SET TransactionDelay_end_ms = t2.TransactionDelay_end_ms
,	TransactionDelay_end = t2.TransactionDelay_end
from @TransactionDelay t
inner join 
(select DB = pc.instance_name
,	TransactionDelay_end_ms = MAX(ms_ticks)
,	TransactionDelay_end = MAX(convert(decimal(19,2), pc.cntr_value))
from sys.dm_os_sys_info as si
CROSS APPLY sys.dm_os_performance_counters as pc
 where object_name like '%database replica%'
 and counter_name = 'transaction delay' --cumulative transaction delay in ms
 group by pc.instance_name
 ) t2 on t.DB = t2.DB
 
UPDATE t 
SET MirroredWriteTranspersec_end_ms = t2.MirroredWriteTranspersec_end_ms
,	MirroredWriteTranspersec_end = t2.MirroredWriteTranspersec_end
from @TransactionDelay t
inner join 
(select DB = pc.instance_name
,	MirroredWriteTranspersec_end_ms = MAX(ms_ticks)
,	MirroredWriteTranspersec_end = MAX(convert(decimal(19,2), pc.cntr_value))
from sys.dm_os_sys_info as si
CROSS APPLY sys.dm_os_performance_counters as pc
 where object_name like '%database replica%'
 and counter_name = 'mirrored write transactions/sec'  --actually a cumulative transactions count, not per sec
 group by pc.instance_name
 ) t2 on t.DB = t2.DB

select @BytesFlushed_End_ms =  MAX(ms_ticks), @BytesFlushed_End = MAX(cntr_value) --the availability database with the highest Tdata_loss becomes the limiting value for RPO compliance.
from sys.dm_os_sys_info
CROSS APPLY sys.dm_os_performance_counters where counter_name like 'Log Bytes Flushed/sec%'

declare @LogBytesFlushed decimal(19,2) 
set @LogBytesFlushed = (@BytesFlushed_End - @BytesFlushed_Start) / NULLIF(@BytesFlushed_End_ms - @BytesFlushed_Start_ms,0)

--select * from @TransactionDelay

select 
	AG					= ag.name
,	Instance			= ar.replica_server_name + ' ' + case when is_local = 1 then '(local)' else '' end
,	DB					= db_name(dm.database_id)	
,	Replica_Role		= CASE WHEN last_received_time IS NULL THEN 'PRIMARY (Connections: '+ar.primary_role_allow_connections_desc+')' ELSE 'SECONDARY (Connections: '+ar.secondary_role_allow_connections_desc+')' END
,	Last_received_time
,	Last_commit_time
,	dm.synchronization_state_desc 
,	dm.synchronization_health_desc
,	ar.availability_mode_desc
,	ar.failover_mode_desc
,	Suspended = case is_suspended when 1 then suspend_reason_desc else 'NO' end
,	Redo_queue_size_MB		= convert(decimal(19,2),dm.redo_queue_size/1024.)--KB
,	Redo_rate_MB_per_s		= convert(decimal(19,2),dm.redo_rate/1024.) --KB/s
,	Redo_Time_Left_s_RTO	= convert(decimal(19,2),dm.redo_queue_size*1./NULLIF(dm.redo_rate*1.,0)) --only part of RTO. NULL value on secondary replica indicates no sampled activity.
,	Log_Send_Queue_Size_MB		= convert(decimal(19,2),dm.log_send_queue_size/1024.) 
,	Log_Send_Queue_Bytes_flushed_per_s = NULLIF(@LogBytesFlushed ,0)
,	Log_Send_Queue_Time_Left_s_RPO	= convert(decimal(19,2),dm.log_send_queue_size*1./NULLIF(@LogBytesFlushed ,0)) --Rate. NULL value on secondary replica indicates no sampled activity.
,	Sampled_Transactions_count		= (td.MirroredWriteTranspersec_end - td.MirroredWriteTranspersec_start)  
,	Sampled_Transaction_Delay_ms	= (td.TransactionDelay_end - td.TransactionDelay_start)  
--Transaction Delay numbers will be 0 if there is no synchronous replica for the DB
,	Avg_Sampled_Transaction_Delay_ms_per_s	= convert(decimal(19,2), (td.TransactionDelay_end - td.TransactionDelay_Start) / ((td.TransactionDelay_end_ms - td.TransactionDelay_Start_ms)/1000.))
,	Transactions_per_s	= convert(decimal(19,2), ((td.MirroredWriteTranspersec_end - td.MirroredWriteTranspersec_start) / ((td.MirroredWriteTranspersec_End_ms - td.MirroredWriteTranspersec_Start_ms)/1000.)))
,	dm.secondary_lag_seconds --sql 2016 and above only
,	ar.backup_priority
,	ar.modify_date
,	ar.endpoint_url 
,	ar.read_only_routing_url
,	ar.session_timeout
from sys.dm_hadr_database_replica_states dm
INNER JOIN sys.availability_replicas ar on dm.replica_id = ar.replica_id and dm.group_id = ar.group_id
INNER JOIN sys.availability_groups ag on ag.group_id = dm.group_id
LEFT OUTER JOIN @TransactionDelay td on td.DB = db_name(dm.database_id) --LEFT OUTER in case the sys.dm_os_performance_counters DMV is blank because of a rare issue with SQL startup. Still returns the rest of the data.
ORDER BY
	AG			
,	Instance		
,	DB			
,	Replica_Role

--Current node only, should be run on primary
select 
	wait_type
,	waiting_tasks_count
,	wait_time_ms
,	per_wait_ms = convert(decimal(19,2), (convert(decimal(19,2), wait_time_ms)/ convert(decimal(19,2),waiting_tasks_count) ))
from sys.dm_os_wait_stats where waiting_tasks_count >0 
and wait_type like 'HADR_%_COMMIT'

--SELECT log_reuse_wait_desc FROM sys.databases WHERE name = 'operations'

--Check for suspect pages (hopefully 0 rows returned)
--https://msdn.microsoft.com/en-us/library/ms191301.aspx
SELECT * FROM msdb.dbo.suspect_pages
   WHERE (event_type <= 3);

--Check for autorepair events (hopefully 0 rows returned)
--https://msdn.microsoft.com/en-us/library/bb677167.aspx
select db = db_name(database_id)
,	file_id
,	page_id
,	error_type 
,	page_status
,	modification_time
from sys.dm_hadr_auto_page_repair order by modification_time desc

--Replica status (one row per replica when run on the primary)
select 
	ag.name,
	rcs.replica_server_name,
	rs.last_connect_error_number, rs.last_connect_error_description, rs.last_connect_error_timestamp,
	rs.operational_state_desc,
	rs.recovery_health_desc,
	rs.connected_state_desc,
	rs.role_desc,
	rs.synchronization_health_desc
from sys.dm_hadr_availability_replica_states rs --https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-hadr-availability-replica-states-transact-sql?view=sql-server-2017
inner join sys.dm_hadr_availability_replica_cluster_states rcs
on rs.replica_id = rcs.replica_id
inner join sys.availability_groups ag 
on ag.group_id = rcs.group_id

--https://msdn.microsoft.com/en-us/library/ff877972(v=sql.110).aspx
--https://msdn.microsoft.com/en-us/library/dn135338(v=sql.110).aspx
--https://blogs.msdn.microsoft.com/psssql/2013/09/23/interpreting-the-counter-values-from-sys-dm_os_performance_counters/
--https://msdn.microsoft.com/en-us/library/ms175048.aspx

