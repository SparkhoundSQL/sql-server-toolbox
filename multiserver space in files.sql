use master
go
exec sp_MSforeachdb  'use [?]; 
select * from (
SELECT 
  ''DatabaseName_____________'' = d.name
, Recovery = d.recovery_model_desc
, ''DatabaseFileName_______'' = df.name
, ''Location_______________________________________________________________________'' = df.physical_name
, df.File_ID
, FileSizeMB = CAST(size/128.0 as Decimal(9,2))
, SpaceUsedMB = CAST(CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0 as Decimal(9,2))
, AvailableMB =  CAST(size/128.0 - CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0 as Decimal(9,2))
, ''Free%'' = CAST((((size/128.0) - (CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0)) / NULLIF(size/128.0, 0) ) * 100. as Decimal(9,2))
 FROM sys.database_files df
 cross apply sys.databases d
 where d.database_id = DB_ID() 
  and size > 0
 and d.name not like ''%test%''
 ) x
 where [Free%] <= 10.
 and filesizemb > 500.
 and availableMB < 500.
 
'