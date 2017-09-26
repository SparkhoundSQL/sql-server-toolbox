--On a secondary replica, this view returns a row for every secondary database on the server instance. 
--On the primary replica, this view returns a row for each primary database and an additional row for the corresponding secondary database.

--Updated WDA 20170622

IF NOT EXISTS (
SELECT @@SERVERNAME, *
   FROM sys.dm_hadr_availability_replica_states  rs
   inner join sys.availability_databases_cluster dc
   on rs.group_id = dc.group_id
   WHERE is_local = 1
   and role_desc = 'PRIMARY'
)
  SELECT 'Recommend: Run This Script on Primary Replica';
	

DECLARE @BytesFlushed_Start_ms bigint, @BytesFlushed_Start bigint, @BytesFlushed_End_ms bigint, @BytesFlushed_End bigint

DECLARE @TransactionDelay TABLE
(	instance_name nvarchar(256) not null PRIMARY KEY
,	TransactionDelay_Start_ms decimal(19,2) null
,	TransactionDelay_end_ms decimal(19,2) null
,	TransactionDelay_Start decimal(19,2) null
,	TransactionDelay_end decimal(19,2) null
,	MirroredWriteTranspersec_Start_ms decimal(19,2) null
,	MirroredWriteTranspersec_end_ms decimal(19,2) null
,	MirroredWriteTranspersec_Start decimal(19,2) null
,	MirroredWriteTranspersec_end decimal(19,2) null
)

INSERT INTO @TransactionDelay (instance_name, TransactionDelay_Start_ms, TransactionDelay_Start)
select instance_name
,	TransactionDelay_Start_ms = MAX(ms_ticks)
,	TransactionDelay_Start = MAX(convert(decimal(19,2), pc.cntr_value))
from sys.dm_os_sys_info as si
cross apply sys.dm_os_performance_counters as pc
 where object_name like '%database replica%'
 and counter_name = 'transaction delay' --cumulative transaction delay in ms
 group by instance_name

 
UPDATE t 
SET MirroredWriteTranspersec_Start_ms = t2.MirroredWriteTranspersec_Start_ms
,	MirroredWriteTranspersec_Start = t2.MirroredWriteTranspersec_Start
from @TransactionDelay t
inner join 
(select instance_name
,	MirroredWriteTranspersec_Start_ms = MAX(ms_ticks)
,	MirroredWriteTranspersec_Start = MAX(convert(decimal(19,2), pc.cntr_value))
from sys.dm_os_sys_info as si
cross apply sys.dm_os_performance_counters as pc
 where object_name like '%database replica%'
 and counter_name = 'mirrored write transactions/sec' --actually a cumulative transactions count, not per sec
 group by instance_name
 ) t2 on t.instance_name = t2.instance_name

select @BytesFlushed_Start_ms = MAX(ms_ticks), @BytesFlushed_Start = MAX(cntr_value) --the availability database with the highest Tdata_loss becomes the limiting value for RPO compliance.
from sys.dm_os_sys_info
cross apply sys.dm_os_performance_counters where counter_name like 'Log Bytes Flushed/sec%'

waitfor delay '00:00:04'

UPDATE t 
SET TransactionDelay_end_ms = t2.TransactionDelay_end_ms
,	TransactionDelay_end = t2.TransactionDelay_end
from @TransactionDelay t
inner join 
(select instance_name
,	TransactionDelay_end_ms = MAX(ms_ticks)
,	TransactionDelay_end = MAX(convert(decimal(19,2), pc.cntr_value))
from sys.dm_os_sys_info as si
cross apply sys.dm_os_performance_counters as pc
 where object_name like '%database replica%'
 and counter_name = 'transaction delay' --cumulative transaction delay in ms
 group by instance_name
 ) t2 on t.instance_name = t2.instance_name
 
