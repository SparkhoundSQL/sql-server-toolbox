CREATE EVENT SESSION [CollectLogonData] ON SERVER 
ADD EVENT sqlserver.login(
    ACTION(sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.server_principal_sid,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.username)) 
ADD TARGET package0.event_file(SET filename=N'c:\[RenameMe]\CollectLogindata.xel')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO

ALTER EVENT SESSION [CollectLogonData] on server STATE = START
--ALTER EVENT SESSION [CollectLogonData] on server STATE = STOP