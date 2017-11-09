--	TODO: Run the script below to refresh the demo
USE [DemoDatabase]
GO
ALTER TABLE [dbo].[TemporalTable] SET ( SYSTEM_VERSIONING = OFF )
GO
DROP TABLE [dbo].[TemporalTable]
GO
DROP TABLE [dbo].[TemporalTableHistory]
GO
USE [master]
GO
DROP DATABASE [DemoDatabase]
GO







/*	Creates the demo database */
CREATE DATABASE [DemoDatabase]
 ON  PRIMARY 
( NAME = N'DemoDatabase', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA\DemoDatabase.mdf' )
 LOG ON 
( NAME = N'DemoDatabase_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA\DemoDatabase_log.ldf' )
GO


USE [DemoDatabase]
GO





/*	Creating the Temporal Table while also naming the History table */
CREATE TABLE [dbo].[TemporalTable](
	[ID] [int] PRIMARY KEY NOT NULL,
	[FirstName] [varchar](255) NULL,
	[LastName] [varchar](255) NULL,
	[Age] [int] NULL,
	[Gender] [varchar](50) NULL,
	[SysStartTime] [datetime2](7) GENERATED ALWAYS AS ROW START, 
	[SysEndTime] [datetime2](7) GENERATED ALWAYS AS ROW END,
	PERIOD FOR SYSTEM_TIME ([SysStartTime], [SysEndTime])
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [dbo].[TemporalTableHistory] ))
GO


SELECT * FROM [dbo].[TemporalTable]

SELECT * FROM [dbo].[TemporalTableHistory]





/*	Insert sample data into the table to be used. */
INSERT [dbo].[TemporalTable] (ID, FirstName, LastName, Age, Gender) VALUES (1, 'John', 'Doe', 35, 'Male')
WAITFOR DELAY '00:00:05'
INSERT [dbo].[TemporalTable] (ID, FirstName, LastName, Age, Gender) VALUES (2, 'Mary', 'Lee', 28, 'Female')
WAITFOR DELAY '00:00:05'
INSERT [dbo].[TemporalTable] (ID, FirstName, LastName, Age, Gender) VALUES (3, 'SQL', 'Server', 27, 'System')


SELECT * FROM [dbo].[TemporalTable]

SELECT * FROM [dbo].[TemporalTableHistory]





/*	
	The system stores the previous value of the row in the history table 
	and sets the value for the SysEndTime column to the begin time of the 
	current transaction (in the UTC time zone) based on the system clock. 
	This marks the row as closed, with a period recorded for which the previous row was valid.
*/

/*	Perform an update on the table, because Mary gets married to John */
UPDATE [dbo].[TemporalTable]
SET LastName = 'Doe'
WHERE FirstName = 'Mary'


SELECT * FROM [dbo].[TemporalTable]

SELECT * FROM [dbo].[TemporalTableHistory]





/*	Perform an update on the table, because Mary divorced John */
UPDATE [dbo].[TemporalTable]
SET LastName = 'Lee'
WHERE FirstName = 'Mary'


SELECT * FROM [dbo].[TemporalTable]

SELECT * FROM [dbo].[TemporalTableHistory]





/*	What if all of the data accidently got deleted? */
TRUNCATE TABLE [dbo].[TemporalTable]
GO
TRUNCATE TABLE [dbo].[TemporalTableHistory]
GO


DELETE FROM [dbo].[TemporalTable]
WHERE ID = 3


SELECT * FROM [dbo].[TemporalTable]

SELECT * FROM [dbo].[TemporalTableHistory]





/*	Insert sample data back into the table to be used. */
INSERT [dbo].[TemporalTable] (ID, FirstName, LastName, Age, Gender) VALUES
(3, 'SQL', 'Server', 27, 'System')


SELECT * FROM [dbo].[TemporalTable]

SELECT * FROM [dbo].[TemporalTableHistory]





/*	Let's see what happen when both tables are out of sync. */
ALTER TABLE [dbo].[TemporalTable] SET ( SYSTEM_VERSIONING = OFF )
GO

ALTER TABLE [dbo].[TemporalTable]
ADD [SET] int


