--This version of backup history.sql only looks for problematic backup gaps, etc.
--Includes filters for a lack of recent backups
--Include AG group status. Be aware of the AG's replica backup preference, make sure backups are happening somewhere. They may not happen on the PRIMARY.

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

 --below is SQL 2012+
 LEFT OUTER JOIN ( SELECT  database_id 
						 ,	Replica_Role		= CASE WHEN database_state_desc IS NOT NULL and last_received_time is null THEN 'PRIMARY '
															WHEN database_state_desc IS NOT NULL and last_received_time is not null THEN 'SECONDARY' 
															ELSE null END
															from sys.dm_hadr_database_replica_states) dm
						 on dm.database_id = a.database_id

WHERE database_name not in ('model','tempdb')
and state_desc <> 'offline'
and not (backuptype = 'transaction log' and recovery_model_desc = 'SIMPLE')
 group by database_name, backuptype, d.recovery_model_desc, d.state_desc, d.is_read_only, dm.replica_role

 having ( 
			(   max(backupdate) <= dateadd(week,-1,getdate()) 
				and backuptype = 'database'
			) 
			or 
			(   max(backupdate) <= dateadd(hour,-3,getdate()) 
				and backuptype = 'transaction log'
			) 
			or (	max(backupdate) is null		)
		)
order by backuptype, recovery_model_desc, database_name asc
go



--Look for tlog backups to NUL, a sign that someone doesn't know what they're doing to the tlog. (Probably VEEAM)

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