--Work in progress, not Production ready

use msdb
go

declare @xp_sqlagent_enum_jobs table ( 
Job_ID uniqueidentifier not null PRIMARY KEY, 
Last_Run_Date int not null, 
Last_Run_Time int not null, 
Next_Run_Date int not null, 
Next_Run_Time int not null,  
Next_Run_Schedule_ID int not null, 
Requested_To_Run int not null, 
Request_Source int not null, 
Request_Source_ID varchar(100)  null, 
Running int not null, 
Current_Step int not null, 
Current_Retry_Attempt int not null, 
[State] int not null 
)

INSERT INTO @xp_sqlagent_enum_jobs 
EXEC master.dbo.xp_sqlagent_enum_jobs 1,''  

--Essentially display the SQL Agent Job Activity Monitor
SELECT * 
 FROM msdb.dbo.sysjobs j
 INNER JOIN @xp_sqlagent_enum_jobs ej ON j.job_id = ej.Job_ID

declare @now datetime = GETDATE()

--Danger, the below is unrefined. Testing only. -w

IF NOT EXISTS (select 1 from admindb.sys.objects o  where name = 'overduejobs')
CREATE TABLE admindb.[dbo].[overduejobs](
	ID int not null identity(1,1) PRIMARY KEY,
	[name] [sysname] NOT NULL,
	[job_id] [uniqueidentifier] NOT NULL,
	[State] [varchar](29) NULL,
	[last_run_datetime] [datetime] NULL,
	[next_run_datetime] [datetime] NULL,
	[If_Nightly_Job_When_Start] [datetime] NULL,
	[Avg_Duration_s] [int] NULL,
	[Expected_Current_End_Time] [datetime] NULL,
	[Now] [datetime] NOT NULL,
	capturedtime datetime not null default(getdate())
) ON [PRIMARY]

insert into admindb.dbo.overduejobs (
		name
	,	job_id
	,	State
	,	last_run_datetime
	,	next_run_datetime
	,	If_Nightly_Job_When_Start
	,	Avg_Duration_s
	,	Expected_Current_End_Time
	,	Now)
 select name, job_id, State, last_run_datetime,  next_run_datetime, If_Nightly_Job_When_Start, Avg_Duration_s 
	,	Expected_Current_End_Time	=	CASE		WHEN	If_Nightly_Job_When_Start is not null 
														THEN dateadd(s, avg_duration_s, If_Nightly_Job_When_Start)
													WHEN	next_run_datetime is not null 
														and next_run_datetime > last_run_datetime 
														and @now > next_run_datetime
														THEN dateadd(s, avg_duration_s, next_run_datetime)
													ELSE dateadd(s, avg_duration_s, last_run_datetime) END
	,	Now							=	@now
