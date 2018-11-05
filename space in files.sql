DECLARE @TempTable TABLE
( DatabaseName varchar(128)
,recovery_model_desc varchar(50)
,DatabaseFileName varchar(500)
,FileLocation varchar(500)
,FileId int
,FileSizeMB decimal(19,2)
,SpaceUsedMB decimal(19,2)
,AvailableMB decimal(19,2)
,FreePercent decimal(19,2)
,growTSQL nvarchar(4000)
)

--Optional filter for small/unused databases at bottom

INSERT INTO @TempTable
exec sp_MSforeachdb  'use [?]; 
select *,
growTSQL = ''ALTER DATABASE [''+DatabaseName_____________ COLLATE SQL_Latin1_General_CP1_CI_AS+''] 
MODIFY FILE ( NAME = N''''''+DatabaseFileName_______ COLLATE SQL_Latin1_General_CP1_CI_AS +''''''
, '' + CASE WHEN FileSizeMB < 100 THEN ''SIZE = ''+STR(FileSizeMB+64)
			WHEN FileSizeMB < 1000 THEN ''SIZE = ''+STR(FileSizeMB+256)
			WHEN FileSizeMB < 10000 THEN ''SIZE = ''+STR(FileSizeMB+1024)
			WHEN FileSizeMB < 40000 THEN ''SIZE = ''+STR(FileSizeMB+4092)
			ELSE ''SIZE = ''+STR(FileSizeMB+(FileSizeMB*.05)) END +''MB )''
FROM (
SELECT 
  ''DatabaseName_____________'' = d.name
, Recovery			= d.recovery_model_desc
, ''DatabaseFileName_______'' = df.name
, Location			= df.physical_name
, File_ID			= df.File_ID
, FileSizeMB		= CAST(size/128.0 as Decimal(9,2))
, SpaceUsedMB		= CAST(CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0 as Decimal(9,2))
, AvailableMB		= CAST(size/128.0 - CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0 as Decimal(9,2))
, FreePercent		= CAST((((size/128.0) - (CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0)) / (size/128.0) ) * 100. as Decimal(9,2))
 FROM sys.database_files df
 CROSS APPLY sys.databases d
 WHERE d.database_id = DB_ID() 
 AND d.is_read_only = 0
 AND df.size > 0) x;
'

SELECT
    *
FROM @TempTable
--where [FreePercent] < 5  and FileSizeMB > 6 --Optional filter for small/unused databases 

ORDER BY FreePercent asc, DatabaseName, FileId

