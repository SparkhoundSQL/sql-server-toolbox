--Use to configure the blocked process report and an xevent session to capture blocking chains
--Not recommended for permanent use

EXEC sp_configure 'show advanced options', 1 ;
GO
RECONFIGURE;
GO
/* Enabled the blocked process report */
EXEC sp_configure 'blocked process threshold', '10'; --seconds blocked that trigger report
RECONFIGURE;
GO

CREATE EVENT SESSION [blocked_process] ON SERVER
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name)) ,
ADD EVENT sqlserver.xml_deadlock_report (
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name))
ADD TARGET package0.asynchronous_file_target
(SET filename = N'c:\temp\SQLDiagnosticXEventSessions\blocked_process.xel',
     metadatafile = N'c:\temp\SQLDiagnosticXEventSessions\blocked_process.xem',
     max_file_size=(1024), --MB
     max_rollover_files=5) --max_file_size * 5
WITH (MAX_DISPATCH_LATENCY = 5SECONDS)
GO
  
/* Start the Extended Events session */
ALTER EVENT SESSION [blocked_process] ON SERVER
STATE = START;

/* --Later on, Read the captured blocking chains */

WITH events_cte AS (
  SELECT
    xevents.event_data,
    DATEADD(mi,
    DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),
    xevents.event_data.value(
      '(event/@timestamp)[1]', 'datetime2')) AS [event time] ,
    xevents.event_data.value(
      '(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(128)')
      AS [client app name],
    xevents.event_data.value(
      '(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(max)')
      AS [client host name],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="database_name"]/value)[1]', 'nvarchar(max)')
      AS [database name],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="database_id"]/value)[1]', 'int')
      AS [database_id],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="object_id"]/value)[1]', 'int')
      AS [object_id],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="index_id"]/value)[1]', 'int')
      AS [index_id],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="duration"]/value)[1]', 'bigint') / 1000
      AS [duration (ms)],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="lock_mode"]/text)[1]', 'varchar')
      AS [lock_mode],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="login_sid"]/value)[1]', 'int')
      AS [login_sid],
    xevents.event_data.query(
      '(event[@name="blocked_process_report"]/data[@name="blocked_process"]/value/blocked-process-report)[1]')
      AS blocked_process_report,
    xevents.event_data.query(
      '(event/data[@name="xml_report"]/value/deadlock)[1]')
      AS deadlock_graph
  FROM    sys.fn_xe_file_target_read_file
    ('C:\temp\SQLDiagnosticXEventSessions\blocked_process*.xel',
     'C:\temp\SQLDiagnosticXEventSessions\blocked_process*.xem',
     null, null)
    CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) as xevents
)
SELECT
  CASE WHEN blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NULL
       THEN 'Deadlock'
       ELSE 'Blocked Process'
       END AS ReportType,
  [event time],
  CASE [client app name] WHEN '' THEN ' -- N/A -- '
                         ELSE [client app name]
                         END AS [client app _name],
  CASE [client host name] WHEN '' THEN ' -- N/A -- '
                          ELSE [client host name]
                          END AS [client host name],
  [database name],
  COALESCE(OBJECT_SCHEMA_NAME(object_id, database_id), ' -- N/A -- ') AS [schema],
  COALESCE(OBJECT_NAME(object_id, database_id), ' -- N/A -- ') AS [table],
  index_id,
  [duration (ms)],
  lock_mode,
  COALESCE(SUSER_NAME(login_sid), ' -- N/A -- ') AS username,
  CASE WHEN blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NULL
       THEN deadlock_graph
       ELSE blocked_process_report
       END AS Report
FROM events_cte
ORDER BY [event time] DESC ;


--Source Reference: https://www.brentozar.com/archive/2014/03/extended-events-doesnt-hard/