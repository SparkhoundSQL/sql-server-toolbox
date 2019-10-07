use msdb
go
select user_name = dpu.name, role_name = dpr.name 
from msdb.sys.database_role_members drm
left outer join msdb.sys.database_principals dpu on dpu.principal_id = drm.member_principal_id
left outer join msdb.sys.database_principals dpr on dpr.principal_id = drm.role_principal_id
where dpr.name = 'SQLAgentOperatorRole'