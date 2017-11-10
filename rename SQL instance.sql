/* 
	Rename SQL Server Instance  

When the physical server is renamed, this script must be executed to rename the SQL Server Instance.

Change the Variables to the correct information, and then execute the script.
The results will show the old setting and the changed setting so you can verify the 

*/

SELECT SERVERPROPERTY('MachineName') [Machine Name],@@SERVERNAME [SQL Instance]

-----------------------------------------------------------------------------
--- PLEASE CHANGE THE FOLLOWING VARIABLES BEFORE EXECUTION
DECLARE @Current_SQLServer_Name sysname = ''  --- Old Physical name or Current SQL Instance Name
DECLARE @New_SQLServer_Name sysname = ''	-- New Physical name or New SQL Instance Name


-----------------------------------------------------------------------------
--EXEC sp_dropserver @server=@Current_SQLServer_Name
--EXEC sp_addserver  @server=@New_SQLServer_Name, @Local='local'
--GO


SELECT SERVERPROPERTY('MachineName') [Machine Name],@@SERVERNAME [SQL Instance]
