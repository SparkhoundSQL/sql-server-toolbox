-- Get information on location, time and size of any memory dumps from SQL Server  
-- Only SQL 2008R2+
SELECT [filename], creation_time, size_in_bytes/1048576.0 AS [Size (MB)]
FROM sys.dm_server_memory_dumps 
ORDER BY creation_time DESC OPTION (RECOMPILE);