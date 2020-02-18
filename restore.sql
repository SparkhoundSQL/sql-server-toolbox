--Basic Restore template

USE [master]
GO

--RESTORE FILELISTONLY FROM  DISK = N'C:\BACKUPS\whatever.bak' 
go
ALTER DATABASE whatever SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
RESTORE DATABASE [whatever] FROM  DISK = N'C:\backups\whatever.bak' 
WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 5,
 MOVE 'whatever' to 'e:\SQLDATA\whatever.mdf',
 MOVE 'whatever_log' to 'e:\SQLDATA\whatever.ldf'
GO
ALTER DATABASE whatever SET  MULTI_USER
GO

/*
Next:
Check compatibility mode and other database options? 
Enable Query Store?
fix orpahned sids.sql
*/
 

/*
--Example: Restore WWI sample DB
USE [master]
--https://github.com/Microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers
ALTER DATABASE [WideWorldImporters] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
RESTORE DATABASE [WideWorldImporters] 
FROM  DISK = N'E:\Program Files\Microsoft SQL Server\MSSQL15.SQL2K19\MSSQL\Backup\WideWorldImporters-Full.bak' 
WITH  FILE = 1
,  MOVE N'WWI_Primary' TO N'E:\Program Files\Microsoft SQL Server\MSSQL15.SQL2K19\MSSQL\DATA\WideWorldImporters.mdf'
,  MOVE N'WWI_UserData' TO N'E:\Program Files\Microsoft SQL Server\MSSQL15.SQL2K19\MSSQL\DATA\WideWorldImporters_UserData.ndf'
,  MOVE N'WWI_Log' TO N'E:\Program Files\Microsoft SQL Server\MSSQL15.SQL2K19\MSSQL\DATA\WideWorldImporters.ldf'
,  MOVE N'WWI_InMemory_Data_1' TO N'E:\Program Files\Microsoft SQL Server\MSSQL15.SQL2K19\MSSQL\DATA\WideWorldImporters_InMemory_Data_1',  NOUNLOAD,  STATS = 5
GO
ALTER DATABASE [WideWorldImporters] SET MULTI_USER
GO
ALTER DATABASE [WideWorldImporters] SET COMPATIBILITY_LEVEL = 150
GO




*/