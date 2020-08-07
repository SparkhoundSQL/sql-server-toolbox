--Discover indexes that aren't helping reads but still hurting writes
--Does not show tables that have never been written to

--Cleared when SQL Server restarts. This DMV returns the service start time for both SQL Server and Azure SQL DB.
SELECT sqlserver_start_time FROM sys.dm_os_sys_info;
GO

SELECT  DatabaseName		= d.name
	,	s.object_id
	,	TableName 			= ' [' + sc.name + '].[' + o.name + ']'
    ,   IndexName			= i.name
    ,   s.user_seeks
    ,   s.user_scans
    ,   s.user_lookups
    ,   s.user_updates
	,	ps.row_count
	,	SizeMb				= cast((ps.in_row_reserved_page_count*8.)/1024. as decimal(19,2))
	,	s.last_user_lookup
	,	s.last_user_scan
	,	s.last_user_seek
	,	s.last_user_update
	,	Partition_Schema_Name = psch.[name]
	,	Partition_Number = pr.partition_number
	,	[tSQL]	= '--caution! DROP INDEX [' + i.name + '] ON [' + sc.name + '].[' + o.name + ']' --caution!!
--select object_name(object_id), * 
FROM	sys.dm_db_index_usage_stats s 
        INNER JOIN sys.objects o
			 ON o.object_id=s.object_id
		inner join sys.schemas sc
			on sc.schema_id = o.schema_id
		INNER JOIN sys.indexes i
           ON i.object_id = s.object_id
              AND i.index_id = s.index_id
		left outer join sys.partitions pr 
			on pr.object_id = i.object_id 
			and pr.index_id = i.index_id
		left outer join sys.dm_db_partition_stats ps
			on ps.object_id = i.object_id
			and ps.partition_id = pr.partition_id
		left outer join sys.partition_schemes psch 
			on psch.data_space_id = i.data_space_id
		inner join sys.databases d
			on s.database_id = d.database_id
			and db_name() = d.name
WHERE 1=1 
--Strongly recommended filters
and o.is_ms_shipped = 0
and o.type_desc = 'USER_TABLE'
and i.type_desc = 'NONCLUSTERED'
and is_unique = 0
and is_primary_key = 0
and is_unique_constraint = 0

--Optional filters
--and user_updates / 50. > (user_seeks + user_scans + user_lookups ) --arbitrary
--and o.name in ('ContactBase')
--and o.name not like '%cascade%'
--and (ps.in_row_reserved_page_count) > 1280 --10mb

order by user_seeks + user_scans + user_lookups  asc,  s.user_updates desc; --most useless indexes show up first

GO