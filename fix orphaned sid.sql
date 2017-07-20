--Only works for SQL 2005 SP2 or later!
/** GENERATE TSQL TO FIX ORPHANS **/
Select 
		DBUser_Name	=	dp.name
	,	DBUser_SID	=	dp.sid
	,	Login_Name	=	sp.name
	,	Login_SID	=	sp.sid
	,	SQLtext		=	'ALTER USER [' + dp.name + '] WITH LOGIN = [' + ISNULL(sp.name, '???') + ']'
	from sys.database_principals dp
	left outer join sys.server_principals sp
	on dp.name = sp.name 
	where 
		dp.is_fixed_role = 0
	and sp.sid <> dp.sid 
	and dp.principal_id > 1
	and dp.sid is not null 
	and dp.sid <> 0x0
	order by dp.name
go




/* multi-database

exec sp_MSforeachdb N'use [?];
Select [?]=	''?'', 	''ALTER USER ['' + dp.name + ''] WITH LOGIN = ['' + dp.name + '']'', *
	from sys.database_principals dp
	inner join sys.server_principals sp
	on dp.name COLLATE SQL_Latin1_General_CP1_CI_AS = sp.name COLLATE SQL_Latin1_General_CP1_CI_AS 
	where 
		dp.is_fixed_role = 0
	and (dp.sid is not null and dp.sid <> 0x0)	
	and sp.sid <> dp.sid 
	and dp.principal_id > 1
	order by dp.name
'
*/


/***** OLD ********/
/*
select * from sysusers
where issqluser = 1 and (sid is not null and sid <> 0x0) and suser_sname(sid) is null
order by name

--Only works for SQL 2005 SP2 or later!
GO
DECLARE @SQL varchar(100)
DECLARE curSQL CURSOR FOR
	Select 	'ALTER USER [' + name + '] WITH LOGIN = [' + name + ']'
	from sysusers
	where issqluser = 1 	and (sid is not null and sid <> 0x0)	and suser_sname(sid) is null
	order by name
OPEN curSQL
FETCH curSQL into @SQL
WHILE @@FETCH_STATUS = 0
BEGIN
	print @SQL
	EXEC (@SQL)
	FETCH curSQL into @SQL
END
CLOSE curSQL
DEALLOCATE curSQL

GO
*/



/*

--Lab: Create orphaned SID

USE [master]
GO
CREATE LOGIN [test] WITH PASSWORD=N'test', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

USE w
GO
CREATE USER test
GO


test	0x1E1EEF7790E11745B42B9A33083DFF55	NULL	NULL	ALTER USER [test] WITH LOGIN = [test]

ALTER USER [test] WITH LOGIN = [test]

*/
