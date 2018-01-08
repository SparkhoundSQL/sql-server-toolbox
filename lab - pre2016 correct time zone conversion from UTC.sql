--This lab demonstrates a common antipattern for converting UTC to the local timezone.

declare @audit_created table 
(audit_created datetime2(0))

insert into @audit_created (audit_created) 
values 
 ('3/12/2017 03:00')
,('3/12/2017 04:00')
,('3/12/2017 05:00') --This will be wrong in the the Incorrect pre2016 method if we are currently in DST (March-Nov)
,('3/12/2017 06:00')
,('3/12/2017 07:00')
,('3/12/2017 08:00')
,('3/12/2017 09:00')
,('11/5/2017 03:00')
,('11/5/2017 04:00')
,('11/5/2017 05:00') --This will be wrong in the the Incorrect pre2016 method if we are currently not in DST (Nov-March)
,('11/5/2017 06:00')
,('11/5/2017 07:00')
,('11/5/2017 08:00')
,('11/5/2017 09:00')
,('1/1/2017 05:00') --One of these two rows will be wrong for Central US Time in the Incorrect pre2016 method. It'll be the one that doesn't match our CURRENT DST setting.
,('6/1/2017 05:00') --One of these two rows will be wrong for Central US Time in the Incorrect pre2016 method. It'll be the one that doesn't match our CURRENT DST setting.

select			
	audit_created
,	audit_created_actually_at_UTC	= TODATETIMEOFFSET(audit_created, 0)
,   Incorrect_pre2016_method		=	DATEADD(second, DATEDIFF(second, GETUTCDATE(), GETDATE()), audit_created )
,   Incorrect_pre2016_method_date	=	CONVERT(date, DATEADD(second, DATEDIFF(second, GETUTCDATE(), GETDATE()), audit_created ))
,	Correct_pre2016_method				=	
	SWITCHOFFSET(TODATETIMEOFFSET(audit_created, 0), DATEPART(TZoffset, SYSDATETIMEOFFSET()) + CASE WHEN EXISTS (select * from dbo.DSTDates where BeginDate<=TODATETIMEOFFSET(audit_created, 0) and EndDate>TODATETIMEOFFSET(audit_created, 0)) THEN 60 ELSE 0 END) 
,	Correct_pre2016_method_date		=	CONVERT(DATE, 
	SWITCHOFFSET(TODATETIMEOFFSET(audit_created, 0), DATEPART(TZoffset, SYSDATETIMEOFFSET()) + CASE WHEN EXISTS (select * from dbo.DSTDates where BeginDate<=TODATETIMEOFFSET(audit_created, 0) and EndDate>TODATETIMEOFFSET(audit_created, 0)) THEN 60 ELSE 0 END) 
	)

--Uncomment the following two rows for the right way to do this in SQL 2016+
--,    Correct_2016_method			=   audit_created  AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time'
--,    Correct_2016_method__date		=	convert(date,  (audit_created AT TIME ZONE 'UTC'  AT TIME ZONE 'Central Standard Time'))
from @audit_created as A