SELECT * FROM [dbo].[TemporalTable]

SELECT * FROM [dbo].[TemporalTableHistory]


ALTER TABLE [dbo].[TemporalTable] SET 
( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = [dbo].[TemporalTableHistory]))
GO


ALTER TABLE [dbo].[TemporalTableHistory]
ADD [SET] int


SELECT * FROM [dbo].[TemporalTable]

SELECT * FROM [dbo].[TemporalTableHistory]


ALTER TABLE [dbo].[TemporalTable] SET ( SYSTEM_VERSIONING = ON)
GO


/*	This is what happens when you don't define the HISTORY_TABLE */
ALTER TABLE [dbo].[TemporalTable] SET ( SYSTEM_VERSIONING = OFF )
GO

ALTER TABLE [dbo].[TemporalTable] SET 
( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = [dbo].[TemporalTableHistory]))
GO





/*	Querying for time with offset 
	Below is the system view */
select * from sys.time_zone_info

SELECT [ID],[FirstName],[LastName],[Age],[Gender]
      ,[SysStartTime] AT TIME ZONE 'Central Standard Time' AS StartTime 
      ,[SysEndTime]
FROM [dbo].[TemporalTable]

SELECT  [ID],[FirstName],[LastName],[Age],[Gender]
		,[SysStartTime] AT TIME ZONE 'Central Standard Time' AS SysStartTime 
		,[SysEndTime] AT TIME ZONE 'Central Standard Time' AS SysEndTime
FROM [dbo].[TemporalTableHistory]

/*	
	TODO: Change date and time
	Querying System Time with AS OF
	AS OF will include rows up to a point of time for current data 
*/
SELECT * FROM [dbo].[TemporalTable]
SELECT * 
FROM [dbo].[TemporalTable]  
FOR SYSTEM_TIME AS OF '2017-11-08 20:15:13.6195602';


/*
	TODO: Change date and time
	Querying System Time with FROM...TO AND BETWEEN...AND
	FROM … TO and BETWEEN … AND are very similar. 
	They include rows that were active during the time interval for both current and historical data.
*/
SELECT * FROM [dbo].[TemporalTable]
SELECT * FROM [dbo].[TemporalTableHistory]
SELECT * 
FROM [dbo].[TemporalTable]
FOR SYSTEM_TIME FROM '2017-05-24 17:20:40' TO '2017-05-24 17:23:10'   

SELECT * FROM [dbo].[TemporalTable]
SELECT * FROM [dbo].[TemporalTableHistory]
SELECT * 
FROM [dbo].[TemporalTable]
FOR SYSTEM_TIME BETWEEN '2017-05-24 17:20:40' AND '2017-05-24 17:23:10'  


/* 
	TODO: Change date and time
	Querying System Time with CONTAINED IN 
	The CONTAINED IN will look only at historical records and only include 
	those that completely occurred within the time window. 
*/
SELECT * FROM [dbo].[TemporalTable]
SELECT * FROM [dbo].[TemporalTableHistory]
SELECT * 
FROM [dbo].[TemporalTable]  
FOR SYSTEM_TIME CONTAINED IN ('2017-05-24 17:20:00', '2017-05-24 17:22:50')

/* 
	Querying System Time with ALL
	Union of all current and historical data 
*/
SELECT *
FROM [dbo].[TemporalTable]   
FOR SYSTEM_TIME ALL 





/*	Clearing the history table */
ALTER TABLE [dbo].[TemporalTable] SET ( SYSTEM_VERSIONING = OFF )
GO

TRUNCATE TABLE [dbo].[TemporalTableHistory]

SELECT * FROM [dbo].[TemporalTable]

SELECT * FROM [dbo].[TemporalTableHistory]

ALTER TABLE [dbo].[TemporalTable] SET ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = [dbo].[TemporalTableHistory]))
GO


/*	Set retention policy if Azure SQL Database */
ALTER DATABASE [DemoDatabase]
SET TEMPORAL_HISTORY_RETENTION ON
GO

ALTER TABLE [dbo].[TemporalTable]
SET (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 30 DAYS));