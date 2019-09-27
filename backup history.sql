--Looks for a complete backup history, displaying the latest backup of each type.

--See also toolbox/multiserver backup history.sql for health checks.

use master
go
--sql2012 and above
select 
	database_Name
	, backuptype 
	, d.recovery_model_desc
	, BackupDate = MAX(BackupDate)
	, d.state_desc
	, d.is_read_only
	, dm.Replica_Role		--SQL 2012+
 from sys.databases d
 inner join 
 (
select distinct 
	database_name
	, database_id = db_id(database_name)
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
	, d.database_id
	, backuptype = 'Database'
	, null
	FROM master.sys.databases d
 UNION
 select distinct
	db_name(d.database_id)
	, d.database_id
	, backuptype = 'Transaction Log'
	, null
  FROM master.sys.databases d
  where d.recovery_model_desc in ('FULL', 'BULK_LOGGED')
 ) a
 on d.database_id = a.database_id
 
 --SQL 2012+
 LEFT OUTER JOIN ( SELECT  database_id 
						 ,	Replica_Role		= CASE WHEN database_state_desc IS NOT NULL and last_received_time is null THEN 'PRIMARY '
															WHEN database_state_desc IS NOT NULL and last_received_time is not null THEN 'SECONDARY' 
															ELSE null END
															from sys.dm_hadr_database_replica_states) dm
						 on dm.database_id = a.database_id
WHERE database_name not in ('model','tempdb')
and not (backuptype = 'transaction log' and recovery_model_desc = 'SIMPLE')
group by database_name, backuptype, d.recovery_model_desc, d.state_desc, d.is_read_only, dm.replica_role
order by backuptype, recovery_model_desc, database_name asc
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


--Look for backups to NUL, a sign that someone doesn't know what they're doing to the tlog. (Probably VEEAM. Bad VEEAM.)
--This is bad. Backup to NUL is just truncating the log without backing up the log, breaking the tlog chain. Any subsequent tlog backups are broken until a FULL backup restarts a valid chain.
--Do not allow VEEAM or other VSS-based backup solutions to do backups to NUL. 
--In VEEAM, this is somewhere near the "application aware backups" or similar settings menu in various settings. Disable this. 
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
	where bf.physical_device_name = 'NUL'
	ORDER BY  bs.database_name asc, bs.Backup_Start_Date desc;
