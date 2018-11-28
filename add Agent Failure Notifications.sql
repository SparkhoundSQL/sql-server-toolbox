--TODO: Change the operator name sql.alerts@sparkhound.com
--TODO: Uncomment --EXEC (@TSQL) when confirmed

SET NOCOUNT ON
--These jobs do not have a notify operator setting
--select j.job_id, j.name, CategoryName = jc.name, j.enabled, j.description
--, OwnerName = suser_sname(j.owner_sid), date_created,date_modified, j.notify_email_operator_id
--  from msdb.dbo.sysjobs  j
--inner join msdb.dbo.syscategories jc
--on j.category_id = jc.category_id
--where j.notify_email_operator_id = 0  
--and j.name not in ('syspolicy_purge_history')

DECLARE AddFailureNotifications CURSOR FAST_FORWARD 
FOR
select convert(nvarchar(4000),	'
EXEC msdb.dbo.sp_update_job @job_id=N'''+convert(varchar(64), job_id)+''', /*'+j.name+'*/ 
		@notify_level_email=2, 
		@notify_email_operator_name=N''sql.alerts@sparkhound.com''')
from msdb.dbo.sysjobs  j
where j.notify_email_operator_id = 0  
and j.name not in ('syspolicy_purge_history')

declare @tsql nvarchar(4000) = null
OPEN AddFailureNotifications
FETCH NEXT FROM AddFailureNotifications 
INTO @tsql

WHILE @@FETCH_STATUS = 0
BEGIN
	--EXEC (@TSQL)
	SELECT @TSQL
	FETCH NEXT FROM AddFailureNotifications 
	INTO @tsql
END

CLOSE AddFailureNotifications
DEALLOCATE AddFailureNotifications;

