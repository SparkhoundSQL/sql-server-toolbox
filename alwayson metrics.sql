select * from sys.dm_hadr_cluster hc
select * from sys.dm_hadr_cluster_members cm

select td.instance_name, delay_ms = td.cntr_value, transactions_count = mts.cntr_value,  transactiondelay_ms = convert(decimal(9,2),td.cntr_value / mts.cntr_value)
from 
( select instance_name,cntr_value = convert(decimal(9,2), cntr_value)
from sys.dm_os_performance_counters
 where object_name like '%database replica%'
 and counter_name = 'transaction delay' --cumulative transaction delay in ms
 ) td
 inner join
 (
select instance_name,cntr_value = convert(decimal(9,2), cntr_value)
from sys.dm_os_performance_counters
 where object_name like '%database replica%'
 and counter_name =  'mirrored write transactions/sec' --actually a cumulative transactions count, not per sec
 ) mts
 on td.instance_name = mts.instance_name



select wait_type, waiting_tasks_count, wait_time_ms, wait_time_ms/waiting_tasks_count as'time_per_wait' 
from sys.dm_os_wait_stats where waiting_tasks_count >0 
and wait_type like 'HADR_%_COMMIT'
