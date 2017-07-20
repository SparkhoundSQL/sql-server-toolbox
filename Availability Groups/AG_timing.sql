
;WITH AG_Stats AS (
            SELECT AGS.name                       AS AGGroupName, 
                   AR.replica_server_name         AS InstanceName, 
                   HARS.role_desc, 
                   Db_name(DRS.database_id)       AS DBName, 
                   DRS.database_id, 
                   AR.availability_mode_desc      AS SyncMode, 
                   DRS.synchronization_state_desc AS SyncState, 
                   DRS.last_hardened_lsn, 
                   DRS.end_of_log_lsn, 
                   DRS.last_redone_lsn, 
                   DRS.last_hardened_time, -- On a secondary database, time of the log-block identifier for the last hardened LSN (last_hardened_lsn).
                   DRS.last_redone_time, -- Time when the last log record was redone on the secondary database.
                   DRS.log_send_queue_size, 
                   DRS.redo_queue_size,
				   Redo_Time_Left_s = DRS.redo_queue_size/DRS.redo_rate,
                   DRS.last_commit_time -- select *
            FROM   sys.dm_hadr_database_replica_states DRS 
            LEFT JOIN sys.availability_replicas AR 
            ON DRS.replica_id = AR.replica_id 
            LEFT JOIN sys.availability_groups AGS 
            ON AR.group_id = AGS.group_id 
            LEFT JOIN sys.dm_hadr_availability_replica_states HARS ON AR.group_id = HARS.group_id 
            AND AR.replica_id = HARS.replica_id 
            ),
    Pri_CommitTime AS 
            (
            SELECT  DBName
                    , last_commit_time
            FROM    AG_Stats
            WHERE   role_desc = 'PRIMARY'
            ),
    Rpt_CommitTime AS 
            (
            SELECT  DBName, last_commit_time
            FROM    AG_Stats
            WHERE   role_desc = 'SECONDARY' AND [InstanceName] = 'SQLSERVER-1'
            ),
    FO_CommitTime AS 
            (
            SELECT  DBName, last_commit_time
            FROM    AG_Stats
            WHERE   role_desc = 'SECONDARY' AND ([InstanceName]in ( 'SQLSERVER-0') )
            )
SELECT p.[DBName] AS [DatabaseName]
	, a.AGGroupName
	, a.InstanceName
	, a.role_desc
	, a.SyncMode
	, a.SyncState
	, a.Redo_Time_Left_s
	, p.last_commit_time AS [Primary_Last_Commit_Time]
    , r.last_commit_time AS [Reporting_Last_Commit_Time]
    , DATEDIFF(ss,r.last_commit_time,p.last_commit_time) AS [Reporting_Sync_Lag_(secs)]
    , f.last_commit_time AS [FailOver_Last_Commit_Time]
    , DATEDIFF(ss,f.last_commit_time,p.last_commit_time) AS [FailOver_Sync_Lag_(secs)]
FROM AG_Stats a
INNER JOIN Pri_CommitTime p ON p.DBName = a.DBName
LEFT JOIN Rpt_CommitTime r ON [r].[DBName] = [p].[DBName]
LEFT JOIN FO_CommitTime f ON [f].[DBName] = [p].[DBName]

--stolen from http://dba.stackexchange.com/questions/60624/check-the-data-latency-between-two-always-on-availability-group-servers-in-async