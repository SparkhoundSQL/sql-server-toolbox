--sql2005 and above
select 
	database_Name
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
	, BackupDate	=	MAX(backup_finish_date)  	
	from msdb.dbo.backupset bs							
 group by Database_name, type
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
 where database_name not in ('model','tempdb')
 group by database_name, backuptype, d.recovery_model_desc, d.state_desc
	, d.is_read_only
 having ( (max(backupdate) <= dateadd(day,-1,getdate()) and (max(backupdate) >= dateadd(month, -1, getdate())) ) or max(backupdate) is null)
order by backuptype, recovery_model_desc, database_name asc
 
 go