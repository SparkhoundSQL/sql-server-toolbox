use msdb
go
--TODO Change @owner_login_name to desired SQL agent service account to own the job

declare @Desired_job_owner varchar(255) = 'SPARKHOUND\svcaccount' --'sa' is just an example, change to desired service account, example: domain\accountname

--sql 2005 and above
select owner = SUSER_SNAME (j.owner_sid), jobname = j.name, j.job_id
,	change_tsql = N'EXEC msdb.dbo.sp_update_job @job_id=N'''+convert(nvarchar(100), j.job_id)+N''', @owner_login_name=N'''+@Desired_job_owner+''''
,	revert_tsql = N'EXEC msdb.dbo.sp_update_job @job_id=N'''+convert(nvarchar(100), j.job_id)+N''', @owner_login_name=N'''+SUSER_SNAME (j.owner_sid)+''''
from sysjobs j
left outer join sys.server_principals  sp on j.owner_sid = sp.sid
where 
	(sp.name not in ('sa','distributor_admin','NT SERVICE\ReportServer') 
	 and sp.name <> @Desired_job_owner
	 and sp.name not like '##%')
	or sp.name is null 

/*
--sql 2000
select sp.name, j.name, j.job_id from msdb.dbo.sysjobs j
left outer join master.dbo.syslogins sp on j.owner_sid = sp.sid
where sp.name not in ('sa','distributor_admin') or sp.name is null
--EXEC msdb.dbo.sp_update_job @job_id=N'8eab379e-958e-4576-92ae-b5999aeec01c', @owner_login_name=N'distributor_admin'
*/

/*
--Sample usage

EXEC msdb.dbo.sp_update_job @job_id=N'BDAFAC9B-1705-4E47-9C26-6C4B813CB165', @owner_login_name=N'sa'
EXEC msdb.dbo.sp_update_job @job_id=N'987AF666-A516-4847-8BA3-73DE337CFF94', @owner_login_name=N'sa'
EXEC msdb.dbo.sp_update_job @job_id=N'AEBF4C5C-EC6D-4635-96B6-797BF4AEEC62', @owner_login_name=N'sa'

*/

