declare @tempperfmon table (
[object_name]	nchar	(256) null,
counter_name	nchar	(256) null,
instance_name	nchar	(256) null,
cntr_value		bigint	null
, second_value bigint null
)

--For databases both the primary and secondary, with send/receive counters reflecting the local replica
insert into @tempperfmon ([object_name],counter_name,instance_name,cntr_value)
select [object_name],counter_name,instance_name,cntr_value
from sys.dm_os_performance_counters
 where [object_name] like '%Availability Replica%' and instance_name <> '_Total' and
	(	counter_name = 'Bytes Received from Replica/sec' --From the availability replica. Pings and status updates will generate network traffic even on databases with no user updates.
	or	counter_name = 'Bytes Sent to Replica/sec' --Sent to the remote replica. On primary, sent to the secondary replica. On secondary, sent to the primary replica.
	or	counter_name = 'Bytes Sent to Transport/sec' --Sent over the network to the remote replica. On primary, sent to the secondary replica. On secondary, sent to the primary replica.
	or	counter_name = 'Flow Control Time (ms/sec)' --Time in milliseconds that log stream messages waited for send flow control, in the last second.   
	or	counter_name = 'Receives from Replica/Sec'
	or	counter_name = 'Sends to Replica/Sec'

	)
	
insert into @tempperfmon ([object_name],counter_name,instance_name,cntr_value)
--Only valid for databases in the secondary replica role
select [object_name],counter_name,instance_name,cntr_value
from sys.dm_os_performance_counters
 where [object_name] like '%database replica%' and instance_name <> '_Total' and
	(	counter_name = 'File Bytes Received/sec' --FILESTREAM data only
	or	counter_name = 'Log Bytes Received/sec' --Amount of log records received by the secondary replica for the database in the last second.'
	or	counter_name = 'Log remaining for undo' --The amount of log in kilobytes remaining to complete the undo phase.
	)

WAITFOR DELAY '00:00:05';  --5s


--For databases both the primary and secondary, with send/receive counters reflecting the local replica
insert into @tempperfmon ([object_name],counter_name,instance_name,second_value)
select [object_name],counter_name,instance_name,cntr_value
from sys.dm_os_performance_counters
 where [object_name] like '%Availability Replica%' and instance_name <> '_Total' and
	(	counter_name = 'Bytes Received from Replica/sec' --From the availability replica. Pings and status updates will generate network traffic even on databases with no user updates.
	or	counter_name = 'Bytes Sent to Replica/sec' --Sent to the remote replica. On primary, sent to the secondary replica. On secondary, sent to the primary replica.
	or	counter_name = 'Bytes Sent to Transport/sec' --Sent over the network to the remote replica. On primary, sent to the secondary replica. On secondary, sent to the primary replica.
	or	counter_name = 'Flow Control Time (ms/sec)' --Time in milliseconds that log stream messages waited for send flow control, in the last second.   
	or	counter_name = 'Receives from Replica/Sec'
	or	counter_name = 'Sends to Replica/Sec'

	)
	
insert into @tempperfmon ([object_name],counter_name,instance_name,second_value)
--Only valid for databases in the secondary replica role
select [object_name],counter_name,instance_name,cntr_value
from sys.dm_os_performance_counters
 where [object_name] like '%database replica%' and instance_name <> '_Total' and
	(	counter_name = 'File Bytes Received/sec' --FILESTREAM data only
	or	counter_name = 'Log Bytes Received/sec' --Amount of log records received by the secondary replica for the database in the last second.'
	or	counter_name = 'Log remaining for undo' --The amount of log in kilobytes remaining to complete the undo phase.
	)

select 
[object_name],counter_name,instance_name
, Observation = (max(second_value) - max(cntr_value)) /5.
from @tempperfmon
group by [object_name],counter_name,instance_name

/*
--For databases both the primary and secondary, with send/receive counters reflecting the local replica
select object_name,counter_name,instance_name,cntr_value
from sys.dm_os_performance_counters
 where object_name like '%Availability Replica%' and instance_name <> '_Total' and
	(	counter_name = 'Bytes Received from Replica/sec' --From the availability replica. Pings and status updates will generate network traffic even on databases with no user updates.
	or	counter_name = 'Bytes Sent to Replica/sec' --Sent to the remote replica. On primary, sent to the secondary replica. On secondary, sent to the primary replica.
	or	counter_name = 'Bytes Sent to Transport/sec' --Sent over the network to the remote replica. On primary, sent to the secondary replica. On secondary, sent to the primary replica.
	or	counter_name = 'Flow Control Time (ms/sec)' --Time in milliseconds that log stream messages waited for send flow control, in the last second.   
	or	counter_name = 'Receives from Replica/Sec'
	or	counter_name = 'Sends to Replica/Sec'

	)
	

--Only valid for databases in the secondary replica role
select object_name,counter_name,instance_name,cntr_value
from sys.dm_os_performance_counters
 where object_name like '%database replica%' and instance_name <> '_Total' and
	(	counter_name = 'File Bytes Received/sec' --FILESTREAM data only
	or	counter_name = 'Log Bytes Received/sec' --Amount of log records received by the secondary replica for the database in the last second.'
	or	counter_name = 'Log remaining for undo' --The amount of log in kilobytes remaining to complete the undo phase.
	)
*/