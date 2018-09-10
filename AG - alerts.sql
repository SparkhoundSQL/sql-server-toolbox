USE [msdb]
GO
--TODO: CHANGE THE @OperatorName variable to the correct operator name


/* *************************************************************** */ 
--Bypassing recovery for database '(null)' because it is marked as an inaccessible availability database. The session with the primary replica was interrupted while reverting the database to the common recovery point. Either the WSFC node lacks quorum or the communications links are broken because of problems with links, endpoint configuration, or permissions (for the server account or security certificate). To gain access to the database, you need to determine what has changed in the session configuration and undo the change.
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups Error - 35273 - bypassing recovery',
  @message_id=35273, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=60, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'
  GO
/* *************************************************************** */ 
--Recovery for availability database '(null)' is pending until the secondary replica receives additional transaction log from the primary before it complete and come online. Ensure that the server instance that hosts the primary replica is running.
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups Error - 35274 - recovery pending',
  @message_id=35274, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=60, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'
  GO 
/* *************************************************************** */ 
--A previous RESTORE WITH CONTINUE_AFTER_ERROR operation or being removed while in the SUSPECT state from an availability group left the '(null)' database in a potentially damaged state. The database cannot be joined while in this state. Restore the database, and retry the join operation.

EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups Error - 35275 - database potentially damaged',
  @message_id=35275, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=60, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'
  GO 
/* *************************************************************** */ 
--An error occurred while accessing the availability group metadata. Remove this database or replica from the availability group, and reconfigure the availability group to add the database or replica again. For more information, see the ALTER AVAILABILITY GROUP Transact-SQL statement in SQL Server Books Online.
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups Error - 35254 - metadata error',
  @message_id=35254, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=60, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'
  GO 
/* *************************************************************** */ 
--The attempt to join database '(null)' to the availability group was rejected by the primary database with error '(null)'. For more information, see the SQL Server error log for the primary replica.
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups Error - 35279 - join rejected',
  @message_id=35279, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=60, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'

/* *************************************************************** */ 
--Failed to allocate and schedule an AlwaysOn Availability Groups task for database '(null)'. Manual intervention may be required to resume synchronization of the database. If the problem persists, you might need to restart the local instance of SQL Server.
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups Error - 35276 - failed to allocate database',
  @message_id=35276, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=60, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'

  GO 

  /* *************************************************************** */ 
--AlwaysOn Availability Groups data movement for database has been suspended for the following reason: "%S_MSG" 
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups Error - 35264 - data movement suspended',
  @message_id=35264, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=60, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'

  GO 
    /* *************************************************************** */ 
--AlwaysOn Availability Groups data movement for database has been resumed 
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups Error - 35265 - data movement resumed',
  @message_id=35265, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=60, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'

  GO 

      /* *************************************************************** */ 
--AlwaysOn Availability Groups offline
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups Error - 41404 - AG offline',
  @message_id=41404, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=60, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'

  GO 

      
--AlwaysOn Availability Groups no longer ready for automatic failover
EXEC msdb.dbo.sp_add_alert @name=N'Availability Groups Error - 41405 - not ready for automatic failover',
  @message_id=41405, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses=60, 
  @include_event_description_in=1, 
  @job_id=N'00000000-0000-0000-0000-000000000000'

  GO 
  
      


DECLARE @OperatorName nvarchar(100)='DBAResponse' --TODO: change
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups Error - 35273 - bypassing recovery', @operator_name=@OperatorName, @notification_method = 1;
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups Error - 35276 - failed to allocate database', @operator_name=@OperatorName, @notification_method = 1;
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups Error - 35274 - recovery pending', @operator_name=@OperatorName, @notification_method = 1;
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups Error - 35254 - metadata error', @operator_name=@OperatorName, @notification_method = 1;
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups Error - 35279 - join rejected', @operator_name=@OperatorName, @notification_method = 1;
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups Error - 35275 - database potentially damaged', @operator_name=@OperatorName, @notification_method = 1;
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups Error - 35264 - data movement suspended', @operator_name=@OperatorName, @notification_method = 1;
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups Error - 35265 - data movement resumed', @operator_name=@OperatorName, @notification_method = 1;
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups Error - 41404 - AG offline', @operator_name=@OperatorName, @notification_method = 1;
EXEC msdb.dbo.sp_add_notification @alert_name=N'Availability Groups Error - 41405 - not ready for automatic failover', @operator_name=@OperatorName, @notification_method = 1;
GO 

 