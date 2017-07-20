USE [msdb]
GO
--TODO: CHANGE THE @OperatorName variable to the correct operator name


/* *************************************************************** */ 
--Bypassing recovery for database '(null)' because it is marked as an inaccessible availability database. The session with the primary replica was interrupted while reverting the database to the common recovery point. Either the WSFC node lacks quorum or the communications links are broken because of problems with links, endpoint configuration, or permissions (for the server account or security certificate). To gain access to the database, you need to determine what has changed in the session configuration and undo the change.
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups related Error - 35273',
  @message_id=35273, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=300, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'
  GO
/* *************************************************************** */ 
--Recovery for availability database '(null)' is pending until the secondary replica receives additional transaction log from the primary before it complete and come online. Ensure that the server instance that hosts the primary replica is running.
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups related Error - 35274',
  @message_id=35274, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=300, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'
  GO 
/* *************************************************************** */ 
--A previous RESTORE WITH CONTINUE_AFTER_ERROR operation or being removed while in the SUSPECT state from an availability group left the '(null)' database in a potentially damaged state. The database cannot be joined while in this state. Restore the database, and retry the join operation.

EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups related Error - 35275',
  @message_id=35275, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=300, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'
  GO 
/* *************************************************************** */ 
--An error occurred while accessing the availability group metadata. Remove this database or replica from the availability group, and reconfigure the availability group to add the database or replica again. For more information, see the ALTER AVAILABILITY GROUP Transact-SQL statement in SQL Server Books Online.
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups related Error - 35254',
  @message_id=35254, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=300, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'
  GO 
/* *************************************************************** */ 
--The attempt to join database '(null)' to the availability group was rejected by the primary database with error '(null)'. For more information, see the SQL Server error log for the primary replica.
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups related Error - 35279',
  @message_id=35279, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=300, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'

  GO 
/* *************************************************************** */ 
--Skipping the default startup of database '(null)' because the database belongs to an availability group (Group ID:  (null)). The database will be started by the availability group. This is an informational message only. No user action is required.
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups related Error - 35262',
  @message_id=35262, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=300, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'
  GO

/* *************************************************************** */ 
--Failed to allocate and schedule an AlwaysOn Availability Groups task for database '(null)'. Manual intervention may be required to resume synchronization of the database. If the problem persists, you might need to restart the local instance of SQL Server.
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups related Error - 35276',
  @message_id=35276, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=300, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'

  GO 

DECLARE @OperatorName nvarchar(100)='sql.alerts@sparkhound.com'
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups related Error - 35273', @operator_name=@OperatorName, @notification_method = 1;
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups related Error - 35276', @operator_name=@OperatorName, @notification_method = 1;
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups related Error - 35262', @operator_name=@OperatorName, @notification_method = 1;
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups related Error - 35274', @operator_name=@OperatorName, @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups related Error - 35254', @operator_name=@OperatorName, @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups related Error - 35279', @operator_name=@OperatorName, @notification_method = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups related Error - 35275', @operator_name=@OperatorName, @notification_method = 1
  GO 

 