from 
 (
  select 
	j.name
  , j.job_id
  , Category_name = c.name
  , State	=		case e.State	WHEN 	1 THEN	'Executing'
									WHEN	2 THEN	'Waiting for thread'
									WHEN	3 THEN	'Between retries'
									WHEN	4 THEN	'Idle'
									WHEN	5 THEN	'Suspended'
									WHEN	7 THEN	'Performing completion actions' END
	--convert integer date and integer time HHMMSS to a datetime
  ,	last_run_datetime		=	convert(datetime, (ltrim(convert(varchar(20), converT(smalldatetime, convert(varchar(20), jh.run_date)), 111)))
						+ ' ' + (isnull(ltrim(stuff(stuff(right('00' + convert(varchar(6), jh.run_time),6),3,0, ':' ), 6,0,':')),'00:00:00'))
						)
	--convert integer date and integer time HHMMSS to a datetime
  ,	next_run_datetime		=	min(convert(datetime, case when js.next_run_date <> 0 THEN convert(varchar(20), js.next_run_date, 113) ELSE NULL END
							+ ' ' + (isnull(ltrim(stuff(stuff(right('00' + convert(varchar(6), js.next_run_time),6),3,0, ':' ), 6,0,':')),'00:00:00'))
							))
	--convert HHMMSS integer to seconds so that we can average it							
  ,	Avg_Duration_s = avg(cast(Right(rtrim(ltrim(converT(char(10), jh.run_duration))),2) as int)
					  + (cast(reverse(substring(reverse( rtrim(ltrim(converT(char(10), jh.run_duration)))), 3,2))  as int) *60)
					  + (cast(reverse(substring(reverse( rtrim(ltrim(converT(char(10), jh.run_duration)))), 5,6)) as int) * 3600)) 
					  * 1.05 --pad the duration by 5% to prevent false positives
  ,	If_Nightly_Job_When_Start	=	max(sc.If_Nightly_Job_When_Start)
														
 from dbo.sysjobs j
 inner join (select job_id, run_duration
				, run_date, run_time, run_status
				, instancerank= rank() over (partition by job_id order by run_date desc, run_time desc) 
				from dbo.sysjobhistory 
				where step_id = 0
	) jh 
 on j.job_id = jh.job_id
 and jh.instancerank = 1
 left outer join dbo.syscategories c
 on j.category_id = c.category_id
 left outer join dbo.sysjobschedules js
 on js.job_id = j.job_id
 left outer join 
	(SELECT schedule_id, If_Nightly_Job_When_Start = CASE WHEN 
												(sc.freq_type = 4 and freq_interval = 1 and freq_subday_type = 1)--once daily
											or	(sc.freq_type = 8 and freq_interval = 127 and freq_subday_type = 1)-- every day
											or	(sc.freq_type = 8 and freq_interval = 62 and DATEPART(dw, @now) between 2 and 6) --weekdays
										THEN convert(datetime, 
												convert(varchar(10), convert(date, 
													CASE WHEN datepart(hour, @now) >= left(right('00' + convert(varchar(6), sc.active_start_time),6),2) 
															THEN @now
															ELSE DATEADD(day, -1, @now) END))
													+ ' ' + (isnull(ltrim(stuff(stuff(right('00' + convert(varchar(6), sc.active_start_time),6),3,0, ':' ), 6,0,':')),'00:00:00')
												))				
										ELSE NULL
										END
							FROM dbo.sysschedules sc 
							WHERE sc.enabled = 1 
	) sc
 on sc.schedule_id = js.schedule_id
 inner join #enum_job e
 on e.job_id = j.job_id
 
 where 
 	1=1
 and c.name not like 'repl%'
 and c.name <> 'Report Server'
 and j.name <> 'overdue jobs' --ignore myself
 and e.state in (1,2,3,7) 
 group by  j.name, j.job_id, jh.run_date, jh.run_time, c.name, e.state
 ) x
where	@now > CASE			WHEN	If_Nightly_Job_When_Start is not null 
								THEN dateadd(s, avg_duration_s, If_Nightly_Job_When_Start)
							WHEN	next_run_datetime is not null 
								and next_run_datetime > last_run_datetime 
								and @now > next_run_datetime
								THEN dateadd(s, avg_duration_s, next_run_datetime)
							ELSE dateadd(s, avg_duration_s, last_run_datetime) END
order by name, state, last_run_datetime, next_run_datetime

drop table #enum_job

declare @querytext varchar(150) 
select @querytext = 'SELECT name FROM admindb.dbo.overduejobs where convert(smalldatetime, now) = convert(smalldatetime, ''' + convert(varchar(20), @now, 120) + ''')'
declare @subjecttext varchar(100) 
select @subjecttext = @@servername + ' Overdue Database Jobs '

insert into admindb.dbo.overduejobs (name, job_id, now) values ('TESTING ONLY', NEWID(), @now)

IF exists (SELECT 1 FROM admindb.dbo.overduejobs where now = @now)
EXEC dbo.sp_send_dbmail
    @profile_name = 'prodsql1',
    @recipients = 'william.assaf@sparkhound.com',
    --@body = 'Failed Jobs',
    @query = @querytext,
    @attach_query_result_as_file = 0,
    @execute_query_database = 'admindb',
    @subject = @subjecttext


