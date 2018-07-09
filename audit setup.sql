
--TODOs
--1. Specify events and logins/groups to be captured for Database Audit
--	 As configured only captures writes. Add a similar pattern for ADD(SELECT ... to capture all reads.
--2. Set filter on databases to be audited

--If lines are broken and do not paste correctly, 
--in SSMS, use Tools -> Options -> Query Results -> SQL Server -> Results to Grid -> Retain CR/LF on copy or save
--then open/close SSMS


use master
GO
select
'USE [master]
GO
CREATE SERVER AUDIT ['+replace(@@SERVERNAME,'\','')+'-Audit]
TO APPLICATION_LOG --write to the Application Event Log
WITH
(	QUEUE_DELAY = 5000
	,ON_FAILURE = CONTINUE
)
go
CREATE SERVER AUDIT SPECIFICATION [ServerAudit]
FOR SERVER AUDIT ['+replace(@@SERVERNAME,'\','')+'-Audit]
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
ADD (AUDIT_CHANGE_GROUP),
ADD (DATABASE_PERMISSION_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_CHANGE_GROUP), --Important: This event is raised whenever any schema of any database changes. 
ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP), 
ADD (LOGIN_CHANGE_PASSWORD_GROUP),
ADD (SERVER_PRINCIPAL_CHANGE_GROUP)
WITH (STATE = OFF)
GO'

select 
--TODO 1. specify events and logins/groups to be captured for Database Audit
--As configured only captures writes. Add a similar pattern for ADD(SELECT ... to capture all reads.

'USE ['+d.name+']
GO
CREATE DATABASE AUDIT SPECIFICATION [Database-'+replace(d.name,' ','')+'-Audit]
FOR SERVER AUDIT ['+replace(@@SERVERNAME,'\','')+'-Audit]
--catch all known admin users, regardless of whether or not they have dbo right now
--Examples:
ADD (UPDATE ON DATABASE::['+d.name+'] BY [Sparkhound\william.assaf]),
ADD (DELETE ON DATABASE::['+d.name+'] BY [Sparkhound\william.assaf]),
ADD (INSERT ON DATABASE::['+d.name+'] BY [Sparkhound\william.assaf]),
ADD (EXECUTE ON DATABASE::['+d.name+'] BY [Sparkhound\william.assaf]),
ADD (UPDATE ON DATABASE::['+d.name+'] BY [Sparkhound\Developers]),
ADD (DELETE ON DATABASE::['+d.name+'] BY [Sparkhound\Developers]),
ADD (INSERT ON DATABASE::['+d.name+'] BY [Sparkhound\Developers]),
ADD (EXECUTE ON DATABASE::['+d.name+'] BY [Sparkhound\Developers]),

--catch all database admins, period.
ADD (UPDATE ON DATABASE::['+d.name+'] BY [dbo]),
ADD (INSERT ON DATABASE::['+d.name+'] BY [dbo]),
ADD (DELETE ON DATABASE::['+d.name+'] BY [dbo]),
ADD (EXECUTE ON DATABASE::['+d.name+'] BY [dbo])
WITH (STATE = OFF);
GO
ALTER DATABASE AUDIT SPECIFICATION [Database-'+replace(d.name,' ','')+'-Audit]
FOR SERVER AUDIT ['+@@SERVERNAME+'-Audit]
WITH (STATE = ON);
GO
'
from sys.databases d
--TODO 2. Add any database names here you want to ignore
where d.name not in ('tempdb','msdb','distribution')
GO
SELECT '
USE master
GO
--ALTER SERVER AUDIT ['+replace(@@SERVERNAME,'\','')+'-Audit]
--WITH (STATE = OFF);
--GO
ALTER SERVER AUDIT ['+replace(@@SERVERNAME,'\','')+'-Audit]
WITH (STATE = ON);
GO
';
