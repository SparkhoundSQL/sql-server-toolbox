--use w
go
DROP TABLE dbo.DimDate 
GO
CREATE TABLE dbo.DimDate  (
    [dimDateID]       INT          NOT NULL,
    [CalendarDate]    DATE         NOT NULL,
    [Day_of_Month]    TINYINT      NOT NULL,
    [Day_of_Year]     SMALLINT     NOT NULL,
    [Day_of_Week]     TINYINT      NOT NULL,
    [Year]            SMALLINT     NOT NULL,
    [Quarter]         CHAR (2)     NOT NULL,
    [Month]           TINYINT      NOT NULL,
    [Month_Name]      VARCHAR (30) NOT NULL,
    [Week_of_Year]    TINYINT      NOT NULL,
    [DayofWeek_Name]  VARCHAR (30) NOT NULL,
    [ISOWeek_of_Year] TINYINT      NOT NULL,
    [IsWeekend]       CHAR (3)     NOT NULL,
    CONSTRAINT [PK_WH_DimDate] PRIMARY KEY NONCLUSTERED ([CalendarDate] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [IDX_NC_DimDate_dimDateID] UNIQUE CLUSTERED ([dimDateID] ASC) WITH (DATA_COMPRESSION = PAGE)
) 

go

;with cteDate (seeddate) as
	(
	select seeddate = convert(date, '10/1/2008') 
	UNION ALL
	select dateadd(day, 1, seeddate) 
	from cteDate
	where seeddate < '1/1/2050'
	) 

	insert into dbo.DimDate (dimDateID, CalendarDate, Day_of_Month, Day_of_Year, Day_of_Week, Year, Quarter, Month, Month_Name, Week_of_Year, DayofWeek_Name, ISOWeek_of_Year, IsWeekend)
		select 
			dimDateID		=	convert(int,convert(varchar(8),seeddate, 112))
		,	CalendarDate	=	seeddate
		,	Day_of_Month	=	DatePart(d, seeddate)
		,	Day_of_Year		=	DatePart(dy, seeddate)
		,	Day_of_Week		=	DatePart(dw, seeddate)
		,	[Year]			=	DatePart(yyyy, seeddate)
		,	[Quarter]		=	'Q' + Convert(char(1), datepart(quarter , seeddate))
		,	[Month]			=	DatePart(M, seeddate)
		,	[Month_Name]	=	DateName(m, seeddate) 
		,	Week_of_Year	=	DatePart(week, seeddate) 
		,	DayofWeek_Name	=	DateName(dw, seeddate) 
		,	ISOWeek_of_Year	=	DatePart(ISO_WEEK, seeddate) 
		,	IsWeekend		=	CASE WHEN DatePart(dw, seeddate) in (1,7) THEN 'Yes' ELSE 'No' END
		
		from cteDate
		where seeddate < '1/1/2050'
OPTION (MAXRECURSION 0)
go


select * from dimdate