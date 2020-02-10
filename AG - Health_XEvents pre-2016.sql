--Recommend running on Primary replica
--Recommend TEXT mode (Ctrl+T) in SSMS

--Inspired by trayce@seekwellandprosper.com
--CASE statements to test the whether event\@timestamp is a date is because of this bug: https://blogs.msdn.microsoft.com/psssql/2015/05/04/xevent-timestamp-is-a-large-integer-value-not-the-expected-datatime-value/

--See also: toolbox\AG - Health_XEvents.sql to use features of SQL 2016 to display this data in server local time zone.
--ATTENTION! THIS query returns data in UTC!

USE [TempDB]
SET NOCOUNT ON
GO

SELECT CurrentTime_UTC = SYSUTCDATETIME()

DECLARE @XELTarget VARCHAR(MAX);
DECLARE @XELPath VARCHAR(MAX);
DECLARE @XELFile VARCHAR(max);

IF EXISTS(SELECT name FROM sys.dm_xe_sessions WHERE name = 'AlwaysOn_Health') BEGIN
	SELECT @XELTarget = cast(xet.target_data AS XML).value('(EventFileTarget/File/@name)[1]', 'VARCHAR(MAX)') 
		FROM sys.dm_xe_sessions xes
		INNER JOIN sys.dm_xe_session_targets xet
		ON xes.address = xet.event_session_address
		WHERE xet.target_name = 'event_file' and xes.name = 'AlwaysOn_Health'

	SELECT @XELPath = REVERSE(SUBSTRING(REVERSE(@XELTarget), 
			CHARINDEX('\', reverse(@XELTarget)), 
			LEN(@XELTarget)+1- CHARINDEX('\', REVERSE(@XELTarget))))

	SELECT @XELFile = @XELPath + 'AlwaysOn_health*.xel'
	IF @XELFile IS NULL BEGIN
		PRINT 'Unable to find XEVent target files for AlwaysOn_Health XEvent session'
		PRINT 'Expected AOHealth XEvent files in this location:'
		PRINT @XELPath
		RETURN
	END
END ELSE BEGIN
	PRINT 'No AlwaysOn Health XEvent session found'
	RETURN
END


--create table
DECLARE @AOHealth_XELData TABLE --CREATE TABLE @AOHealth_XELData
    (ID INT IDENTITY PRIMARY KEY CLUSTERED,
    object_name varchar(max),
    EventData XML,
    file_name varchar(max),
    file_offset bigint);

--read from the files into the table
IF @XELFile IS NOT NULL BEGIN
	INSERT INTO @AOHealth_XELData
	SELECT object_name, cast(event_data as XML) AS EventData,
	  file_name, File_Offset
	  FROM sys.fn_xe_file_target_read_file(
	  @XELFile, NULL, null, null);
END

-- Create table for "error_reported" events
DECLARE @error_reported TABLE --CREATE TABLE @error_reported 
(Xevent varchar(15),
	TimeStamp_UTC varchar(75),  --because sometimes it's a long integer because of an internal bug
	error_number INT, 
	severity INT, 
	state INT, 
	user_defined varchar(5),
	category_desc varchar(25),
	category varchar(5),
	destination varchar(20),
	destination_desc varchar(20),
	is_intercepted varchar(5),
	message varchar(max))

INSERT INTO @error_reported
SELECT  CAST(object_name as varchar(15)) AS Xevent, 
	CASE WHEN 
			ISDATE(EventData.value('(event/@timestamp)[1]', 'varchar(25)') ) =0 
			THEN NULL
			ELSE CAST(EventData.value('(event/@timestamp)[1]', 'datetimeoffset(2)') as DATETIMEOFFSET(2))
			END		
			AS TimeStamp_UTC,
    EventData.value('(event/data[@name="error_number"]/value)[1]', 'int') AS error_number,
    EventData.value('(event/data[@name="severity"]/value)[1]', 'int') AS severity,
    EventData.value('(event/data[@name="state"]/value)[1]', 'int') AS state,
    EventData.value('(event/data[@name="user_defined"]/value)[1]', 'varchar(5)') AS user_defined,
    EventData.value('(event/data[@name="category"]/text)[1]', 'varchar(25)') AS category_desc,
    EventData.value('(event/data[@name="category"]/value)[1]', 'varchar(5)') AS category,
    EventData.value('(event/data[@name="destination"]/value)[1]', 'varchar(20)') AS destination,
    EventData.value('(event/data[@name="destination"]/text)[1]', 'varchar(20)') AS destination_desc,
    EventData.value('(event/data[@name="is_intercepted"]/value)[1]', 'varchar(5)') AS is_intercepted,
    EventData.value('(event/data[@name="message"]/value)[1]', 'varchar(max)') AS message
    FROM @AOHealth_XELData
    WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'error_reported';

IF EXISTS(SELECT * FROM @error_reported) BEGIN
	PRINT 'Error event stats'
	PRINT '=================';
	--display results from "error_reported" event data
	WITH ErrorCTE (ErrorNum, ErrorCount, FirstDate_UTC, LastDate_UTC) AS (
	SELECT error_number, Count(error_number), min(TimeStamp_UTC), max(TimeStamp_UTC) As ErrorCount 
		FROM @error_reported
		GROUP BY error_number) 
	SELECT ErrorNum,
		ErrorCount,--CAST(ErrorCount as CHAR(10)) ErrorCount,
		CONVERT(datetimeoffset(2), FirstDate_UTC,121)   as FirstDate_UTC,
		CONVERT(datetimeoffset(2), LastDate_UTC, 121)   as LastDate_UTC,
			CAST(CASE ErrorNum 
			WHEN 35202 THEN 'A connection for availability group ... has been successfully established...'
			WHEN 1480 THEN 'The %S_MSG database "%.*ls" is changing roles ... because the AG failed over ...'
			WHEN 35206 THEN 'A connection timeout has occurred on a previously established connection ...'
			WHEN 35201 THEN 'A connection timeout has occurred while attempting to establish a connection ...'
			WHEN 41050 THEN 'Waiting for local WSFC service to start.'
			WHEN 41051 THEN 'Local WSFC service started.'
			WHEN 41052 THEN 'Waiting for local WSFC node to start.'
			WHEN 41053 THEN 'Local WSFC node started.'
			WHEN 41054 THEN 'Waiting for local WSFC node to come online.'
			WHEN 41055 THEN 'Local WSFC node is online.'
			WHEN 41048 THEN 'Local WSFC service has become unavailable.'
			WHEN 41049 THEN 'Local WSFC node is no longer online.'
			ELSE m.text END AS VARCHAR(81)) [Abbreviated Message]
		 FROM
		ErrorCTE ec LEFT JOIN sys.messages m on ec.ErrorNum = m.message_id
		and m.language_id = 1033
	order by LastDate_UTC DESC, ErrorCount DESC
END

IF EXISTS(SELECT object_name FROM @AOHealth_XELData WHERE object_name = 'alwayson_ddl_executed')
BEGIN
	PRINT 'Non-failover DDL Events';
	PRINT '=======================';
	WITH AODDL (object_name, TimeStamp_UTC, ddl_action, ddl_action_desc, ddl_phase, ddl_phase_desc,
		availability_group_name, availability_group_id, [statement])
	AS
	(
		SELECT  object_name, CASE WHEN 
			ISDATE(EventData.value('(event/@timestamp)[1]', 'varchar(25)') ) =0 
			THEN NULL
			ELSE CAST(EventData.value('(event/@timestamp)[1]', 'datetimeoffset(2)') as DATETIMEOFFSET(2))
			END			 
			AS TimeStamp_UTC,
		EventData.value('(event/data[@name="ddl_action"]/value)[1]', 'int') AS ddl_action,
		EventData.value('(event/data[@name="ddl_action"]/text)[1]', 'varchar(15)') AS ddl_action_desc,
		EventData.value('(event/data[@name="ddl_phase"]/value)[1]', 'int') AS ddl_phase,
		EventData.value('(event/data[@name="ddl_phase"]/text)[1]', 'varchar(10)') AS ddl_phase_desc,
		EventData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(25)') AS availability_group_name,
		EventData.value('(event/data[@name="availability_group_id"]/value)[1]', 'varchar(36)') AS availability_group_id,
		EventData.value('(event/data[@name="statement"]/value)[1]', 'varchar(max)') AS [statement]
		FROM @AOHealth_XELData
		WHERE object_name = 'alwayson_ddl_executed'
			AND EventData.value('(event/data[@name="statement"]/value)[1]', 'varchar(max)') NOT LIKE '%FAILOVER%'
			OR (EventData.value('(event/data[@name="statement"]/value)[1]', 'varchar(max)') LIKE '%FAILOVER%' AND
					EventData.value('(event/data[@name="statement"]/value)[1]', 'varchar(max)') LIKE '%CREATE%')
	)
	SELECT cast(object_name as varchar(22)) AS XEvent, TimeStamp_UTC, ddl_action, ddl_action_desc, ddl_phase,
		ddl_phase_desc, availability_group_name, availability_group_id, 
		CASE WHEN LEN([statement]) > 220
		THEN CAST([statement] as varchar(1155)) + char(10) 
		ELSE CAST(Replace([statement], char(10), '') as varchar(220)) 
		END as [statement]
		FROM AODDL
		ORDER BY TimeStamp_UTC desc;


	PRINT 'Failover DDL Events';
	PRINT '===================';
	-- Display results "alwayson_ddl_executed" events
	WITH AODDL (object_name, TimeStamp_UTC, ddl_action, ddl_action_desc, ddl_phase, ddl_phase_desc,
		availability_group_name, availability_group_id, [statement])
	AS
	(
		SELECT  object_name, CASE WHEN 
			ISDATE(EventData.value('(event/@timestamp)[1]', 'varchar(25)') ) =0 
			THEN NULL
			ELSE CAST(EventData.value('(event/@timestamp)[1]', 'datetimeoffset(2)') as DATETIMEOFFSET(2))
			END			 
			AS TimeStamp_UTC,
		EventData.value('(event/data[@name="ddl_action"]/value)[1]', 'int') AS ddl_action,
		EventData.value('(event/data[@name="ddl_action"]/text)[1]', 'varchar(15)') AS ddl_action_desc,
		EventData.value('(event/data[@name="ddl_phase"]/value)[1]', 'int') AS ddl_phase,
		EventData.value('(event/data[@name="ddl_phase"]/text)[1]', 'varchar(10)') AS ddl_phase_desc,
		EventData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(25)') AS availability_group_name,
		EventData.value('(event/data[@name="availability_group_id"]/value)[1]', 'varchar(36)') AS availability_group_id,
		EventData.value('(event/data[@name="statement"]/value)[1]', 'varchar(max)') AS [statement]
		FROM @AOHealth_XELData
		WHERE object_name = 'alwayson_ddl_executed'
			AND (EventData.value('(event/data[@name="statement"]/value)[1]', 'varchar(max)') LIKE '%FAILOVER%'
					OR EventData.value('(event/data[@name="statement"]/value)[1]', 'varchar(max)') LIKE '%FORCE%')
			AND EventData.value('(event/data[@name="statement"]/value)[1]', 'varchar(max)') NOT LIKE '%CREATE%'
	)
	SELECT cast(object_name as varchar(22)) AS XEvent, TimeStamp_UTC, ddl_action, ddl_action_desc, ddl_phase,
		ddl_phase_desc, availability_group_name, availability_group_id, 
		CAST(Replace([statement], char(10), '') as varchar(80)) as [statement]
		FROM AODDL
		ORDER BY TimeStamp_UTC desc;
END

IF EXISTS(SELECT object_name FROM @AOHealth_XELData WHERE object_name = 'availability_replica_manager_state_change')
BEGIN
	PRINT 'Availability Replica Manager state changes'
	PRINT '==========================================';
	-- display results for "availability_replica_manager_state_change" events
	SELECT cast(object_name as varchar(42)) AS XEvent, CASE WHEN 
			ISDATE(EventData.value('(event/@timestamp)[1]', 'varchar(25)') ) =0 
			THEN NULL
			ELSE CAST(EventData.value('(event/@timestamp)[1]', 'datetimeoffset(2)') as DATETIMEOFFSET(2))
			END			 
			AS TimeStamp_UTC,
		EventData.value('(event/data[@name="current_state"]/value)[1]', 'int') AS current_state,
		EventData.value('(event/data[@name="current_state"]/text)[1]', 'varchar(30)') AS current_state_desc
		FROM @AOHealth_XELData
		WHERE object_name = 'availability_replica_manager_state_change'
		ORDER BY TimeStamp_UTC desc;
END


IF EXISTS(SELECT object_name FROM @AOHealth_XELData WHERE object_name = 'availability_replica_state')
BEGIN
	PRINT 'Availability Replica state'
	PRINT '==========================';
	-- display results for "availability_replica_state" events
	SELECT cast(object_name as varchar(34)) AS XEvent, CASE WHEN 
			ISDATE(EventData.value('(event/@timestamp)[1]', 'varchar(25)') ) =0 
			THEN NULL
			ELSE CAST(EventData.value('(event/@timestamp)[1]', 'datetimeoffset(2)') as DATETIMEOFFSET(2))
			END		 
			AS TimeStamp_UTC,
		EventData.value('(event/data[@name="current_state"]/value)[1]', 'int') AS current_state,
		EventData.value('(event/data[@name="current_state"]/text)[1]', 'varchar(20)') AS current_state_desc,
		EventData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(36)') AS availability_group_name,
		EventData.value('(event/data[@name="availability_group_id"]/value)[1]', 'varchar(36)') AS availability_group_id,
		EventData.value('(event/data[@name="availability_replica_id"]/value)[1]', 'varchar(36)') AS availability_replica_id
		FROM @AOHealth_XELData
		WHERE object_name = 'availability_replica_state'
		ORDER BY TimeStamp_UTC desc;
END

IF EXISTS(SELECT object_name FROM @AOHealth_XELData WHERE object_name = 'availability_replica_state_change')
BEGIN
	PRINT 'Availability Replica state changes'
	PRINT '==================================';
	-- display results for "availability_replica_state_change" events
	SELECT cast(object_name as varchar(34)) AS XEvent, CASE WHEN 
			ISDATE(EventData.value('(event/@timestamp)[1]', 'varchar(25)') ) =0 
			THEN NULL
			ELSE CAST(EventData.value('(event/@timestamp)[1]', 'datetimeoffset(2)') as DATETIMEOFFSET(2))
			END			 
			AS TimeStamp_UTC,
		IsNULL(EventData.value('(event/data[@name="availability_replica_name"]/value)[1]', 'varchar(25)'), 'Data Unavailable') AS availability_replica_name,
		EventData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(25)') AS availability_group_name,
		EventData.value('(event/data[@name="previous_state"]/value)[1]', 'int') AS previous_state,
		EventData.value('(event/data[@name="previous_state"]/text)[1]', 'varchar(30)') AS previous_state_desc,
		EventData.value('(event/data[@name="current_state"]/value)[1]', 'int') AS current_state,
		EventData.value('(event/data[@name="current_state"]/text)[1]', 'varchar(30)') AS current_state_desc,
		EventData.value('(event/data[@name="availability_replica_id"]/value)[1]', 'varchar(36)') AS availability_replica_id,
		EventData.value('(event/data[@name="availability_group_id"]/value)[1]', 'varchar(36)') AS availability_group_id
		FROM @AOHealth_XELData
		WHERE object_name = 'availability_replica_state_change'
		ORDER BY TimeStamp_UTC DESC;
END

IF EXISTS(SELECT object_name FROM @AOHealth_XELData WHERE object_name = 'availability_group_lease_expired')
BEGIN
	PRINT 'Lease Expiration Events'
	PRINT '=======================';
	-- Display results "lease expiration" events
	SELECT  cast(object_name as varchar(33)) AS XEvent, CASE WHEN 
			ISDATE(EventData.value('(event/@timestamp)[1]', 'varchar(25)') ) =0 
			THEN NULL
			ELSE CAST(EventData.value('(event/@timestamp)[1]', 'datetimeoffset(2)') as DATETIMEOFFSET(2))
			END			 
			AS TimeStamp_UTC,
		EventData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(25)') AS AGName,
		EventData.value('(event/data[@name="availability_group_id"]/value)[1]', 'varchar(36)') AS AG_ID
		FROM @AOHealth_XELData
		WHERE object_name = 'availability_group_lease_expired'
		ORDER BY TimeStamp_UTC desc;
END

IF EXISTS(SELECT object_name FROM @AOHealth_XELData WHERE object_name = 'lock_redo_blocked')
BEGIN
	PRINT 'BLOCKED REDO Events'
	PRINT '===================';
	-- Display results "lock_redo_blocked" events
		SELECT cast(object_name as varchar(42)) AS XEvent, CASE WHEN 
			ISDATE(EventData.value('(event/@timestamp)[1]', 'varchar(25)') ) =0 
			THEN NULL
			ELSE CAST(EventData.value('(event/@timestamp)[1]', 'datetimeoffset(2)') as DATETIMEOFFSET(2))
			END	 
			AS TimeStamp_UTC,
		EventData.value('(event/data[@name="resource_type"]/value)[1]', 'int') AS ResourceType,
		EventData.value('(event/data[@name="resource_type"]/text)[1]', 'varchar(25)') AS ResourceTypeDesc,
		EventData.value('(event/data[@name="mode"]/value)[1]', 'int') AS Mode,
		EventData.value('(event/data[@name="mode"]/text)[1]', 'varchar(25)') AS ModeDesc,
		EventData.value('(event/data[@name="owner_type"]/value)[1]', 'int') AS OwnerType,
		EventData.value('(event/data[@name="owner_type"]/text)[1]', 'varchar(25)') AS OwnerTypeDesc,
		EventData.value('(event/data[@name="transaction_id"]/value)[1]', 'bigint') AS transaction_id,
		EventData.value('(event/data[@name="database_id"]/value)[1]', 'int') AS database_id,
		EventData.value('(event/data[@name="lockspace_workspace_id"]/value)[1]', 'varchar(22)') AS lockspace_workspace_id,
		EventData.value('(event/data[@name="lockspace_sub_id"]/value)[1]', 'bigint') AS lockspace_sub_id,
		EventData.value('(event/data[@name="lockspace_nest_id"]/value)[1]', 'bigint') AS lockspace_nest_id,
		EventData.value('(event/data[@name="resource_0"]/value)[1]', 'bigint') AS resource_0,
		EventData.value('(event/data[@name="resource_1"]/value)[1]', 'bigint') AS resource_1,
		EventData.value('(event/data[@name="resource_2"]/value)[1]', 'bigint') AS resource_2,
		EventData.value('(event/data[@name="object_id"]/value)[1]', 'bigint') AS [object_id],
		EventData.value('(event/data[@name="associated_object_id"]/value)[1]', 'bigint') AS associated_object_id,
		EventData.value('(event/data[@name="duration"]/value)[1]', 'int') AS duration,
		EventData.value('(event/data[@name="resource_description"]/value)[1]', 'varchar(25)') AS resource_description
		FROM @AOHealth_XELData
		WHERE object_name = 'lock_redo_blocked'
		ORDER BY TimeStamp_UTC desc;
END

IF EXISTS(SELECT object_name FROM @AOHealth_XELData WHERE object_name = 'hadr_db_partner_set_sync_state')
BEGIN
	PRINT 'hadr_db_partner_set_sync_state Events'
	PRINT '=====================================';
	-- Display results "hadr_db_partner_set_sync_state" events
	   SELECT cast(object_name as varchar(42)) AS XEvent, CASE WHEN 
			ISDATE(EventData.value('(event/@timestamp)[1]', 'varchar(25)') ) =0 
			THEN NULL
			ELSE CAST(EventData.value('(event/@timestamp)[1]', 'datetimeoffset(2)') as DATETIMEOFFSET(2))
			END	 
			AS TimeStamp_UTC,
			EventData.value('(event/data[@name="database_id"]/value)[1]', 'int') AS database_id,
			EventData.value('(event/data[@name="commit_policy"]/value)[1]', 'int') AS commit_policy,
			EventData.value('(event/data[@name="commit_policy"]/text)[1]', 'varchar(20)') AS commit_policy_desc,
			EventData.value('(event/data[@name="commit_policy_target"]/value)[1]', 'int') AS commit_policy_target,
			EventData.value('(event/data[@name="commit_policy_target"]/text)[1]', 'varchar(20)') AS commit_policy_target_desc,
			EventData.value('(event/data[@name="sync_state"]/value)[1]', 'int') AS sync_state,
			EventData.value('(event/data[@name="sync_state"]/text)[1]', 'varchar(20)') AS sync_state_desc,
			EventData.value('(event/data[@name="sync_log_block"]/value)[1]', 'varchar(20)') AS sync_log_block,
			EventData.value('(event/data[@name="group_id"]/value)[1]', 'varchar(36)') AS group_id,
			EventData.value('(event/data[@name="replica_id"]/value)[1]', 'varchar(36)') AS replica_id,
			EventData.value('(event/data[@name="ag_database_id"]/value)[1]', 'varchar(36)') AS ag_database_id
		FROM @AOHealth_XELData
		WHERE object_name = 'hadr_db_partner_set_sync_state'
		ORDER BY TimeStamp_UTC desc;
END

IF EXISTS(SELECT object_name FROM @AOHealth_XELData WHERE object_name = 'availability_replica_automatic_failover_validation')
BEGIN
	PRINT 'availability_replica_automatic_failover_validation'
	PRINT '==================================================';
	-- Display results "availability_replica_automatic_failover_validation" events
	   SELECT cast(object_name as varchar(50)) AS XEvent, CASE WHEN 
			ISDATE(EventData.value('(event/@timestamp)[1]', 'varchar(25)') ) =0 
			THEN NULL
			ELSE CAST(EventData.value('(event/@timestamp)[1]', 'datetimeoffset(2)') as DATETIMEOFFSET(2))
			END	
			AS TimeStamp_UTC,
		EventData.value('(event/data[@name="availability_replica_name"]/value)[1]', 'varchar(25)') AS availability_replica_name,
		EventData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(25)') AS availability_group_name,
		EventData.value('(event/data[@name="availability_replica_id"]/value)[1]', 'varchar(36)') AS availability_replica_id,
		EventData.value('(event/data[@name="availability_group_id"]/value)[1]', 'varchar(36)') AS availability_group_id,
		EventData.value('(event/data[@name="forced_quorum"]/value)[1]', 'varchar(5)') AS forced_quorum,
		EventData.value('(event/data[@name="joined_and_synchronized"]/value)[1]', 'varchar(5)') AS joined_and_synchronized,
		EventData.value('(event/data[@name="previous_primary_or_automatic_failover_target"]/value)[1]', 'varchar(5)') AS previous_primary_or_automatic_failover_target
		FROM @AOHealth_XELData
		WHERE object_name = 'availability_replica_automatic_failover_validation'
		ORDER BY TimeStamp_UTC desc;
END

DECLARE @AOHealthSummary TABLE --CREATE TABLE @AOHealthSummary 
(XEvent varchar(50), [COUNT] INT);
INSERT INTO @AOHealthSummary 
SELECT CAST(xv.event_name AS VARCHAR(50)), 0
	FROM sys.dm_xe_sessions xes
	INNER JOIN sys.dm_xe_session_events xv ON xes.address = xv.event_session_address
	WHERE xes.name like 'AlwaysOn_Health'
	ORDER BY event_name;

With Summary (XEvent, [Count])
AS (SELECT CAST(object_name AS VARCHAR(50)) AS [XEvent], count(*) AS [Count] 
	FROM @AOHealth_XELData
	GROUP BY object_name)
UPDATE @AOHealthSummary
	SET [COUNT] = s.[COUNT] 
	FROM Summary s
	INNER JOIN @AOHealthSummary ao ON s.XEvent = ao.XEvent;

IF EXISTS(SELECT * FROM @AOHealthSummary) BEGIN
	PRINT 'Summary event counts for AO Health XEvents'
	PRINT '==========================================';
	-- Display event counts for AO Health XEvent data
	SELECT * FROM @AOHealthSummary
	ORDER BY [count] DESC, XEvent
END

GO