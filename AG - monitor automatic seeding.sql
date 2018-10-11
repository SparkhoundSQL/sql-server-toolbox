-- Monitor automatic seeding
USE master;
GO
SELECT s.local_database_name, s.role_desc, s.internal_state_desc, s.transfer_rate_bytes_per_second, s.transferred_size_bytes, s.database_size_bytes, s.start_time_utc, s.end_time_utc, s.estimate_time_complete_utc, s.total_disk_io_wait_time_ms, s.total_network_wait_time_ms, s.failure_message, s.failure_time_utc, s.is_compression_enabled
FROM sys.dm_hadr_physical_seeding_stats s
ORDER BY start_time_utc desc

-- Automatic seeding History
USE master;
GO

SELECT TOP 10 ag.name, dc.database_name, s.start_time, s.completion_time, s.current_state, s.performed_seeding, s.failure_state_desc, s.error_code, s.number_of_attempts
FROM sys.dm_hadr_automatic_seeding s
	INNER JOIN sys.availability_databases_cluster dc ON s.ag_db_id = dc.group_database_id
	INNER JOIN sys.availability_groups ag ON s.ag_id = ag.group_id
ORDER BY start_time desc;