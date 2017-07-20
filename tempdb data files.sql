--Tempdb data files should all be the same size, same autogrowth settings
select d.name
,	CurrentSizeMb = (size*8.)/1024. --actual current windows file size
,	is_percent_growth
,	type_desc
,	GrowthMb = (growth*8.)/1024.
,	MaxFileSizeMB = CASE WHEN max_size > -1 THEN (max_size*8.)/1024. ELSE max_size END  -- -1 is unlimited
 from sys.master_files mf
inner join sys.databases d
on mf.database_id = d.database_id
where d.name = 'tempdb'-- and type_desc = 'rows'
order by size desc

