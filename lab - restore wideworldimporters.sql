--AdventureWorks latest download
--https://docs.microsoft.com/sql/samples/wide-world-importers-oltp-install-configure

USE [master]
GO
RESTORE VERIFYONLY FROM  DISK = N'E:\Program Files\Microsoft SQL Server\MSSQL15.SQL2K19\MSSQL\Backup\WideWorldImporters-Full.bak'
GO
alter database [WideWorldImporters]  set single_user with rollback immediate
GO
USE [master]
RESTORE DATABASE [WideWorldImporters] FROM  DISK = N'E:\Program Files\Microsoft SQL Server\MSSQL15.SQL2K19\MSSQL\Backup\WideWorldImporters-Full.bak'
WITH  FILE = 1,  REPLACE,
MOVE N'WWI_Primary' TO N'E:\Program Files\Microsoft SQL Server\MSSQL15.SQL2K19\MSSQL\DATA\WideWorldImporters.mdf',  
MOVE N'WWI_UserData' TO N'E:\Program Files\Microsoft SQL Server\MSSQL15.SQL2K19\MSSQL\DATA\WideWorldImporters_UserData.ndf',  
MOVE N'WWI_Log' TO N'E:\Program Files\Microsoft SQL Server\MSSQL15.SQL2K19\MSSQL\DATA\WideWorldImporters.ldf',  
MOVE N'WWI_InMemory_Data_1' TO N'E:\Program Files\Microsoft SQL Server\MSSQL15.SQL2K19\MSSQL\DATA\WideWorldImporters_InMemory_Data_1',  NOUNLOAD,  STATS = 5
GO


alter database [WideWorldImporters]  set multi_user with rollback immediate
GO
alter database [WideWorldImporters] set compatibility_level = 150