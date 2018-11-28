--TODO: Change the operator name sql.alerts@sparkhound.com

declare @Desired_operator varchar(255) = 'sql.alerts@sparkhound.com' --is just an example, change to desired operator listed in msdb.dbo.sysoperators

--Finds any jobs not sending a failure notification to someone
SELECT 
	JobName = j.name
,	j.description
,	j.enabled
,	OwnerName = suser_sname(j.owner_sid)
,	date_created
,	date_modified
,	TSQL_Add_Failure_Notification =	convert(nvarchar(4000),	'EXEC msdb.dbo.sp_update_job @job_id=N'''+convert(varchar(64), job_id)+''', /*'+j.name+'*/ 
		@notify_level_email=2, 
		@notify_email_operator_name=N'''+@Desired_operator+'''')
from msdb.dbo.sysjobs  j
where j.notify_email_operator_id = 0  
and j.enabled = 1

