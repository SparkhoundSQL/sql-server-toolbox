use w
go
DROP TABLE IF EXISTS #audit_created  
go
CREATE TABLE #audit_created  
(audit_created datetime2(0) primary key)

--See DimDate.sql
INSERT INTO #audit_created (audit_created) 
SELECT DISTINCT DT=  DATETIME2FROMPARTS (year(DimDate.CalendarDate), month(DimDate.CalendarDate), day(DimDate.CalendarDate), hours.Day_of_Month-1, 0,0,0,0)
 FROM DimDate 
 CROSS APPLY  DimDate as hours
 WHERE hours.Day_of_Month < 25 --get 24 numbers
 AND DimDate.CalendarDate >= '1/1/2009'
 AND DimDate.CalendarDate < '1/1/2020'
 ORDER BY DT

 --Get Server's local time zone from the regionalization settings (does not work in Azure SQL DB)
 DECLARE @TimeZone VARCHAR(50)
EXEC MASTER.dbo.xp_regread 'HKEY_LOCAL_MACHINE',
'SYSTEM\CurrentControlSet\Control\TimeZoneInformation',
'TimeZoneKeyName',@TimeZone OUT
SELECT @TimeZone, DATENAME(TZ , SYSDATETIMEOFFSET())

SELECT * FROM sys.time_zone_info WHERE name = @TimeZone

--Pretend that audit_created below is a UTC date that needs to be converted to the local timezone for display.
--Between Nov-March, 'Bad Strategy' below is wrong for historical dates between March-Nov. 
--Between March-Nov, 'Bad Strategy' below is wrong for historical dates between Nov-March. 
SELECT 
	UTCDate = audit_created	 
,	BadStrategy = DATEADD(second, DATEDIFF(second, GETUTCDATE(), GETDATE()), audit_created ) --Don't use!
,	ConvertedDate = audit_created  AT TIME ZONE 'UTC' AT TIME ZONE @TimeZone --SQL 2016+ only
,	WRONG = CASE WHEN convert(varchar(19), DATEADD(second, DATEDIFF(second, GETUTCDATE(), GETDATE()), audit_created )) = convert(varchar(19), audit_created  AT TIME ZONE 'UTC' AT TIME ZONE @TimeZone) THEN 0 ELSE 1 END
FROM #audit_created
GO