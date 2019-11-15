use w
go
DROP TABLE IF EXISTS dbo.DimDate 
GO

CREATE TABLE dbo.DimDate  (
    [dimDateID]				INT				NOT NULL,
    [CalendarDate]			DATE			NOT NULL,
    [Day_of_Month]			TINYINT			NOT NULL,
    [Day_of_Year]			SMALLINT		NOT NULL,
    [Day_of_Week]			TINYINT			NOT NULL,
    [Year]					SMALLINT		NOT NULL,
    [Quarter]				CHAR (2)		NOT NULL,
    [Month]					TINYINT			NOT NULL,
    [Month_Name]			VARCHAR (30)	NOT NULL,
    [Week_of_Year]			TINYINT			NOT NULL,
	[DayOfWeek_Month]		TINYINT			NOT NULL,
    [DayofWeek_Name]		VARCHAR (30)	NOT NULL,
    [ISOWeek_of_Year]		TINYINT			NOT NULL,
	[FirstDay_Month]		DATE			NOT NULL,
	[LastDay_Month]			DATE			NOT NULL,
	[FirstDay_Year]			DATE			NOT NULL,
    [IsWeekend]				CHAR (3)		NOT NULL,
	[IsHoliday]				BIT				NULL,
	[HolidayText]			VARCHAR(64)		NULL,
    CONSTRAINT [PK_WH_DimDate] PRIMARY KEY NONCLUSTERED ([CalendarDate] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [IDX_NC_DimDate_DimDateID] UNIQUE CLUSTERED ([dimDateID] ASC) WITH (DATA_COMPRESSION = PAGE)
);
go

;with cteDate (seeddate) as
	(
	select seeddate = convert(date, '1/1/2000') 
	UNION ALL
	select dateadd(day, 1, seeddate) 
	from cteDate
	where seeddate < '1/1/2050'
) 

insert into dbo.DimDate (dimDateID, CalendarDate, Day_of_Month, Day_of_Year, Day_of_Week, Year, Quarter, Month, Month_Name, DayOfWeek_Month, Week_of_Year, DayofWeek_Name, ISOWeek_of_Year, FirstDay_Month, LastDay_Month, FirstDay_Year, IsWeekend)
		select 
			dimDateID			=	convert(int,convert(varchar(8),seeddate, 112))
		,	CalendarDate		=	seeddate
		,	Day_of_Month		=	DatePart(d, seeddate)
		,	Day_of_Year			=	DatePart(dy, seeddate)
		,	Day_of_Week			=	DatePart(dw, seeddate)
		,	[Year]				=	DatePart(yyyy, seeddate)
		,	[Quarter]			=	'Q' + Convert(char(1), datepart(quarter , seeddate))
		,	[Month]				=	DatePart(M, seeddate)
		,	[Month_Name]		=	DateName(m, seeddate) 
		,   [DayOfWeek_Month]   =	CONVERT(TINYINT, ROW_NUMBER() OVER 
									(PARTITION BY (CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, seeddate), 0))), DatePart(dw, seeddate) ORDER BY seeddate))
		,	Week_of_Year		=	DatePart(week, seeddate) 
		,	DayofWeek_Name		=	DateName(dw, seeddate) 
		,	ISOWeek_of_Year		=	DatePart(ISO_WEEK, seeddate) 
		,	[FirstDay_Month]	=	CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, seeddate), 0))
		,	[LastDay_Month]		=	MAX(seeddate) OVER (PARTITION BY DatePart(yyyy, seeddate), DatePart(M, seeddate))
		,	[FirstDay_Year]		=	CONVERT(DATE, DATEADD(YEAR,  DATEDIFF(YEAR,  0, seeddate), 0))
		,	IsWeekend			=	CASE WHEN DatePart(dw, seeddate) in (1,7) THEN 'Yes' ELSE 'No' END
from cteDate
where seeddate < '1/1/2050'
OPTION (MAXRECURSION 0);
GO

-- Adds Holidays
;WITH x AS 
(
  SELECT /* DateKey, */ CalendarDate, IsHoliday, HolidayText, [FirstDay_Year],
    [DayOfWeek_Month], [Month_Name], DayofWeek_Name, Day_of_Month,
    LastDOWInMonth = ROW_NUMBER() OVER 
    (
      PARTITION BY [FirstDay_Month], Day_of_Week 
      ORDER BY CalendarDate DESC
    )
  FROM dbo.DimDate
)
UPDATE x SET IsHoliday = 1, HolidayText = CASE
  WHEN ([CalendarDate] = FirstDay_Year) 
    THEN 'New Year''s Day'
  WHEN ([DayOfWeek_Month] = 3 AND [Month_Name] = 'January' AND [DayofWeek_Name] = 'Monday')
    THEN 'Martin Luther King Day'    -- (3rd Monday in January)
  WHEN ([DayOfWeek_Month] = 3 AND [Month_Name] = 'February' AND [DayofWeek_Name] = 'Monday')
    THEN 'President''s Day'          -- (3rd Monday in February)
  WHEN (LastDOWInMonth = 1 AND [Month_Name] = 'May' AND [DayofWeek_Name] = 'Monday')
    THEN 'Memorial Day'              -- (last Monday in May)
  WHEN ([Month_Name] = 'July' AND Day_of_Month = 4)
    THEN 'Independence Day'          -- (July 4th)
  WHEN ([DayOfWeek_Month] = 1 AND [Month_Name] = 'September' AND [DayofWeek_Name] = 'Monday')
    THEN 'Labour Day'                -- (first Monday in September)
  WHEN ([DayOfWeek_Month] = 2 AND [Month_Name] = 'October' AND [DayofWeek_Name] = 'Monday')
    THEN 'Columbus Day'              -- Columbus Day (second Monday in October)
  WHEN ([Month_Name] = 'November' AND Day_of_Month = 11)
    THEN 'Veterans'' Day'            -- Veterans' Day (November 11th)
  WHEN ([DayOfWeek_Month] = 4 AND [Month_Name] = 'November' AND [DayofWeek_Name] = 'Thursday')
    THEN 'Thanksgiving Day'          -- Thanksgiving Day (fourth Thursday in November)
  WHEN ([Month_Name] = 'December' AND Day_of_Month = 25)
    THEN 'Christmas Day'
  END
WHERE 
  ([CalendarDate] = [FirstDay_Year])
  OR ([DayOfWeek_Month] = 3     AND [Month_Name] = 'January'   AND [DayofWeek_Name] = 'Monday')
  OR ([DayOfWeek_Month] = 3     AND [Month_Name] = 'February'  AND [DayofWeek_Name] = 'Monday')
  OR (LastDOWInMonth = 1 AND [Month_Name] = 'May'       AND [DayofWeek_Name] = 'Monday')
  OR ([Month_Name] = 'July' AND Day_of_Month = 4)
  OR ([DayOfWeek_Month] = 1     AND [Month_Name] = 'September' AND [DayofWeek_Name] = 'Monday')
  OR ([DayOfWeek_Month] = 2     AND [Month_Name] = 'October'   AND [DayofWeek_Name] = 'Monday')
  OR ([Month_Name] = 'November' AND Day_of_Month = 11)
  OR ([DayOfWeek_Month] = 4     AND [Month_Name] = 'November' AND [DayofWeek_Name] = 'Thursday')
  OR ([Month_Name] = 'December' AND Day_of_Month = 25);



SELECT * FROM dbo.DimDate;