-------------------------------------------------------------------------------------------------------
----			 SQL Server Memory Dumps
----				Are their any recent SQL mini dumps
-------------------------------------------------------------------------------------------------------

SELECT [filename], creation_time, size_in_bytes/1048576.0 AS [Size (MB)]
FROM sys.dm_server_memory_dumps WITH (NOLOCK) 
ORDER BY creation_time DESC OPTION (RECOMPILE);