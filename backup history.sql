use master
go
--sql2005 and above
select 
	  a.database_name
	, a.backuptype 
	, d.recovery_model_desc
	, LatestBackupDate = max(a.BackupFinishDate)
	, LatestBackupStartDate = max(a.BackupStartDate)
	, LatestBackupLocation = max(a.physical_device_name)
	, d.state_desc
 from sys.databases d
 inner join (	select * from (
						select  
						  database_name
						, backuptype = case type	WHEN 'D' then 'Database'
												WHEN 'I' then 'Differential database'
												WHEN 'L' then 'Transaction Log'
												WHEN 'F' then 'File or filegroup'
												WHEN 'G' then 'Differential file'
												WHEN 'P' then 'Partial'
												WHEN 'Q' then 'Differential partial' END
						, BackupFinishDate	=	bs.backup_finish_date
						, BackupStartDate	=	bs.backup_start_date
						, physical_device_name 
						, latest = Row_number() OVER (PARTITION BY database_name, type order by backup_finish_date desc)
						from msdb.dbo.backupset bs					
						left outer join msdb.dbo.[backupmediafamily] bf
						on bs.[media_set_id] = bf.[media_set_id]	
						WHERE backup_finish_date is not null 
						) x
						where latest = 1
					 UNION 
					 select 
						db_name(d.database_id)
						, backuptype = 'Database'
						, null, null, null, null
						FROM master.sys.databases d
						group by db_name(d.database_id)
					 UNION
					 select 
						db_name(d.database_id)
						, backuptype = 'Transaction Log'
						, null, null, null, null
					  FROM master.sys.databases d
					  where d.recovery_model_desc in ('FULL', 'BULK_LOGGED')
					  group by db_name(d.database_id)
 ) a
 on db_name(d.database_id) = a.database_name
 WHERE a.database_name not in ('tempdb')
group by 
	  a.database_name
	, a.backuptype 
	, d.recovery_model_desc
	, d.state_desc
order by a.backuptype, d.recovery_model_desc, max(a.BackupFinishDate) asc, a.database_name asc
 
 go
 

 /*

 
 select d.name, Latest_Restore = max(restore_date)
	from sys.databases d
	LEFT OUTER JOIN msdb.dbo.restorehistory rh on d.name = rh.destination_database_name
	group by d.name
	order by Latest_Restore desc

 --sql 2000 and above
select distinct 
	database_name	= d.name 
	, a.backuptype	
	, RecoveryModel	=	databasepropertyex(d.name, 'Recovery')  
	, BackupDate	=	Max(a.backup_finish_date)  
	from master.dbo.sysdatabases d
	left outer join 
	(		select distinct 
			database_name
			, backuptype = case type	WHEN 'D' then 'Database'
									WHEN 'I' then 'Differential database'
									WHEN 'L' then 'Transaction Log'
									WHEN 'F' then 'File or filegroup'
									WHEN 'G' then 'Differential file'
									WHEN 'P' then 'Partial'
									WHEN 'Q' then 'Differential partial' END
			, backup_finish_date	=	MAX(backup_finish_date)  	
			from msdb.dbo.backupset bs							
		 group by Database_name, type
		 UNION 
		 select distinct
			  d.name
			, backuptype = 'Database'
			, null
			FROM master.dbo.sysdatabases d
		 UNION
		 select distinct
			  d.name
			, backuptype = 'Transaction Log'
			, null
		  FROM master.dbo.sysdatabases d
		  where databasepropertyex(d.name, 'Recovery') in ('FULL', 'BULK_LOGGED')
  
 ) a
	on d.name = a.database_name
 group by d.name , backuptype ,	databasepropertyex(d.name, 'Recovery')
order by backuptype, RecoveryModel, BackupDate asc
 */

 /*
--granular backup history
SELECT 
	database_name
	, type
	, backuptype = CASE bs.type WHEN 'D' then 'Database'
							WHEN 'I' then 'Differential database'
							WHEN 'L' then 'Transaction Log'
							WHEN 'F' then 'File or filegroup'
							WHEN 'G' then 'Differential file'
							WHEN 'P' then 'Partial'
							WHEN 'Q' then 'Differential partial' END
	, BackupDate	=	backup_finish_date
	, database_backup_lsn
	, bf.physical_device_name
	, begins_log_chain
	, backup_size_mb			=	bs.backup_size / 1024./1024.
	, compressed_backup_size_mb =	bs.compressed_backup_size /1024./1024.
	, bs.is_copy_only	
	, bs.recovery_model
	FROM msdb.dbo.backupset bs	
	LEFT OUTER JOIN msdb.dbo.[backupmediafamily] bf
	on bs.[media_set_id] = bf.[media_set_id]
	where database_name = 'SP2010_UserProfile_Sync'
	ORDER BY bs.database_name asc, BackupDate desc;
  
  select convert(Date, backup_finish_date), SizeGB = sum(compressed_backup_size)/1024./1024./1024.
  from msdb.dbo.backupset bs	
	left outer join msdb.dbo.[backupmediafamily] bf
	on bs.[media_set_id] = bf.[media_set_id]
	where 1=1 
	and datepart(dw, backup_finish_date) = 1
  group by convert(Date, backup_finish_date)
  order by convert(Date, backup_finish_date) desc
  

*/