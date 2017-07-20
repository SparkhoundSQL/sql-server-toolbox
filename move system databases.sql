

USE master;
GO
alter database msdb modify file ( NAME = MSDBData , FILENAME = 'F:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\MSDBData.mdf')
go
alter database msdb modify file ( NAME = MSDBlog , FILENAME = 'F:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\MSDBLog.ldf')
go
alter database model modify file ( NAME = modeldev, FILENAME = 'F:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\model.mdf')
go
alter database model modify file ( NAME = modellog, FILENAME = 'F:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\modellog.ldf')
go
ALTER DATABASE tempdb MODIFY FILE (NAME = tempdev, FILENAME = 'F:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\tempdb.mdf');
go
ALTER DATABASE tempdb MODIFY FILE (NAME = templog, FILENAME = 'F:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\templog.ldf');
go
alter database reportserver MODIFY file ( NAME = ReportServer , FILENAME = 'F:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\ReportServer.mdf')
go
alter database reportserver MODIFY file ( NAME = ReportServer_log , FILENAME = 'F:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\ReportServer_Log.ldf')
go
alter database ReportServerTempDB MODIFY file ( NAME = ReportServerTempDB , FILENAME = 'F:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\ReportServerTempDB.mdf')
go
alter database ReportServerTempDB MODIFY file ( NAME = ReportServerTempDB_log , FILENAME = 'F:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\ReportServerTempDB_log.LDF')
go
alter database SSISDB MODIFY file ( NAME = data , FILENAME = 'F:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\SSISDB.mdf')
go
alter database SSISDB MODIFY file ( NAME = log , FILENAME = 'F:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\SSISDB.LDF')

/*
master startup parameters

--old
-dC:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\mastlog.ldf

--new
-dF:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ERRORLOG;-lF:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\data2\mastlog.ldf
*/

select name, physical_name, state_desc from sys.master_files