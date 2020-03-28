--Sometimes it is easier to query the SSISDB directly instead of using SSMS reports.
--Can also be the foundation for custom dashboards, error notifications, etc.
USE SSISDB 

--Example 1: Query for recent errors
SELECT 
  om.message 
, om.message_time
, em.execution_path
, em.package_name
, em.event_name
, em.message_source_name
, o.start_time
, o.end_time
, o.caller_name
, o.server_name
, o.machine_name
, *
  FROM [SSISDB].internal.event_messages em
  inner join ssisdb.internal.operations o on em.operation_id =o.operation_id
  inner join ssisdb.internal.operation_messages om on om.operation_message_id = em.event_message_id
  WHERE  om.message_time >= dateadd(day, -1, sysdatetime())
  and event_name = 'OnError'
  ORDER BY  om.message_time desc, o.operation_id, em.event_message_id;

--Example 2: Query for rowcounts from a specific data flow over time
SELECT 
  om.message 
, om.message_time
, em.execution_path
, em.package_name
, em.event_name
, em.message_source_name
, o.start_time
, o.end_time
, o.caller_name
, o.server_name
, o.machine_name
, *
  FROM [SSISDB].internal.event_messages em
  inner join ssisdb.internal.operations o on em.operation_id =o.operation_id
  inner join ssisdb.internal.operation_messages om on om.operation_message_id = em.event_message_id
  WHERE  om.message_time >= dateadd(day, -3, sysdatetime())
  and event_name in ('OnInformation', 'OnProgress')
  and message like '%DataFlowName%rows%'
  and execution_path = '\Package\Package\Sequence\Data Flow\'
  ORDER BY  om.message_time desc, o.operation_id, em.event_message_id;