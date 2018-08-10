
--TODOs
--1. Specify events and logins/groups to be captured for Database Audit
--	 As configured only captures writes. Add a similar pattern for ADD(SELECT ... to capture all reads.
--2. Set filter on databases to be audited

--If lines are broken and do not paste correctly, 
--in SSMS, use Tools -> Options -> Query Results -> SQL Server -> Results to Grid -> Retain CR/LF on copy or save
--then open/close SSMS

--You may also have to change the "Maximum Number of Characters displayed in each column from the default.
--in SSMS, use Tools -> Options -> Query Results -> SQL Server -> Results to Text window
--then open/close SSMS window 

use master
GO
SET NOCOUNT ON
GO
SELECT
'USE [master];
GO
CREATE SERVER AUDIT ['+replace(@@SERVERNAME,'\','')+'-Audit]
TO APPLICATION_LOG --write to the Application Event Log
WITH
(	QUEUE_DELAY = 5000
	,ON_FAILURE = CONTINUE
);
go
CREATE SERVER AUDIT SPECIFICATION ['+replace(@@SERVERNAME,'\','')+'-Audit-Spec]
FOR SERVER AUDIT ['+replace(@@SERVERNAME,'\','')+'-Audit]
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
ADD (AUDIT_CHANGE_GROUP),
ADD (DATABASE_PERMISSION_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_CHANGE_GROUP), --Important: This event is raised for any DDL in any database. 
ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP), 
ADD (LOGIN_CHANGE_PASSWORD_GROUP),
ADD (SERVER_PRINCIPAL_CHANGE_GROUP)
WITH (STATE = OFF);
GO'

SELECT 
--TODO 1. specify events and logins/groups to be captured for Database Audit
--As configured only captures writes. Add a similar pattern for ADD(SELECT ... to capture all reads.

--catch all known admin users, regardless of whether or not they have dbo right now
--Examples:
--ADD (UPDATE ON DATABASE::['+d.name+'] BY [Sparkhound\william.assaf]),
--ADD (DELETE ON DATABASE::['+d.name+'] BY [Sparkhound\william.assaf]),
--ADD (INSERT ON DATABASE::['+d.name+'] BY [Sparkhound\william.assaf]),
--ADD (EXECUTE ON DATABASE::['+d.name+'] BY [Sparkhound\william.assaf]),
--ADD (UPDATE ON DATABASE::['+d.name+'] BY [Sparkhound\Developers]),
--ADD (DELETE ON DATABASE::['+d.name+'] BY [Sparkhound\Developers]),
--ADD (INSERT ON DATABASE::['+d.name+'] BY [Sparkhound\Developers]),
--ADD (EXECUTE ON DATABASE::['+d.name+'] BY [Sparkhound\Developers]),

--catch all database admins, period.
--ADD (UPDATE ON DATABASE::['+d.name+'] BY [dbo]),
--ADD (INSERT ON DATABASE::['+d.name+'] BY [dbo]),
--ADD (DELETE ON DATABASE::['+d.name+'] BY [dbo]),
--ADD (EXECUTE ON DATABASE::['+d.name+'] BY [dbo]),
--ADD (SELECT ON DATABASE::['+d.name+'] BY [dbo])
--WITH (STATE = OFF);

N'USE ['+d.name+'];
GO
CREATE DATABASE AUDIT SPECIFICATION [Database-'+replace(d.name,N' ',N'')+N'-Audit-Spec]
FOR SERVER AUDIT ['+replace(@@SERVERNAME,'\','')+N'-Audit]
--catch all activity, period.
ADD (UPDATE ON DATABASE::['+d.name+N'] BY [public]),
ADD (INSERT ON DATABASE::['+d.name+N'] BY [public]),
ADD (DELETE ON DATABASE::['+d.name+N'] BY [public]),
ADD (EXECUTE ON DATABASE::['+d.name+N'] BY [public]),
ADD (SELECT ON DATABASE::['+d.name+N'] BY [public])
WITH (STATE = OFF);
GO
ALTER DATABASE AUDIT SPECIFICATION [Database-'+replace(d.name,N' ',N'')+N'-Audit-Spec]
FOR SERVER AUDIT ['+replace(@@SERVERNAME,'\','')+N'-Audit]
WITH (STATE = ON);
GO
'
FROM (SELECT name = convert(nvarchar(4000), d.name) from sys.databases d
WHERE d.name not in ('tempdb','msdb','distribution')
--and d.name in (N'a2012db') --this filter for testing only
) d;
--TODO 2. Add any database names here you want to ignore

GO
SELECT '
use master
go
ALTER SERVER AUDIT SPECIFICATION ['+replace(@@SERVERNAME,'\','')+'-Audit-Spec]
WITH (STATE = ON);
GO
ALTER SERVER AUDIT ['+replace(@@SERVERNAME,'\','')+'-Audit]
WITH (STATE = ON);
GO
';

/*

--Cleanup

USE [master]
GO
ALTER SERVER AUDIT [BTR-69NRN32SQL2K16-Audit] WITH (STATE = OFF);
GO
ALTER SERVER AUDIT SPECIFICATION [BTR-69NRN32SQL2K16-Audit-Spec] WITH (STATE = OFF);
GO
USE [a2012db]
GO
ALTER DATABASE AUDIT SPECIFICATION [Database-a2012db-Audit-Spec] WITH (STATE = OFF);
GO
DROP DATABASE AUDIT SPECIFICATION [Database-a2012db-Audit-Spec]
GO
USE [master]
GO
DROP SERVER AUDIT SPECIFICATION [BTR-69NRN32SQL2K16-Audit-Spec] 
GO
DROP SERVER AUDIT [BTR-69NRN32SQL2K16-Audit]
GO

*/