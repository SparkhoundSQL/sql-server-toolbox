use master
go
--sql2005 and above

--Look for gaps, omissions in the backups. A granular database backup history is below.
select 
	  a.database_name
	, a.backuptype 
	, d.recovery_model_desc
	, LatestBackupStartDate = max(a.BackupStartDate)
	, LatestBackupFinishDate = max(a.BackupFinishDate)
	, LatestBackupLocation = max(a.physical_device_name)
	, backup_size_mb			 = max(backup_size_mb)
	, compressed_backup_size_mb	 = max(compressed_backup_size_mb)
	, d.state_desc
	, d.create_date
 from sys.databases d
 inner join (	select * from (
						select  
						  database_name
						, backuptype = case type	WHEN 'D' then 'Full Database Backup'
												WHEN 'I' then 'Differential database backup'
												WHEN 'L' then 'Transaction Log Backup'
												WHEN 'F' then 'File or filegroup'
												WHEN 'G' then 'Differential file'
												WHEN 'P' then 'Partial'
												WHEN 'Q' then 'Differential partial' END
						, BackupFinishDate	=	bs.backup_finish_date
						, BackupStartDate	=	bs.backup_start_date
						, physical_device_name 
						, backup_size_mb			=	bs.backup_size / 1024./1024.
						, compressed_backup_size_mb =	bs.compressed_backup_size /1024./1024.
	
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
						, backuptype = 'Full Database Backup'
						, null, null, null, null, null, null
						FROM master.sys.databases d
						group by db_name(d.database_id)
					 UNION
					 select 
						db_name(d.database_id)
						, backuptype = 'Transaction Log Backup'
						, null, null, null, null, null, null
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
	, d.create_date
order by a.backuptype, d.recovery_model_desc, max(a.BackupFinishDate) asc, a.database_name asc
 go
 

 /*
--for SQL 2000 and above
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
									WHEN 'I' then 'Differential database backup'
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
 
--granular backup history
SELECT 
		bs.database_name
	, backuptype = CASE 
							WHEN bs.type = 'D' and bs.is_copy_only = 0 then 'Full Database'
							WHEN bs.type = 'D' and bs.is_copy_only = 1 then 'Full Copy-Only Database'
							WHEN bs.type = 'I' then 'Differential database backup'
							WHEN bs.type = 'L' then 'Transaction Log'
							WHEN bs.type = 'F' then 'File or filegroup'
							WHEN bs.type = 'G' then 'Differential file'
							WHEN bs.type = 'P' then 'Partial'
							WHEN bs.type = 'Q' then 'Differential partial' END + ' Backup'
	, bs.recovery_model
	, BackupStartDate = bs.Backup_Start_Date
	, BackupFinishDate = bs.Backup_Finish_Date
	, LatestBackupLocation = bf.physical_device_name
	, backup_size_mb			=	bs.backup_size / 1024./1024.
	, compressed_backup_size_mb =	bs.compressed_backup_size /1024./1024.
	, database_backup_lsn -- For tlog and differential backups, this is the checkpoint_lsn of the FULL backup it is based on. 
	, checkpoint_lsn
	, begins_log_chain
	FROM msdb.dbo.backupset bs	
	LEFT OUTER JOIN msdb.dbo.[backupmediafamily] bf
	on bs.[media_set_id] = bf.[media_set_id]
	--where database_name = 'w'
	ORDER BY  bs.database_name asc, bs.Backup_Start_Date desc;
 

 
 /*
  --Latest Restore
 select d.name, Latest_Restore = max(restore_date)
	from sys.databases d
	LEFT OUTER JOIN msdb.dbo.restorehistory rh on d.name = rh.destination_database_name
	group by d.name
	order by Latest_Restore desc

*/
