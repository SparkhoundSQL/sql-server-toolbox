--sql2005 and above
select 
	  backuptype 
	, recovery_model_desc
	, state_desc
	, is_read_only
	, OldestLatestBackupDate = MIN(BackupDate)
FROM
(
select 
	database_name
	, backuptype 
	, d.recovery_model_desc
	, BackupDate = MAX(BackupDate)
	, d.state_desc
	, d.is_read_only
 from sys.databases d
 inner join 
	(
	select distinct 
		database_name
		, backuptype = case type	WHEN 'D' then 'Database'
								WHEN 'I' then 'Differential database'
								WHEN 'L' then 'Transaction Log'
								WHEN 'F' then 'File or filegroup'
								WHEN 'G' then 'Differential file'
								WHEN 'P' then 'Partial'
								WHEN 'Q' then 'Differential partial' END
		, BackupDate	=	MAX(backup_start_date)  	
		from msdb.dbo.backupset bs							
	group by database_name, type
	UNION 
	select distinct
		db_name(d.database_id)
		, backuptype = 'Database'
		, null
		FROM master.sys.databases d
	UNION
	select distinct
		db_name(d.database_id)
		, backuptype = 'Transaction Log'
		, null
	FROM master.sys.databases d
	where d.recovery_model_desc in ('FULL', 'BULK_LOGGED')
	
	) a
 on db_name(d.database_id) = a.database_name
 WHERE backuptype = 'transaction log'
 group by database_name, backuptype, d.recovery_model_desc, d.state_desc, d.is_read_only
) x
group by backuptype, recovery_model_desc, state_desc, is_read_only
order by backuptype, recovery_model_desc

GO

select 
	database_name
	, backuptype 
	, d.recovery_model_desc
	, BackupDate = MAX(BackupDate)
	, d.state_desc
	, d.is_read_only
 from sys.databases d
 inner join 
 (
select distinct 
	database_name
	, backuptype = case type	WHEN 'D' then 'Database'
							WHEN 'I' then 'Differential database'
							WHEN 'L' then 'Transaction Log'
							WHEN 'F' then 'File or filegroup'
							WHEN 'G' then 'Differential file'
							WHEN 'P' then 'Partial'
							WHEN 'Q' then 'Differential partial' END
	, BackupDate	=	MAX(backup_start_date)  	
	from msdb.dbo.backupset bs							
 group by database_name, type
 UNION 
 select distinct
	db_name(d.database_id)
	, backuptype = 'Database'
	, null
	FROM master.sys.databases d
 UNION
 select distinct
	db_name(d.database_id)
	, backuptype = 'Transaction Log'
	, null
  FROM master.sys.databases d
  where d.recovery_model_desc in ('FULL', 'BULK_LOGGED')
  
 ) a
 on db_name(d.database_id) = a.database_name
 --WHERE backuptype = 'transaction log'
 group by database_name, backuptype, d.recovery_model_desc, d.state_desc, d.is_read_only
