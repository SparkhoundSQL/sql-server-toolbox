USE master
--create login [Sparkhound\DB Administrators-Readonly] FROM WINDOWS
GO
GRANT ALTER TRACE TO [Sparkhound\DB Administrators-Readonly]
GRANT ALTER ANY EVENT SESSION TO [Sparkhound\DB Administrators-Readonly]
GRANT VIEW ANY DEFINITION TO [Sparkhound\DB Administrators-Readonly]
GRANT SHOWPLAN TO [Sparkhound\DB Administrators-Readonly]

--For DMV's
GRANT VIEW SERVER STATE TO [Sparkhound\DB Administrators-Readonly]
exec sp_msforeachdb 'use [?]; GRANT VIEW DATABASE STATE TO [Sparkhound\DB Administrators-Readonly]'


--For the Error Log
--One of the next two scripts will work, but only the first allows SQL Error Log access via the UI.
--However, securityadmin is virtually the same as sysadmin, since you can make yourself a sysadmin.
--https://social.msdn.microsoft.com/Forums/en-US/11efe32b-1af5-44da-bbf7-e183e5341f2c/grant-access-to-view-sql-server-logs-from-sql-server-management-studio?forum=sqlsecurity'
--There is no permission short of securityadmin/sysadmin that allows SSMS to view logs. 
ALTER SERVER ROLE [securityadmin] ADD MEMBER [Sparkhound\DB Administrators-Readonly]
--or--
GRANT  EXECUTE ON xp_readerrorlog TO [Sparkhound\DB Administrators-Readonly]; 
--With the above permission and no membership to sysadmin or securityadmin, must use toolbox/error log.sql instead of the SSMS UI to view logs.
GO

--For SQL Agent jobs 
USE msdb
GO
CREATE USER [Sparkhound\DB Administrators-Readonly] FOR LOGIN [Sparkhound\DB Administrators-Readonly]
ALTER ROLE [SQLAgentReaderRole] ADD MEMBER [Sparkhound\DB Administrators-Readonly]
ALTER ROLE [SQLAgentOperatorRole] ADD MEMBER [Sparkhound\DB Administrators-Readonly]
GRANT SELECT TO [Sparkhound\DB Administrators-Readonly]
GRANT EXECUTE ON sysmail_help_profile_sp TO [Sparkhound\DB Administrators-Readonly]