--Script out Server-level permissions
--See also Security Script - database.sql
--This script works SQL 2012+ (thus the title)

--enable "Retain CR/LF on copy or save" in Options, Query Results, SQL Server, Results to Grid

SELECT @@SERVERNAME

--script out SQL logins to create/transfer
--http://support.microsoft.com/kb/918992
-- or see bottom of this script
EXEC sp_help_revlogin
GO

--or, use the next two.

--create windows logins
select 
	CreateTSQL_Source = 'CREATE LOGIN ['+ name +'] FROM WINDOWS WITH DEFAULT_DATABASE=['+default_database_name+'], DEFAULT_LANGUAGE=['+default_language_name+']' + CHAR(10) + CHAR(13) + 'GO'
,	DropTSQL_Source = 'DROP LOGIN ['+ name +']' 

from sys.server_principals
where type in ('U','G')
and name not like 'NT %'
and is_disabled = 0
order by name, type_desc

USE [master]
GO

--compare sql logins, use to drop only. Can only get Password hash from sp_help_revlogin, so use that for migrations.
select 
	QUOTENAME(name) as sql_login_name
,	CreateTSQL_Source = 'CREATE LOGIN ['+ name +'] WITH DEFAULT_DATABASE=['+default_database_name+'], DEFAULT_LANGUAGE=['+default_language_name+'] 
	, CHECK_EXPIRATION=' + CASE is_expiration_checked WHEN 0 THEN 'OFF' ELSE 'ON' END + '
	, CHECK_POLICY= ' + CASE is_policy_checked WHEN 0 THEN 'OFF' ELSE 'ON' END + '
	 WITH 
	 --PASSWORD = Must use sp_help_revlogin for PW!,
	 SID = ', sid 
,	DropTSQL_Source = 'DROP LOGIN ['+ name +']' 
from sys.sql_logins
where type = ('S')
and name not in ('dbo', 'sa', 'public')
and is_disabled = 0
order by sid, sql_login_name
GO


--Server level roles
SELECT	DISTINCT
	Server_Role_Name			=	QUOTENAME(r.name) 
,	Role_Type					=	r.type_desc
,	Principal_Name				=	QUOTENAME(m.name)
,	Principal_Type				=	m.type_desc 
,	SQL2008R2_below_CreateTSQL	=	'exec sp_addsrvrolemember  @loginame=  '''+m.name+''',  @rolename = '''+r.name+'''' 
,	SQL2012_above_CreateTSQL	=	'ALTER SERVER ROLE [' + r.name + '] ADD MEMBER [' + m.name + ']'
,	DropTSQL_Source				=	'ALTER SERVER ROLE [' + r.name + '] DROP MEMBER [' + m.name + ']'
FROM	sys.server_role_members AS rm
inner join sys.server_principals r on rm.role_principal_id = r.principal_id
inner join sys.server_principals m on rm.member_principal_id = m.principal_id
where r.is_disabled = 0 and m.is_disabled = 0
and m.name not in ('dbo', 'sa', 'public')
and m.name not like 'NT %'
order by QUOTENAME(r.name)


--Server Level Security
SELECT 
   Permission_State  =  rm.state_desc
,  Permission  =  rm.permission_name
,  Principal_name  =  QUOTENAME(u.name)
,  Principal_type  =  u.type_desc
,  CreateTSQL_Source = rm.state_desc + N' ' + rm.permission_name + 
	CASE WHEN e.name is not null THEN 'ON ENDPOINT::[' + e.name + '] ' ELSE '' END +
	N' TO ' + cast(QUOTENAME(u.name COLLATE DATABASE_DEFAULT) as nvarchar(256)) + ';'
,  DropTSQL_Source = N'REVOKE ' + rm.permission_name +
	CASE WHEN e.name is not null THEN 'ON ENDPOINT::[' + e.name + '] ' ELSE '' END +
	 N' TO ' + cast(QUOTENAME(u.name COLLATE DATABASE_DEFAULT) as nvarchar(256)) + ';', *
FROM sys.server_permissions rm
inner join sys.server_principals u 
on rm.grantee_principal_id = u.principal_id
left outer join sys.endpoints e
on e.endpoint_id = major_id and class_desc = 'ENDPOINT'
where u.name not like '##%' 
and u.name not in ('dbo', 'sa', 'public')
and u.name not like 'NT %'
order by rm.permission_name, u.name



/*

USE master
GO
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
  DROP PROCEDURE sp_hexadecimal
GO
CREATE PROCEDURE sp_hexadecimal
    @binvalue varbinary(256),
    @hexvalue varchar (514) OUTPUT
AS
DECLARE @charvalue varchar (514)
DECLARE @i int
DECLARE @length int
DECLARE @hexstring char(16)
SELECT @charvalue = '0x'
SELECT @i = 1
SELECT @length = DATALENGTH (@binvalue)
SELECT @hexstring = '0123456789ABCDEF'
WHILE (@i <= @length)
BEGIN
  DECLARE @tempint int
  DECLARE @firstint int
  DECLARE @secondint int
  SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
  SELECT @firstint = FLOOR(@tempint/16)
  SELECT @secondint = @tempint - (@firstint*16)
  SELECT @charvalue = @charvalue +
    SUBSTRING(@hexstring, @firstint+1, 1) +
    SUBSTRING(@hexstring, @secondint+1, 1)
  SELECT @i = @i + 1
END

SELECT @hexvalue = @charvalue
GO
 
IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL
  DROP PROCEDURE sp_help_revlogin
GO
CREATE PROCEDURE sp_help_revlogin @login_name sysname = NULL AS
DECLARE @name sysname
DECLARE @type varchar (1)
DECLARE @hasaccess int
DECLARE @denylogin int
DECLARE @is_disabled int
DECLARE @PWD_varbinary  varbinary (256)
DECLARE @PWD_string  varchar (514)
DECLARE @SID_varbinary varbinary (85)
DECLARE @SID_string varchar (514)
DECLARE @tmpstr  varchar (1024)
DECLARE @is_policy_checked varchar (3)
DECLARE @is_expiration_checked varchar (3)

DECLARE @defaultdb sysname
 
IF (@login_name IS NULL)
  DECLARE login_curs CURSOR FOR

      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name <> 'sa'
ELSE
  DECLARE login_curs CURSOR FOR


      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name = @login_name
OPEN login_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
IF (@@fetch_status = -1)
BEGIN
  PRINT 'No login(s) found.'
  CLOSE login_curs
  DEALLOCATE login_curs
  RETURN -1
END
SET @tmpstr = '/* sp_help_revlogin script '
PRINT @tmpstr
SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN
    PRINT ''
    SET @tmpstr = '-- Login: ' + @name
    PRINT @tmpstr
    IF (@type IN ( 'G', 'U'))
    BEGIN -- NT authenticated account/group

      SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
    END
    ELSE BEGIN -- SQL Server authentication
        -- obtain password and sid
            SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )
        EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT
        EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT
 
        -- obtain password policy state
        SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
        SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
 
            SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

        IF ( @is_policy_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
        END
        IF ( @is_expiration_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
        END
    END
    IF (@denylogin = 1)
    BEGIN -- login is denied access
      SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
    END
    ELSE IF (@hasaccess = 0)
    BEGIN -- login exists but does not have access
      SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
    END
    IF (@is_disabled = 1)
    BEGIN -- login is disabled
      SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
    END
    PRINT @tmpstr
  END

  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
   END
CLOSE login_curs
DEALLOCATE login_curs
RETURN 0
GO

*/