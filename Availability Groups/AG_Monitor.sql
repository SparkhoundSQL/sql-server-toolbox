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
	

declare @start_tick bigint, @start_cntr bigint

select @start_tick = MAX(ms_ticks), @start_cntr = MAX(cntr_value) --the availability database with the highest Tdata_loss becomes the limiting value for RPO compliance.
from sys.dm_os_sys_info
cross apply sys.dm_os_performance_counters where counter_name like 'Log Bytes Flushed/sec%'

waitfor delay '00:00:02'

declare @end_tick bigint, @end_cntr bigint
select @end_tick =  MAX(ms_ticks), @end_cntr = MAX(cntr_value) --the availability database with the highest Tdata_loss becomes the limiting value for RPO compliance.
from sys.dm_os_sys_info
cross apply sys.dm_os_performance_counters where counter_name like 'Log Bytes Flushed/sec%'

declare @LogBytesFushed decimal(19,2) 
set @LogBytesFushed = (@end_cntr - @start_cntr) / NULLIF(@end_tick - @start_tick,0)

select 
	Replica				= ar.replica_server_name + ' ' + case when is_local = 1 then '(local)' else '' end
,	Replica_Role		= case when last_received_time is null then 'PRIMARY' ELSE 'SECONDARY ('+ar.secondary_role_allow_connections_desc+')' END
,	DB					= db_name(database_id)
,	dm.synchronization_state_desc 
,	dm.synchronization_health_desc
,	ar.availability_mode_desc
,	ar.failover_mode_desc
,	Suspended = case is_suspended when 1 then suspend_reason_desc else null end
,	last_received_time
,	last_commit_time
,	redo_queue_size_mb = redo_queue_size/1024.
,	Redo_Time_Left_s_RTO = dm.redo_queue_size/NULLIF(dm.redo_rate,0) --https://msdn.microsoft.com/en-us/library/dn135338(v=sql.110).aspx --only part of RTO
,	Log_Send_Queue_RPO = dm.log_send_queue_size/NULLIF(@LogBytesFushed ,0) --Rate
,	ar.backup_priority
,	ar.modify_date
,	ar.endpoint_url 
,	ar.read_only_routing_url
from sys.dm_hadr_database_replica_states dm
INNER JOIN sys.availability_replicas ar on dm.replica_id = ar.replica_id and dm.group_id = ar.group_id
ORDER BY DB, [Replica], Replica_Role
--WHERE db_name(database_id) = 'operations'

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