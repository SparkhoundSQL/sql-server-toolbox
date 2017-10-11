--Script out Database-level permissions
--See also Security Script 2012.sql

--Database role membership

--Single Database
--Run on each database for database-level security.
SELECT DB_NAME();
SELECT DISTINCT	QUOTENAME(r.name) as database_role_name, r.type_desc, QUOTENAME(d.name) as principal_name, d.type_desc
,	Add_TSQL = 'EXEC sp_addrolemember @membername = N''' + d.name COLLATE DATABASE_DEFAULT + ''', @rolename = N''' + r.name + ''''
,	Drop_TSQL = 'EXEC sp_droprolemember @membername = N''' + d.name COLLATE DATABASE_DEFAULT + ''', @rolename = N''' + r.name + ''''
FROM	sys.database_role_members rm
inner join sys.database_principals r on rm.role_principal_id = r.principal_id
inner join sys.database_principals d on rm.member_principal_id = d.principal_id
/*
--Multi Database
declare @tsql nvarchar(4000) = 'use [?]; 
SELECT DB_NAME();
SELECT DISTINCT	QUOTENAME(r.name) as database_role_name, r.type_desc, QUOTENAME(d.name) as principal_name, d.type_desc
,	Add_TSQL = ''EXEC sp_addrolemember @membername = N'''''' + d.name COLLATE DATABASE_DEFAULT + '''''', @rolename = N'''''' + r.name + ''''''''
,	Drop_TSQL = ''EXEC sp_droprolemember @membername = N'''''' + d.name COLLATE DATABASE_DEFAULT + '''''', @rolename = N'''''' + r.name + ''''''''
FROM	sys.database_role_members rm
inner join sys.database_principals r on rm.role_principal_id = r.principal_id
inner join sys.database_principals d on rm.member_principal_id = d.principal_id
';
exec sp_msforeachdb @tsql
go
*/


--Database Permissions
--Run on each database for database-level security.

SELECT DB_NAME();
SELECT	Permission_State_Desc	=	perm.state_desc
    ,	Permission_Name			=	perm.permission_name 
    ,	Permission_Object_Name	= ISNULL(QUOTENAME(s.name ) + '.','') + QUOTENAME(obj.name COLLATE database_default) + CASE WHEN cl.name COLLATE database_default is null THEN '' ELSE '.' + QUOTENAME(cl.name COLLATE database_default) END 			
	,	Object_Type_Desc		=	obj.type_desc   
    ,	Principal_Name			=	QUOTENAME(u.name COLLATE database_default) 
    ,	User_Type				=	u.type_desc 
	,	Create_TSQL = perm.state_desc + N' ' + perm.permission_name 
		+ case when obj.name COLLATE database_default is not null THEN + N' ON ' + sc.class_desc + '::' + ISNULL(QUOTENAME(s.name COLLATE database_default) + '.','') + QUOTENAME(obj.name COLLATE database_default) ELSE '' END 
		+ CASE WHEN cl.column_id IS NULL THEN ' ' ELSE '(' + QUOTENAME(cl.name COLLATE database_default) + ')' END 
		+ N' TO ' + QUOTENAME(u.name COLLATE database_default)
	,	Revoke_TSQL = N'REVOKE ' + perm.permission_name 
		+ case when obj.name COLLATE database_default is not null THEN + N' ON ' + sc.class_desc + '::' + ISNULL(QUOTENAME(s.name COLLATE database_default) + '.','') + QUOTENAME(obj.name COLLATE database_default) ELSE '' END 
		+ CASE WHEN cl.column_id IS NULL THEN ' ' ELSE '(' + QUOTENAME(cl.name COLLATE database_default) + ')' END 
		+ N' TO ' + QUOTENAME(u.name COLLATE database_default) 
		, *
FROM sys.database_permissions AS perm 
INNER JOIN sys.database_principals AS u	ON perm.grantee_principal_id = u.principal_id

LEFT OUTER JOIN (--https://msdn.microsoft.com/en-us/library/ms188367.aspx			
					select name, object_id, schema_id, is_ms_shipped, class_desc='OBJECT', type_desc from sys.objects 
					union all
					select name, 0, null, null, 'DATABASE', 'DATABASE'  from sys.databases 	
					union all
					select  name, schema_id, null, null, 'SCHEMA', 'SCHEMA' from sys.schemas
					union all
					select name, principal_id, null, null,  'USER', type_desc from sys.database_principals where type_desc in ('WINDOWS_USER','SQL_USER','ASYMMETRIC_KEY_MAPPED_USER','CERTIFICATE_MAPPED_USER', 'WINDOWS_GROUP','EXTERNAL_GROUPS')
					union all
					select name, principal_id, null, null,  'USER', type_desc from sys.database_principals where type_desc in ('WINDOWS_USER','SQL_USER','ASYMMETRIC_KEY_MAPPED_USER','CERTIFICATE_MAPPED_USER', 'WINDOWS_GROUP','EXTERNAL_GROUPS')
					union all
					select name, principal_id, null, null, 'APPLICATION ROLE', type_desc from sys.database_principals where type_desc in ('APPLICATION_ROLE')
					union all
					select name, principal_id, null, null, 'ROLE', type_desc from sys.database_principals where type_desc in ('DATABASE_ROLE')
					union all
					select name, assembly_id, null, null, 'ASSEMBLY', 'ASSEMBLY' from sys.assemblies 
					union all
					select name, user_type_id, null, null, 'TYPE', 'USER TYPE' from sys.types 
					union all
					select name, xml_collection_id, null, null, 'XML SCHEMA COLLECTION', 'XML SCHEMA COLLECTION' from sys.xml_schema_collections
					union all
					select name COLLATE database_default, message_type_id, null, null, 'MESSAGE TYPE', 'MESSAGE TYPE' from sys.service_message_types
					union all
					select name COLLATE database_default, service_contract_id, null, null, 'CONTRACT', 'CONTRACT' from sys.service_contracts
					union all
					select name COLLATE database_default, service_id, null, null, 'SERVICE', 'SERVICE' from sys.services
					union all
					select name COLLATE database_default, remote_service_binding_id, null, null, 'REMOTE SERVICE BINDING', 'REMOTE SERVICE BINDING' from sys.remote_service_bindings
					union all
					select name COLLATE database_default, route_id, null, null, 'ROUTE', 'ROUTE'  from sys.routes
					union all
					select name COLLATE database_default, fulltext_catalog_id, null, null, 'FULLTEXT CATALOG', 'FULLTEXT CATALOG'  from sys.fulltext_catalogs
					union all
					select name, symmetric_key_id, null, null, 'SYMMETRIC KEY', 'SYMMETRIC KEY'  from sys.symmetric_keys
					union all
					select name, certificate_id, null, null, 'CERTIFICATE', 'CERTIFICATE' from sys.certificates
					union all
					select name, asymmetric_key_id, null, null, 'ASYMMETRIC KEY', 'ASYMMETRIC KEY' from sys.asymmetric_keys
			) obj
ON perm.major_id = obj.[object_id] 
INNER JOIN sys.securable_classes sc on sc.class = perm.class 
and sc.class_desc = obj.class_desc
LEFT OUTER JOIN sys.schemas s ON s.schema_id = obj.schema_id
LEFT OUTER JOIN sys.columns cl ON cl.column_id = perm.minor_id AND cl.[object_id] = perm.major_id
where 1=1
and perm.major_id > 0
--Ignore internal principals
and u.name COLLATE database_default not in ('dbo','guest','INFORMATION_SCHEMA','sys','MS_DataCollectorInternalUser','PolicyAdministratorRole','ServerGroupReaderRole'
,'ServerGroupAdministratorRole','TargetServersRole','SQLAgentUserRole','UtilityCMRReader','SQLAgentOperatorRole','dc_operator','dc_proxy','dc_admin','db_ssisadmin','db_ssisltduser','db_ssisoperator'
,'UtilityIMRWriter','UtilityIMRReader','RSExecRole','DatabaseMailUserRole')
--Ignore ## principals
and u.name COLLATE database_default not like '##%##'
--Ignore built-in svc accounts (not recommended anyway!)
and u.name COLLATE database_default not like 'NT SERVICE%'
--Ignore MS shipped internal objects 
and (obj.is_ms_shipped = 0 or obj.is_ms_shipped is null) 
--Ignore system sprocs (be aware of your naming conventions!)
--and (obj.name not like 'sp_%' or obj.name is null)
order by Object_Type_Desc, Principal_Name


/*
--Multi-database database permissions
--script is too long for sp_msforeachdb, had to roll our own.

declare @tsql varchar(8000) = null, @dbcount int = 0, @x int = 0, @dbname varchar(256) = null
declare @dblist table (id int not null identity(1,1) primary key, dbname varchar(256)  not null )
insert into @dblist (dbname)
select name from sys.databases where name <> 'tempdb' and state_desc = 'ONLINE' 
order by database_id
select @dbcount = count(dbname) from @dblist

while (@x <= @dbcount)
BEGIN
	select @dbname = dbname from @dblist d where @x = d.id;

	select @tsql = 	'USE [' + @dbname  + '];
	SELECT DB_NAME();
	SELECT	Permission_State_Desc	=	perm.state_desc
		,	Permission_Name			=	perm.permission_name 
		,	Permission_Object_Name	= ISNULL(QUOTENAME(s.name ) + ''.'','''') + QUOTENAME(obj.name COLLATE database_default) + CASE WHEN cl.name COLLATE database_default is null THEN '''' ELSE ''.'' + QUOTENAME(cl.name COLLATE database_default) END 			
		,	Object_Type_Desc		=	obj.type_desc   
		,	Principal_Name			=	QUOTENAME(u.name COLLATE database_default) 
		,	User_Type				=	u.type_desc 
		,	Create_TSQL = perm.state_desc + N'' '' + perm.permission_name 
			+ case when obj.name COLLATE database_default is not null THEN + N'' ON '' + sc.class_desc + ''::'' + ISNULL(QUOTENAME(s.name COLLATE database_default) + ''.'','''') + QUOTENAME(obj.name COLLATE database_default) ELSE '''' END 
			+ CASE WHEN cl.column_id IS NULL THEN '' '' ELSE ''('' + QUOTENAME(cl.name COLLATE database_default) + '')'' END 
			+ N'' TO '' + QUOTENAME(u.name COLLATE database_default)
		,	Revoke_TSQL = N''REVOKE '' + perm.permission_name 
			+ case when obj.name COLLATE database_default is not null THEN + N'' ON '' + sc.class_desc + ''::'' + ISNULL(QUOTENAME(s.name COLLATE database_default) + ''.'','''') + QUOTENAME(obj.name COLLATE database_default) ELSE '''' END 
			+ CASE WHEN cl.column_id IS NULL THEN '' '' ELSE ''('' + QUOTENAME(cl.name COLLATE database_default) + '')'' END 
			+ N'' TO '' + QUOTENAME(u.name COLLATE database_default) 
			, *
	FROM sys.database_permissions AS perm 
	INNER JOIN sys.database_principals AS u	ON perm.grantee_principal_id = u.principal_id

	LEFT OUTER JOIN (--https://msdn.microsoft.com/en-us/library/ms188367.aspx			
						select name, object_id, schema_id, is_ms_shipped, class_desc=''OBJECT'', type_desc from sys.objects 
						union all
						select name, 0, null, null, ''DATABASE'', ''DATABASE''  from sys.databases 	
						union all
						select  name, schema_id, null, null, ''SCHEMA'', ''SCHEMA'' from sys.schemas
						union all
						select name, principal_id, null, null,  ''USER'', type_desc from sys.database_principals where type_desc in (''WINDOWS_USER'',''SQL_USER'',''ASYMMETRIC_KEY_MAPPED_USER'',''CERTIFICATE_MAPPED_USER'', ''WINDOWS_GROUP'',''EXTERNAL_GROUPS'')
						union all
						select name, principal_id, null, null,  ''USER'', type_desc from sys.database_principals where type_desc in (''WINDOWS_USER'',''SQL_USER'',''ASYMMETRIC_KEY_MAPPED_USER'',''CERTIFICATE_MAPPED_USER'', ''WINDOWS_GROUP'',''EXTERNAL_GROUPS'')
						union all
						select name, principal_id, null, null, ''APPLICATION ROLE'', type_desc from sys.database_principals where type_desc in (''APPLICATION_ROLE'')
						union all
						select name, principal_id, null, null, ''ROLE'', type_desc from sys.database_principals where type_desc in (''DATABASE_ROLE'')
						union all
						select name, assembly_id, null, null, ''ASSEMBLY'', ''ASSEMBLY'' from sys.assemblies 
						union all
						select name, user_type_id, null, null, ''TYPE'', ''USER TYPE'' from sys.types 
						union all
						select name, xml_collection_id, null, null, ''XML SCHEMA COLLECTION'', ''XML SCHEMA COLLECTION'' from sys.xml_schema_collections
						union all
						select name COLLATE database_default, message_type_id, null, null, ''MESSAGE TYPE'', ''MESSAGE TYPE'' from sys.service_message_types
						union all
						select name COLLATE database_default, service_contract_id, null, null, ''CONTRACT'', ''CONTRACT'' from sys.service_contracts
						union all
						select name COLLATE database_default, service_id, null, null, ''SERVICE'', ''SERVICE'' from sys.services
						union all
						select name COLLATE database_default, remote_service_binding_id, null, null, ''REMOTE SERVICE BINDING'', ''REMOTE SERVICE BINDING'' from sys.remote_service_bindings
						union all
						select name COLLATE database_default, route_id, null, null, ''ROUTE'', ''ROUTE''  from sys.routes
						union all
						select name COLLATE database_default, fulltext_catalog_id, null, null, ''FULLTEXT CATALOG'', ''FULLTEXT CATALOG''  from sys.fulltext_catalogs
						union all
						select name, symmetric_key_id, null, null, ''SYMMETRIC KEY'', ''SYMMETRIC KEY''  from sys.symmetric_keys
						union all
						select name, certificate_id, null, null, ''CERTIFICATE'', ''CERTIFICATE'' from sys.certificates
						union all
						select name, asymmetric_key_id, null, null, ''ASYMMETRIC KEY'', ''ASYMMETRIC KEY'' from sys.asymmetric_keys
				) obj
	ON perm.major_id = obj.[object_id] 
	INNER JOIN sys.securable_classes sc on sc.class = perm.class 
	and sc.class_desc = obj.class_desc
	LEFT OUTER JOIN sys.schemas s ON s.schema_id = obj.schema_id
	LEFT OUTER JOIN sys.columns cl ON cl.column_id = perm.minor_id AND cl.[object_id] = perm.major_id
	where 1=1
	and perm.major_id > 0
	--Ignore internal principals
	and u.name COLLATE database_default not in (''dbo'',''guest'',''INFORMATION_SCHEMA'',''sys'',''MS_DataCollectorInternalUser'',''PolicyAdministratorRole'',''ServerGroupReaderRole''
	,''ServerGroupAdministratorRole'',''TargetServersRole'',''SQLAgentUserRole'',''UtilityCMRReader'',''SQLAgentOperatorRole'',''dc_operator'',''dc_proxy'',''dc_admin'',''db_ssisadmin'',''db_ssisltduser'',''db_ssisoperator''
	,''UtilityIMRWriter'',''UtilityIMRReader'',''RSExecRole'',''DatabaseMailUserRole'')
	--Ignore ## principals
	and u.name COLLATE database_default not like ''##%##''
	--Ignore built-in svc accounts (not recommended anyway!)
	and u.name COLLATE database_default not like ''NT SERVICE%''
	--Ignore MS shipped internal objects 
	and (obj.is_ms_shipped = 0 or obj.is_ms_shipped is null) 
	--Ignore system sprocs (be aware of your naming conventions!)
	--and (obj.name not like ''sp_%'' or obj.name is null)
	order by Object_Type_Desc, Principal_Name';

	exec (@TSQL);
	select @x = @x + 1;
END

*/