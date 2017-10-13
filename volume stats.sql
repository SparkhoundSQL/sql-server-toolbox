

select 
  volume_letter = UPPER(vs.volume_mount_point)
, file_system_type
, drive_size_GB = MAX(CONVERT(decimal(19,2), vs.total_bytes/1024./1024./1024. ))
, drive_free_space_GB = MAX(CONVERT(decimal(19,2), vs.available_bytes/1024./1024./1024. ))
, drive_percent_free = MAX(CONVERT(DECIMAL(5,2), vs.available_bytes * 100.0 / vs.total_bytes))
FROM
   sys.master_files AS f CROSS APPLY
   sys.dm_os_volume_stats(f.database_id, f.file_id) vs --only return volumes where there is database file (data or log)
 GROUP BY vs.volume_mount_point, vs.file_system_type
 ORDER BY volume_letter 
 
--exec xp_fixeddrives


/*

E:\	NTFS	300.00	152.94	50.98
F:\	NTFS	300.00	84.08	28.03
*/