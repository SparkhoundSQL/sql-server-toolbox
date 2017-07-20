USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'errorseverity 16', 
		@message_id=0, 
		@severity=16, 
		@enabled=1, 
		@delay_between_responses=600, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'errorseverity 16', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'errorseverity 17', 
		@message_id=0, 
		@severity=17, 
		@enabled=1, 
		@delay_between_responses=600, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'errorseverity 17', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO
EXEC msdb.dbo.sp_add_alert @name=N'errorseverity 18', 
		@message_id=0, 
		@severity=18, 
		@enabled=1, 
		@delay_between_responses=600, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'errorseverity 18', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO
EXEC msdb.dbo.sp_add_alert @name=N'errorseverity 19', 
		@message_id=0, 
		@severity=19, 
		@enabled=1, 
		@delay_between_responses=600, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'errorseverity 19', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'errorseverity 20', 
		@message_id=0, 
		@severity=20, 
		@enabled=1, 
		@delay_between_responses=600, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'errorseverity 20', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'errorseverity 21', 
		@message_id=0, 
		@severity=21, 
		@enabled=1, 
		@delay_between_responses=600, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'errorseverity 21', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'errorseverity 22', 
		@message_id=0, 
		@severity=22, 
		@enabled=1, 
		@delay_between_responses=600, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'errorseverity 22', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'errorseverity 23', 
		@message_id=0, 
		@severity=23, 
		@enabled=1, 
		@delay_between_responses=600, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'errorseverity 23', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'errorseverity 24', 
		@message_id=0, 
		@severity=24, 
		@enabled=1, 
		@delay_between_responses=600, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'errorseverity 24', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'errorseverity 25', 
		@message_id=0, 
		@severity=25, 
		@enabled=1, 
		@delay_between_responses=600, 
		@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'errorseverity 25', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO
EXEC msdb.dbo.sp_add_alert @name=N'error 3041 - backup failure', 
		@message_id=3041, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'error 3041 - backup failure', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO
/*
exec sp_MSforeachdb '
EXEC msdb.dbo.sp_add_alert @name=N''pct log used - [?] database'', 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@performance_condition=N''MSSQLSERVER:Databases|Percent Log Used|?|>|95'', 
		@job_id=N''00000000-0000-0000-0000-000000000000'';
EXEC msdb.dbo.sp_add_notification @alert_name=N''pct log used - [?] database'', @operator_name=N''sql.alerts@sparkhound.com'', @notification_method = 1'
GO
*/
EXEC msdb.dbo.sp_add_alert @name=N'error 825 - read-retry error (severity 10)', 
		@message_id=825, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'error 825 - read-retry error (severity 10)', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO


/*
EXEC msdb.dbo.sp_add_alert @name=N'deadlocks', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'SQLServer:Locks|Number of Deadlocks/sec|_Total|>|0', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'deadlocks', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO


--MSSQL$GP2k8r2

USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'buffer cache hit ratio', 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@performance_condition=N'SQLServer:Buffer Manager|Buffer cache hit ratio||<|0.8'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'buffer cache hit ratio', @operator_name=N'sql.alerts@sparkhound.com', @notification_method = 1
GO
*/