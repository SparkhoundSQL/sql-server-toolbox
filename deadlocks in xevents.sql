

declare @xml xml
select @xml = CAST(t.target_data as xml)
from sys.dm_xe_session_targets t
inner join sys.dm_xe_sessions s
	on s.address = t.event_session_address
	where s.name = 'system_health'
	and t.target_name = 'ring_buffer'
select @xml.query('/RingBufferTarget/event [@name="xml_deadlock_report"]')
FOR XML PATH ('XEvent')

go



/*
--alternative version for SQL 2016
--http://www.sqlservercentral.com/blogs/simple-sql-server/2016/01/25/querying-deadlocks-from-system_health-xevent/

DECLARE @SessionName SysName 

SELECT @SessionName = 'system_health'

/* 
SELECT  Session_Name = s.name, s.blocked_event_fire_time, s.dropped_buffer_count, s.dropped_event_count, s.pending_buffers
FROM sys.dm_xe_session_targets t
	INNER JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address
WHERE target_name = 'event_file'
--*/

IF OBJECT_ID('tempdb..#Events') IS NOT NULL BEGIN
	DROP TABLE #Events
END

DECLARE @Target_File NVarChar(1000)
	, @Target_Dir NVarChar(1000)
	, @Target_File_WildCard NVarChar(1000)

SELECT @Target_File = CAST(t.target_data as XML).value('EventFileTarget[1]/File[1]/@name', 'NVARCHAR(256)')
FROM sys.dm_xe_session_targets t
	INNER JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address
WHERE s.name = @SessionName
	AND t.target_name = 'event_file'

SELECT @Target_Dir = LEFT(@Target_File, Len(@Target_File) - CHARINDEX('\', REVERSE(@Target_File))) 

SELECT @Target_File_WildCard = @Target_Dir + '\'  + @SessionName + '_*.xel'

--Keep this as a separate table because it's called twice in the next query.  You don't want this running twice.
SELECT DeadlockGraph = CAST(event_data AS XML)
	, DeadlockID = Row_Number() OVER(ORDER BY file_name, file_offset)
INTO #Events
FROM sys.fn_xe_file_target_read_file(@Target_File_WildCard, null, null, null) AS F
WHERE event_data like '<event name="xml_deadlock_report%'

;WITH Victims AS
(
	SELECT VictimID = Deadlock.Victims.value('@id', 'varchar(50)')
		, e.DeadlockID 
	FROM #Events e
		CROSS APPLY e.DeadlockGraph.nodes('/event/data/value/deadlock/victim-list/victimProcess') as Deadlock(Victims)
)
, DeadlockObjects AS
(
	SELECT DISTINCT e.DeadlockID
		, ObjectName = Deadlock.Resources.value('@objectname', 'nvarchar(256)')
	FROM #Events e
		CROSS APPLY e.DeadlockGraph.nodes('/event/data/value/deadlock/resource-list/*') as Deadlock(Resources)
)
SELECT *
FROM
(
	SELECT e.DeadlockID
		, TransactionTime = Deadlock.Process.value('@lasttranstarted', 'datetime')
		, DeadlockGraph
		, DeadlockObjects = substring((SELECT (', ' + o.ObjectName)
							FROM DeadlockObjects o
							WHERE o.DeadlockID = e.DeadlockID
							ORDER BY o.ObjectName
							FOR XML PATH ('')
							), 3, 4000)
		, Victim = CASE WHEN v.VictimID IS NOT NULL 
							THEN 1 
						ELSE 0 
						END
		, SPID = Deadlock.Process.value('@spid', 'int')
		, ProcedureName = Deadlock.Process.value('executionStack[1]/frame[1]/@procname[1]', 'varchar(200)')
		, LockMode = Deadlock.Process.value('@lockMode', 'char(1)')
		, Code = Deadlock.Process.value('executionStack[1]/frame[1]', 'varchar(1000)')
		, ClientApp = CASE LEFT(Deadlock.Process.value('@clientapp', 'varchar(100)'), 29)
						WHEN 'SQLAgent - TSQL JobStep (Job '
							THEN 'SQLAgent Job: ' + (SELECT name FROM msdb..sysjobs sj WHERE substring(Deadlock.Process.value('@clientapp', 'varchar(100)'),32,32)=(substring(sys.fn_varbintohexstr(sj.job_id),3,100))) + ' - ' + SUBSTRING(Deadlock.Process.value('@clientapp', 'varchar(100)'), 67, len(Deadlock.Process.value('@clientapp', 'varchar(100)'))-67)
						ELSE Deadlock.Process.value('@clientapp', 'varchar(100)')
						END 
		, HostName = Deadlock.Process.value('@hostname', 'varchar(20)')
		, LoginName = Deadlock.Process.value('@loginname', 'varchar(20)')
		, InputBuffer = Deadlock.Process.value('inputbuf[1]', 'varchar(1000)')
	FROM #Events e
		CROSS APPLY e.DeadlockGraph.nodes('/event/data/value/deadlock/process-list/process') as Deadlock(Process)
		LEFT JOIN Victims v ON v.DeadlockID = e.DeadlockID AND v.VictimID = Deadlock.Process.value('@id', 'varchar(50)')
) X --In a subquery to make filtering easier (use column names, not XML parsing), no other reason
ORDER BY DeadlockID DESC

*/