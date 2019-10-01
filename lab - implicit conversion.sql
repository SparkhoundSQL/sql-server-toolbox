USE tempdb
GO

CREATE TABLE #ImplicitConversionTesting (
	[ID] [int] IDENTITY (1,1) NOT NULL,
	[SomeChar] [varchar](50) NOT NULL,
	[SomeNChar] [nvarchar](50) NOT NULL,
	[SomeID] [int] NOT NULL,
	[SomeDate][datetime2](7)
	CONSTRAINT PK_Implicit PRIMARY KEY (ID)
)
INSERT INTO #ImplicitConversionTesting (SomeChar, SomeNChar, SomeID, SomeDate) 
VALUES ('Whatever','Whatever',123,'1/1/2018')
GO
--Include actual execution plan
SELECT *
  FROM #ImplicitConversionTesting
  WHERE SomeID like '3%' --implicit conversion 
  --WHERE left(SomeID,1) = 3 --implicit conversion 
  --WHERE SomeDate like N'1/1/2018' --implicit conversion
  --WHERE SomeChar like N'What%' --implicit conversion
  --WHERE SomeNChar like 'What%' --no implicit conversion
GO
DROP TABLE IF EXISTS #ImplicitConversionTesting
