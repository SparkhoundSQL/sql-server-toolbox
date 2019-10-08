--Equivalent viewing the number of Error logs retained in SSMS, right-click on SQL Server Logs, configure
--"Limit the number of error logs files before they are recycled"
--By default, 6. Max value of 99.
--The registry key NumErrorLogs does not exist until the default value of 6 is overridden, so NULL = default.
--Actual path of key something like: Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.SQL2K19\MSSQLServer, but can be searched

declare @numlogs int 
EXEC master.dbo.xp_instance_regread @rootkey= N'HKEY_LOCAL_MACHINE'
, @key = N'Software\Microsoft\MSSQLServer\MSSQLServer'
, @value_name = N'NumErrorLogs'
, @value = @numlogs OUTPUT
select @numlogs



--Configure SQL Server Error log to keep 50 logs, as opposed to the default 6
--EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, 50
GO
