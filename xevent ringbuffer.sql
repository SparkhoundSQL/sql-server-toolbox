WITH CteRingBuffer (XMLData) as
( SELECT CAST(xet.target_data as XML) as XMLData 
  FROM sys.dm_xe_session_targets xet INNER JOIN
       sys.dm_xe_sessions xe ON (xe.address = xet.event_session_address)
WHERE xe.name = 'system_health' )
SELECT top 100 e.query('.').value('(/event/@timestamp)[1]', 'datetime2(0)') as "TimeStamp",
       e.query('.').value('(/event/data/value)[1]', 'int') as "ErrorNumber",
    e.query('.').value('(/event/data/value)[2]', 'int') as "ErrorSeverity",
    e.query('.').value('(/event/data/value)[3]', 'int') as "ErrorState",
    e.query('.').value('(/event/data/value)[5]', 'varchar(max)') as "ErrorMessage"
 FROM  cteRingBuffer CROSS APPLY 
       XMLData.nodes('/RingBufferTarget/event') AS Event(e)
 WHERE e.query('.').value('(/event/@name)[1]', 'varchar(255)') = 'error_reported'
   AND e.query('.').value('(/event/@timestamp)[1]', 'datetime2(0)') > GETDATE()-14
 