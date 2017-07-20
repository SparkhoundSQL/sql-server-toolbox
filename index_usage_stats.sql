

SELECT  [tSQL]				= 'DROP INDEX [' + i.name + '] ON [' + sc.name + '].[' + o.name + ']'
	,	o.name
    ,   IndexName			= i.name
    ,   s.user_seeks
    ,   s.user_scans
    ,   s.user_lookups
    ,   s.user_updates
	,	ps.row_count
	,	SizeMb				= (ps.in_row_reserved_page_count*8.)/1024.
	,	s.last_user_lookup
	,	s.last_user_scan
	,	s.last_user_seek
	,	s.last_user_update
FROM sys.dm_db_index_usage_stats s 
         INNER JOIN sys.indexes i
           ON i.object_id = s.object_id
              AND i.index_id = s.index_id
		  INNER JOIN sys.objects o
			 ON o.object_id=i.object_id
		inner join sys.schemas sc
			on sc.schema_id = o.schema_id
		inner join sys.partitions pr 
			on pr.object_id = i.object_id 
			and pr.index_id = i.index_id
		inner join sys.dm_db_partition_stats ps
			on ps.object_id = i.object_id
			and ps.partition_id = pr.partition_id
WHERE    o.is_ms_shipped = 0
--and o.type_desc = 'USER_TABLE'
and i.type_desc = 'NONCLUSTERED'
--and user_updates / 5. > (user_seeks + user_scans + user_lookups )
--and o.name in ('ContactBase')
--and o.name not like '%cascade%'
--order by [OBJECT NAME]
and is_unique = 0
and is_primary_key = 0
and is_unique_constraint = 0
--and (ps.in_row_reserved_page_count) > 1280 --10mb
order by user_seeks + user_scans + user_lookups  asc,  s.user_updates desc

