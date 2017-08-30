-- This works for SQL 2008 R2 SP1 and above only
SELECT servicename -- Ex: SQL Server (SQL2K8R2)
, startup_type_desc -- Manual, Automatic
, status_desc -- Running, Stopped, etc.
, process_id
, last_startup_time -- datetime
, service_account
, filename
, is_clustered -- Y/N
, cluster_nodename
FROM sys.dm_server_services

--The Browser is NOT listed


/*
-- This works prior to SQL 2008 R2 SP1 
DECLARE @DBEngineLogin VARCHAR(100)
DECLARE @AgentLogin VARCHAR(100)
EXECUTE master.dbo.xp_instance_regread
@rootkey = N'HKEY_LOCAL_MACHINE',
@key = N'SYSTEM\CurrentControlSet\Services\MSSQLServer',
@value_name = N'ObjectName',
@value = @DBEngineLogin OUTPUT
EXECUTE master.dbo.xp_instance_regread
@rootkey = N'HKEY_LOCAL_MACHINE',
@key = N'SYSTEM\CurrentControlSet\Services\SQLServerAgent',
@value_name = N'ObjectName',
@value = @AgentLogin OUTPUT
SELECT [DBEngineLogin] = @DBEngineLogin, [AgentLogin] = @AgentLogin
GO
　
*/

