use DBALogging
go
ALTER PROCEDURE dbo.killblockingsessions
AS
SET NOCOUNT OFF

	/* Kill Blocking Sessions
		This procedure is intended to be run regularly against a SQL Server to detect and kill sessions that 
			1) have been running >5 minutes
			2) are blocking other sessions
		The procedure kills the most-blocking and longest-running session (in that order) each time it runs.
		The SQL Job that executes this sproc is Kill Blocking Sessions
		By default, this sproc cleans up old records older than 3 months.
		Activity is logged to the table dbalogging.dbo.ExecRequestsLog 

		First implemented 20150129 William Assaf, Sparkhound
	*/

	--Detect blocking spids
	declare @blockingspids table
	(blocking_session_id int not null, blocking_len int not null, blocked_request_start_time date null)

	insert into @blockingspids (blocking_session_id, blocking_len, blocked_request_start_time)
	select r.blocking_session_id, blocking_len = count(distinct s.session_id), blocked_request_start_time = max(r.start_time)
	from 
	sys.dm_exec_sessions s left outer join 
	sys.dm_exec_requests r on s.session_id = r.session_id
	inner join 
	sys.dm_exec_sessions s2 on r.blocking_session_id = s2.session_id
	left outer join 
	sys.dm_exec_requests r2 on s2.session_id = r2.session_id
	where 1=1
	and r.session_id >= 50 --retrieve only user spids
	and s2.session_id >= 50 --retrieve only user spids
	and r.session_id <> @@SPID --ignore myself
	and s2.session_id <> @@SPID --ignore myself
	and r.blocking_session_id is not null
	and (datediff(SECOND, r2.start_time, getdate()) > 30 -- five minutes
		or datediff(SECOND, r.start_time, getdate()) > 30 -- five minutes
		)
	--Next line is specifically for D'Addario on 99-SQL2012
	and (s2.program_name = 'Microsoft Office 2010' or s2.program_name like 'SQLAgent%')

	group by r.blocking_session_id


	IF EXISTS ( select * from @blockingspids b where blocking_session_id > 0 )
	BEGIN
			declare @blocking_session_id int = null, @str nvarchar(100) = null

			--select 'before', * from @blockingspids b

			select top 1 @blocking_session_id = b.blocking_session_id
			from @blockingspids b where blocking_session_id > 0
			order by blocking_len desc --kill the root blocker first\
			,	blocked_request_start_time asc
		
			SELECT @str=N'KILL '+CONVERT(nvarchar(10),@blocking_session_id )
		
			declare @when datetime = getdate(); 

			insert into dbalogging.dbo.ExecRequestsLog (timecaptured, blocking_session_id,session_id,request_id, request_start_time, login_time, login_name, client_interface_name, session_status, request_status, command,sql_handle,statement_start_offset,statement_end_offset,plan_handle,database_id,user_id,wait_type,last_wait_type,wait_time_s,wait_resource,cpu_time_s,tot_time_s,reads,writes,logical_reads,[host_name], [program_name] ,	session_transaction_isolation_level ,	request_transaction_isolation_level , offsettext)
				select timecaptured = @when, blocking_session_id,s.session_id,request_id, r.start_time, s.login_time, s.login_name, s.client_interface_name, s.status, r.status,command,r.sql_handle,r.statement_start_offset,r.statement_end_offset,r.plan_handle,r.database_id,user_id,wait_type,r.last_wait_type, r.wait_time/1000.,r.wait_resource ,r.cpu_time/1000.,r.total_elapsed_time/1000.,r.reads,r.writes,r.logical_reads,s.[host_name], s.[program_name], s.transaction_isolation_level, r.transaction_isolation_level
				, offsettext	=	CASE	WHEN r.statement_start_offset = 0 and r.statement_end_offset= 0 THEN NULL
							ELSE	SUBSTRING (		est.[text]
											,	r.statement_start_offset/2 + 1, 
												CASE WHEN r.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), est.[text])) 
													ELSE r.statement_end_offset/2 - r.statement_start_offset/2 + 1
												END	)
					END

				from sys.dm_exec_sessions s 
				left outer join sys.dm_exec_requests r on r.session_id = s.session_id
				LEFT OUTER JOIN sys.dm_exec_cached_plans p ON p.plan_handle = r.plan_handle 
				OUTER APPLY sys.dm_exec_query_plan (r.plan_handle) qp
				OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) est
				LEFT OUTER JOIN sys.dm_exec_query_stats stat on stat.plan_handle = r.plan_handle
				and r.statement_start_offset = stat.statement_start_offset  
				and r.statement_end_offset = stat.statement_end_offset
				where 1=1
				and s.session_id >= 50 --retrieve only user spids
				and s.session_id <> @@SPID --ignore myself

			update r
			set blocking_these = LEFT((select isnull(convert(varchar(5), er.session_id),'') + ', ' 
									from dbalogging.dbo.ExecRequestsLog  er
									where er.blocking_session_id = isnull(r.session_id ,0)
									and er.blocking_session_id <> 0
									and timecaptured = @when
									FOR XML PATH('') 
									),1000)
			FROM dbalogging.dbo.ExecRequestsLog r
			WHERE blocking_these IS NULL
			and timecaptured = @when

			update r 
			set kill_text = @str 
			FROM dbalogging.dbo.ExecRequestsLog r
			where @blocking_session_id = session_id
			and timecaptured = @when

		if @blocking_session_id is not null
		BEGIN
			PRINT @str
			EXEC (@str)

		END	
		
		update @blockingspids 
		set blocking_session_id = 0 
		where blocking_session_id = @blocking_session_id

		set @blocking_session_id = null

		--select 'after', * from @blockingspids b

		--select * from  dbalogging.dbo.ExecRequestsLog where timecaptured = @when 

	END

	delete from dbalogging.dbo.ExecRequestsLog 
	where blocking_these is null and (blocking_session_id is null or blocking_session_id = 0)
	
	--Only do maintenance in the middle of the night
	if (datepart(hour, getdate()) = 1)
	BEGIN
		
		delete from dbalogging.dbo.ExecRequestsLog 
		where timecaptured < dateadd(month, -3, getdate())

	END
	
GO
	
