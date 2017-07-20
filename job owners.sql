use msdb
go
--TODO Change @owner_login_name to desired SQL agent service account to own the job

--sql 2005 and above
select owner = sp.name, jobname = j.name, j.job_id
,	change_tsql = N'EXEC msdb.dbo.sp_update_job @job_id=N'''+convert(nvarchar(100), j.job_id)+N''', @owner_login_name=N''domain\sqlsvcacct'''
,	revert_tsql = N'EXEC msdb.dbo.sp_update_job @job_id=N'''+convert(nvarchar(100), j.job_id)+N''', @owner_login_name=N'''+sp.name+''''
from sysjobs j
left outer join sys.server_principals  sp on j.owner_sid = sp.sid
where sp.name not in ('sa','distributor_admin','domain\sqlsvcacct') or sp.name is null
--EXEC msdb.dbo.sp_update_job @job_id=N'd5722a5c-d7cf-4332-8af9-d5839257cb4b', @owner_login_name=N'sa'

/*
--sql 2000
select sp.name, j.name, j.job_id from msdb.dbo.sysjobs j
left outer join master.dbo.syslogins sp on j.owner_sid = sp.sid
where sp.name not in ('sa','distributor_admin') or sp.name is null
--EXEC msdb.dbo.sp_update_job @job_id=N'8eab379e-958e-4576-92ae-b5999aeec01c', @owner_login_name=N'distributor_admin'
*/