UPDATE t 
SET MirroredWriteTranspersec_end_ms = t2.MirroredWriteTranspersec_end_ms
,	MirroredWriteTranspersec_end = t2.MirroredWriteTranspersec_end
from @TransactionDelay t
inner join 
(select instance_name
,	MirroredWriteTranspersec_end_ms = MAX(ms_ticks)
,	MirroredWriteTranspersec_end = MAX(convert(decimal(19,2), pc.cntr_value))
from sys.dm_os_sys_info as si
cross apply sys.dm_os_performance_counters as pc
 where object_name like '%database replica%'
 and counter_name = 'mirrored write transactions/sec'  --actually a cumulative transactions count, not per sec
 group by instance_name
 ) t2 on t.instance_name = t2.instance_name

select @BytesFlushed_End_ms =  MAX(ms_ticks), @BytesFlushed_End = MAX(cntr_value) --the availability database with the highest Tdata_loss becomes the limiting value for RPO compliance.
from sys.dm_os_sys_info
cross apply sys.dm_os_performance_counters where counter_name like 'Log Bytes Flushed/sec%'

declare @LogBytesFushed decimal(19,2) 
set @LogBytesFushed = (@BytesFlushed_End - @BytesFlushed_Start) / NULLIF(@BytesFlushed_End_ms - @BytesFlushed_Start_ms,0)

select 
	Replica				= ar.replica_server_name + ' ' + case when is_local = 1 then '(local)' else '' end
,	Replica_Role		= case when last_received_time is null then 'PRIMARY' ELSE 'SECONDARY ('+ar.secondary_role_allow_connections_desc+')' END
,	DB					= db_name(dm.database_id)
,	dm.synchronization_state_desc 
,	dm.synchronization_health_desc
,	ar.availability_mode_desc
,	ar.failover_mode_desc
,	Suspended = case is_suspended when 1 then suspend_reason_desc else null end
,	last_received_time
,	last_commit_time
,	redo_queue_size_mb		= redo_queue_size/1024.
,	Redo_Time_Left_s_RTO	= dm.redo_queue_size/NULLIF(dm.redo_rate,0) --https://msdn.microsoft.com/en-us/library/dn135338(v=sql.110).aspx --only part of RTO
,	Log_Send_Queue_RPO		= dm.log_send_queue_size/NULLIF(@LogBytesFushed ,0) --Rate
,	Sampled_Transactions_count			= (td.MirroredWriteTranspersec_end - td.MirroredWriteTranspersec_start)  
,	Sampled_Transaction_Delay_ms	= (td.TransactionDelay_end - td.TransactionDelay_start)  
,	Transaction_Delay_ms_per_s	= convert(decimal(19,2), (td.TransactionDelay_end - td.TransactionDelay_Start) / ((td.TransactionDelay_end_ms - td.TransactionDelay_Start_ms)/1000.))
,	Transactions_per_s	= convert(decimal(19,2), ((td.MirroredWriteTranspersec_end - td.MirroredWriteTranspersec_start) / ((td.MirroredWriteTranspersec_End_ms - td.MirroredWriteTranspersec_Start_ms)/1000.)))
,	dm.secondary_lag_seconds --Only works SQL 2016+
,	ar.backup_priority
,	ar.modify_date
,	ar.endpoint_url 
,	ar.read_only_routing_url

from sys.dm_hadr_database_replica_states dm
INNER JOIN sys.availability_replicas ar on dm.replica_id = ar.replica_id and dm.group_id = ar.group_id
INNER JOIN @TransactionDelay td on td.instance_name = db_name(dm.database_id)
ORDER BY DB, [Replica], Replica_Role

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


--https://msdn.microsoft.com/en-us/library/ff877972(v=sql.110).aspx
--https://msdn.microsoft.com/en-us/library/dn135338(v=sql.110).aspx
--https://blogs.msdn.microsoft.com/psssql/2013/09/23/interpreting-the-counter-values-from-sys-dm_os_performance_counters/
--https://msdn.microsoft.com/en-us/library/ms175048.aspx

