/*
Individual users, not groups, have been added to the sysadmin server role. 
It is more desirable to have AD security groups, not individual accounts (even adm accounts) have access to the SQL Server via this role. 
Suggest creating a SQL DBA or DB Admins group for SQL Server admins in the organization instead.
*/

select sp.name, sr.name, * from sys.server_principals sp 
inner join sys.server_role_members  srm on sp.principal_id = srm.member_principal_id
inner join sys.server_principals sr on srm.role_principal_id = sr.principal_id
where (sp.name = 'BUILTIN\Administrators'  --This should not be there after SQL 2005
		or sp.type_desc = 'WINDOWS_LOGIN' or sp.type_desc = 'SQL_LOGIN') --ignores Security Groups, only Windows or SQL individual accounts
and sr.name in ('sysadmin','securityadmin') --securityadmin should be guarded just as much as sysadmin
and sp.name not like 'NT SERVICE\%'
and sp.name not like 'NT AUTHORITY\%'
and sp.principal_id > 1 --ignore the sa account
--check for common naming conventions around service accounts
and sp.name not like '%svc%' 