/*


DROP TABLE dbo.DSTDates 
 CREATE TABLE dbo.DSTDates
 (	BeginDate datetimeoffset(0)
 ,	EndDate datetimeoffset(0)
 )
 GO
 CREATE CLUSTERED INDEX IDX_CL_DSTDates on dbo.DSTDates (BeginDate, EndDate)
 CREATE NONCLUSTERED INDEX IDX_NC_DSTDates on dbo.DSTDates (BeginDate, EndDate) 
 GO
  INSERT INTO dbo.DSTDates (BeginDate, EndDate)
VALUES 
 ('4/26/1970 02:00 -06:00','10/25/1970 02:00 -05:00'),
('4/25/1971 02:00 -06:00','10/31/1971 02:00 -05:00'),
('4/30/1972 02:00 -06:00','10/29/1972 02:00 -05:00'),
('4/29/1973 02:00 -06:00','10/28/1973 02:00 -05:00'),
('1/6/1974 02:00 -06:00','10/27/1974 02:00 -05:00'),
('2/23/1975 02:00 -06:00','10/26/1975 02:00 -05:00'),
('4/25/1976 02:00 -06:00','10/31/1976 02:00 -05:00'),
('4/24/1977 02:00 -06:00','10/30/1977 02:00 -05:00'),
('4/30/1978 02:00 -06:00','10/29/1978 02:00 -05:00'),
('4/29/1979 02:00 -06:00','10/28/1979 02:00 -05:00'),
('4/27/1980 02:00 -06:00','10/26/1980 02:00 -05:00'),
('4/26/1981 02:00 -06:00','10/25/1981 02:00 -05:00'),
('4/25/1982 02:00 -06:00','10/31/1982 02:00 -05:00'),
('4/24/1983 02:00 -06:00','10/30/1983 02:00 -05:00'),
('4/29/1984 02:00 -06:00','10/28/1984 02:00 -05:00'),
('4/28/1985 02:00 -06:00','10/27/1985 02:00 -05:00'),
('4/27/1986 02:00 -06:00','10/26/1986 02:00 -05:00'),
('4/5/1987 02:00 -06:00','10/25/1987 02:00 -05:00'),
('4/3/1988 02:00 -06:00','10/30/1988 02:00 -05:00'),
('4/2/1989 02:00 -06:00','10/29/1989 02:00 -05:00'),
('4/1/1990 02:00 -06:00','10/28/1990 02:00 -05:00'),
('4/7/1991 02:00 -06:00','10/27/1991 02:00 -05:00'),
('4/5/1992 02:00 -06:00','10/25/1992 02:00 -05:00'),
('4/4/1993 02:00 -06:00','10/31/1993 02:00 -05:00'),
('4/3/1994 02:00 -06:00','10/30/1994 02:00 -05:00'),
('4/2/1995 02:00 -06:00','10/29/1995 02:00 -05:00'),
('4/7/1996 02:00 -06:00','10/27/1996 02:00 -05:00'),
('4/6/1997 02:00 -06:00','10/26/1997 02:00 -05:00'),
('4/5/1998 02:00 -06:00','10/25/1998 02:00 -05:00'),
('4/4/1999 02:00 -06:00','10/31/1999 02:00 -05:00'),
('4/2/2000 02:00 -06:00','10/29/2000 02:00 -05:00'),
('4/1/2001 02:00 -06:00','10/28/2001 02:00 -05:00'),
('4/7/2002 02:00 -06:00','10/27/2002 02:00 -05:00'),
('4/6/2003 02:00 -06:00','10/26/2003 02:00 -05:00'),
('4/4/2004 02:00 -06:00','10/31/2004 02:00 -05:00'),
('4/3/2005 02:00 -06:00','10/30/2005 02:00 -05:00'),
('4/2/2006 02:00 -06:00','10/29/2006 02:00 -05:00'),
('3/11/2007 02:00 -06:00','11/4/2007 02:00 -05:00'),
('3/9/2008 02:00 -06:00','11/2/2008 02:00 -05:00'),
('3/8/2009 02:00 -06:00','11/1/2009 02:00 -05:00'),
('3/14/2010 02:00 -06:00','11/7/2010 02:00 -05:00'),
('3/13/2011 02:00 -06:00','11/6/2011 02:00 -05:00'),
('3/11/2012 02:00 -06:00','11/4/2012 02:00 -05:00'),
('3/10/2013 02:00 -06:00','11/3/2013 02:00 -05:00'),
('3/9/2014 02:00 -06:00','11/2/2014 02:00 -05:00'),
('3/8/2015 02:00 -06:00','11/1/2015 02:00 -05:00'),
('3/13/2016 02:00 -06:00','11/6/2016 02:00 -05:00'),
('3/12/2017 02:00 -06:00','11/5/2017 02:00 -05:00'),
('3/11/2018 02:00 -06:00','11/4/2018 02:00 -05:00'),
('3/10/2019 02:00 -06:00','11/3/2019 02:00 -05:00'),
('3/8/2020 02:00 -06:00','11/1/2020 02:00 -05:00'),
('3/14/2021 02:00 -06:00','11/7/2021 02:00 -05:00'),
('3/13/2022 02:00 -06:00','11/6/2022 02:00 -05:00'),
('3/12/2023 02:00 -06:00','11/5/2023 02:00 -05:00'),
('3/10/2024 02:00 -06:00','11/3/2024 02:00 -05:00'),
('3/9/2025 02:00 -06:00','11/2/2025 02:00 -05:00'),
('3/8/2026 02:00 -06:00','11/1/2026 02:00 -05:00'),
('3/14/2027 02:00 -06:00','11/7/2027 02:00 -05:00'),
('3/12/2028 02:00 -06:00','11/5/2028 02:00 -05:00'),
('3/11/2029 02:00 -06:00','11/4/2029 02:00 -05:00'),
('3/10/2030 02:00 -06:00','11/3/2030 02:00 -05:00'),
('3/9/2031 02:00 -06:00','11/2/2031 02:00 -05:00'),
('3/14/2032 02:00 -06:00','11/7/2032 02:00 -05:00')

*/