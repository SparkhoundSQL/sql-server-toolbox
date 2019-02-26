CREATE EVENT SESSION [test] ON SERVER 
ADD EVENT sqlserver.login,
ADD EVENT sqlserver.login_event(
    ACTION(sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.client_hostname,sqlserver.nt_username,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.session_server_principal_name,sqlserver.username))
ADD TARGET package0.event_file(SET filename=N'c:\[RenameMe].xel')
WITH (STARTUP_STATE=ON)
GO
