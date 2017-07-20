 
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
  where o.operation_id = 10205
  order by o.operation_id, em.event_message_id