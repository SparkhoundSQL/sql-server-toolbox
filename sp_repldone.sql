select name, log_reuse_wait, log_reuse_Wait_desc from sys.databases where name = 'DataWarehouse'
go
use DataWarehouse
go

SELECT 
  'DatabaseName_____________' = d.name
, Recovery = d.recovery_model_desc
, 'DatabaseFileName_______' = df.name
, 'Location_______________________________________________________________________' = df.physical_name
, df.File_ID
, FileSizeMB = CAST(size/128.0 as Decimal(9,2))
, SpaceUsedMB = CAST(CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS int)/128. as Decimal(9,2))
, AvailableMB =  CAST(size/128.0 - CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS int)/128.0 as Decimal(9,2))
, 'Free%' = CAST((((size/128.0) - (CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS int)/128.0)) / (size/128.0) ) * 100. as Decimal(9,2))
 FROM sys.database_files df
 cross apply sys.databases d
 where d.database_id = DB_ID() 

 /*
 --If log_reuse_wait_desc = 'REPLICATION' 
 --and the log file is growing unchecked
 --and you are aware of the consequences to replication with sp_repldone (especially to transactional/merge repl), then proceed.
 --Should be just fine if only snapshot repl.
 --This marks all pending transactions as having been Replicated. It could intentionally be used to tell replication to skip over transactions, not send them to subscribers.

 use DataWarehouse
 go
  exec sp_repldone null, null, 0,0,1
 GO
 CHECKPOINT
 GO

 */