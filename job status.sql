--jobs still running 
declare @xp_sqlagent_enum_jobs table ( 
id int not null IDENTITY(1,1) PRIMARY KEY,
Job_ID uniqueidentifier not null, 
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
[State] int not null);

INSERT INTO @xp_sqlagent_enum_jobs 
EXEC master.dbo.xp_sqlagent_enum_jobs 1,'';

SELECT j.name
, state_desc = CASE ej.state 
WHEN 0 THEN 'not idle or suspended'
WHEN 1 THEN 'Executing'
WHEN 2 THEN 'Waiting for thread'
WHEN 3 THEN 'Between retries'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Suspended'
WHEN 7 THEN 'Performing completion actions'
--https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-help-job-transact-sql
END  
, *
 FROM  msdb.dbo.sysjobs j
 LEFT OUTER JOIN @xp_sqlagent_enum_jobs ej 
 ON j.job_id = ej.Job_ID
ORDER BY j.name;