EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'w_memopt'
GO
USE [master]
GO
ALTER DATABASE [w_memopt] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE [w_memopt]
GO
USE [master]
GO

CREATE DATABASE [w_memopt]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'w_memopt', FILENAME = N'E:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\DATA\w_memopt.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'w_memopt_log', FILENAME = N'E:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\DATA\w_memopt_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [w_memopt] SET RECOVERY SIMPLE 
GO
ALTER DATABASE w_memopt
ADD FILEGROUP [w_memopt_mod_fg] CONTAINS MEMORY_OPTIMIZED_DATA; 
GO
ALTER DATABASE w_memopt
ADD FILE (NAME='TestDB_mod_dir', FILENAME='E:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\DATA\w_memopt-mo') 
	TO FILEGROUP [w_memopt_mod_fg];
GO
use [w_memopt]
go
DROP TABLE IF EXISTS [dbo].[memopt1]
GO
CREATE TABLE [dbo].[memopt1]
(
  [id] [int] IDENTITY(1,1) NOT NULL
, [memtext1] [varchar](2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
, CONSTRAINT [memopt1_primaryKey]  PRIMARY KEY NONCLUSTERED HASH ([id] )	WITH ( BUCKET_COUNT = 1024000)
) WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )
GO
SET STATISTICS TIME ON
INSERT INTO dbo.memopt1 (memtext1) VALUES ('aaaaaaaaaaaaaaaaaaaaa')
GO
INSERT INTO dbo.memopt1 (memtext1) select memtext1 from dbo.memopt1 OPTION (MAXDOP 1)
GO 21
SET STATISTICS TIME OFF
GO
/*
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 2 ms.

(2048 rows affected)
...
 SQL Server Execution Times:
   CPU time = 1500 ms,  elapsed time = 3343 ms.

(1048576 rows affected)
   */
DROP TABLE IF EXISTS [dbo].not_memopt1
GO
CREATE TABLE dbo.not_memopt1
(	id int not null IDENTITY(1,1) PRIMARY KEY
,	memtext1 varchar(2000)
)
GO
SET STATISTICS TIME ON
INSERT INTO dbo.not_memopt1 (memtext1) VALUES ('aaaaaaaaaaaaaaaaaaaaa')
GO
INSERT INTO dbo.not_memopt1 (memtext1) select memtext1 from dbo.not_memopt1  OPTION (MAXDOP 1)
GO 21
SET STATISTICS TIME OFF
/*
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 13 ms.

(2048 rows affected)
...
 SQL Server Execution Times:
   CPU time = 3656 ms,  elapsed time = 5568 ms.

(1048576 rows affected)
*/

GO
DROP TABLE IF EXISTS [dbo].[memopt1]
GO


/*
--Create a rowstore table that we'll convert to memory-optimized
CREATE TABLE dbo.memopt1
(	id int not null IDENTITY(1,1)
,	memtext1 varchar(2000)
)
GO
INSERT INTO dbo.memopt1 (memtext1) VALUES ('aaaaaaaaaaaaaaaaaaaaa')
GO
INSERT INTO dbo.memopt1 (memtext1) select memtext1 from dbo.memopt1
GO 10
GO
CREATE TABLE dbo.memopt2
(	id int not null IDENTITY(1,1)
,	memtext2 varchar(2000)
)
GO
INSERT INTO dbo.memopt2 (memtext2) select memtext1 from dbo.memopt1
GO 


USE [w_memopt]
GO

EXEC dbo.sp_rename @objname = N'[dbo].[memopt1]', @newname = N'memopt1_old', @objtype = N'OBJECT'
GO

USE [w_memopt]
GO

SET ANSI_NULLS ON
GO

CREATE TABLE [dbo].[memopt1]
(
	[id] [int] IDENTITY(1,1) NOT NULL,
	[memtext1] [varchar](2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL

 , CONSTRAINT [memopt1_primaryKey]  PRIMARY KEY NONCLUSTERED HASH ([id] )	WITH ( BUCKET_COUNT = 1024)
 --,  CONSTRAINT [memopt1_primaryKey]  PRIMARY KEY CLUSTERED COLUMNSTORE 
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )

GO
ALTER TABLE memopt1   
       ALTER INDEX [memopt1_primaryKey]  
              REBUILD WITH (BUCKET_COUNT=67108864);  
GO

alter index [memopt1_primaryKey] on dbo.memopt1 REBUILD


SET IDENTITY_INSERT [w_memopt].[dbo].[memopt1] ON 

GO

INSERT INTO [w_memopt].[dbo].[memopt1] ([id], [memtext1]) SELECT [id], [memtext1] FROM [w_memopt].[dbo].[memopt1_old] 

GO

SET IDENTITY_INSERT [w_memopt].[dbo].[memopt1] OFF 

GO

EXEC dbo.sp_rename @objname = N'[dbo].[memopt2]', @newname = N'memopt2_old', @objtype = N'OBJECT'
GO

USE [w_memopt]
GO
CREATE TABLE [dbo].[memopt2]
(
	[id] [int] IDENTITY(1,1) NOT NULL,
	[memtext2] [varchar](2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL --INDEX IDX_NC_MemOpt2

 , CONSTRAINT [memopt2_primaryKey]  PRIMARY KEY NONCLUSTERED ([id]) 
 )
 WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_ONLY )
GO

SET IDENTITY_INSERT [w_memopt].[dbo].[memopt2] ON 

GO

INSERT INTO [w_memopt].[dbo].[memopt2] ([id], [memtext2]) SELECT [id], [memtext2] FROM [w_memopt].[dbo].[memopt2_old] 

GO

SET IDENTITY_INSERT [w_memopt].[dbo].[memopt2] OFF 

GO
ALTER TABLE [dbo].[memopt1]
	ADD INDEX IDX_NC_H_memopt1_memtext1 HASH (memtext1) WITH (BUCKET_COUNT = 1024)
GO
ALTER TABLE [dbo].[memopt1]
	ADD INDEX IDX_NC_memopt1_memtext1 NONCLUSTERED (memtext1)
GO

ALTER TABLE [dbo].[memopt2]
	ADD INDEX IDX_NC_H_memopt2_memtext2 HASH (memtext2) WITH (BUCKET_COUNT = 1024)
GO
ALTER TABLE [dbo].[memopt2]
	ADD INDEX IDX_NC_H_memopt2_id UNIQUE HASH (id) WITH (BUCKET_COUNT = 1024)
GO

*/



