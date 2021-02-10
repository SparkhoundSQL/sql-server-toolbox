--BEWARE running this script on production can harm performance by hammering IO.
--Run in each database, shows data per table. 

--Using ALTER INDEX ALL as in this example isn't efficient. 
--This simple script averages fragmentation for all indexes/partitions on a table. Instead, consider index-level or index+partition-level REBUILDs.

--See also \toolbox\automated index rebuild.sql
--See also \toolbox\defrag columnstore.sql
--See also \toolbox\tables without clustered indexes.sql

--Consider also DATA_COMPRESSION, ONLINE, MAXDOP options
--	WITH (MAXDOP = 1, ONLINE = ON);

--Defrag on Tables, ignoring indexes and partitions
SELECT 
	Object						=	x.[schema_name] + '.' + x.[table_name]	
,	SQL_Reorg					=	'ALTER INDEX ALL ON ' + x.DB + '.' + x.[schema_name] + '.' + x.[table_name] + ' REORGANIZE; 
										UPDATE STATISTICS ' + x.DB + '.' + x.[schema_name] + '.' + x.[table_name]  + ';'
,	SQL_Rebuild					=	'ALTER INDEX ALL ON ' + x.DB + '.' + x.[schema_name] + '.' + x.[table_name] + ' REBUILD '+
									'WITH (ONLINE = ON, SORT_IN_TEMPDB = ON);'  
,	max_fragmentation_pct		=	MAX(avg_fragmentation_pct) -- Use the highest amount of fragmentation we find in any index on a table.
,	avg_fragmentation_pct		=	AVG(avg_fragmentation_pct) -- Use the avg amount of fragmentation we find across all indexes 
,	page_count					=	SUM(convert(bigint, page_count))
,	partition_count				=	MAX(partition_count)
,	row_count					=	MAX([rows])
FROM (	SELECT 
		  DB					= db_name(s.database_id)
		, [schema_name]			= sc.name
		, [table_name]			= o.name
		, index_name			= i.name
		, s.index_type_desc
		, p.partition_number
		, avg_fragmentation_pct = s.avg_fragmentation_in_percent
		, s.page_count
		, i.index_id
		, pa.partition_count
		, p.rows
		--select * 
		from sys.indexes as i 
		inner join sys.partitions p on p.index_id = i.index_id and p.object_id = i.object_id
		inner join (select partition_count = count (*), object_id, index_id from sys.partitions group by object_id, index_id) as pa
				on  pa.object_id = i.object_id AND pa.index_id = i.index_id 		
		CROSS APPLY sys.dm_db_index_physical_stats (DB_ID(),i.object_id,i.index_id, null,'limited') as s
		INNER JOIN sys.objects as o ON o.object_id = s.object_id
		INNER JOIN sys.schemas as sc ON o.schema_id = sc.schema_id
		WHERE i.is_disabled = 0
		AND	alloc_unit_type_desc <> 'LOB_DATA'
		AND o.object_id not in (select object_id from sys.indexes where index_id = 0) -- This table is a heap and probably needs a clustered index. Rebuilding will do no good. Ignore. 
	) x
GROUP BY x.DB , x.[schema_name] , x.[table_name]
HAVING 1=1
--AND	SUM(page_count) > 1280 --1280 pages is 10mb, ignore anything smaller
--AND AVG(avg_fragmentation_pct) > 50 
--ORDER BY  avg_fragmentation_pct desc, page_count desc;
ORDER BY SQL_Reorg


--Defrag on tables per each index and partition
SELECT 
	Object						=	x.[schema_name] + '.' + x.[table_name]	
,	SQL_Reorg					=	'ALTER INDEX ALL ON ' + x.DB + '.' + x.[schema_name] + '.' + x.[table_name] + ' REORGANIZE; 
										UPDATE STATISTICS ' + x.DB + '.' + x.[schema_name] + '.' + x.[table_name]  + ';'
,	SQL_Rebuild					=	'ALTER INDEX ALL ON ' + x.DB + '.' + x.[schema_name] + '.' + x.[table_name] + ' REBUILD '+
									CASE WHEN partition_count > 1 THEN ' PARTITION=' + RTRIM(CONVERT (CHAR(4), partition_number)) + ' ' ELSE ' ' END
									+'WITH (ONLINE = ON, SORT_IN_TEMPDB = ON);'  
,	max_fragmentation_pct		=	MAX(avg_fragmentation_pct) -- Use the highest amount of fragmentation we find in any index on a table.
,	avg_fragmentation_pct		=	AVG(avg_fragmentation_pct) -- Use the avg amount of fragmentation we find across all indexes 
,	page_count					=	(convert(bigint, page_count))
,	index_name					
,	partition_count				=	partition_count
,	partition_number			=	partition_number
,	row_count					=	[rows]
FROM (	SELECT 
		  DB					= db_name(s.database_id)
		, [schema_name]			= sc.name
		, [table_name]			= o.name
		, index_name			= i.name
		, s.index_type_desc
		, p.partition_number
		, avg_fragmentation_pct = s.avg_fragmentation_in_percent
		, s.page_count
		, i.index_id
		, pa.partition_count
		, p.rows
		--select * 
		from sys.indexes as i 
		inner join sys.partitions p on p.index_id = i.index_id and p.object_id = i.object_id
		inner join (select partition_count = count (*), object_id, index_id from sys.partitions group by object_id, index_id) as pa
				on  pa.object_id = i.object_id AND pa.index_id = i.index_id 		
		CROSS APPLY sys.dm_db_index_physical_stats (DB_ID(),i.object_id,i.index_id, null,'limited') as s
		INNER JOIN sys.objects as o ON o.object_id = s.object_id
		INNER JOIN sys.schemas as sc ON o.schema_id = sc.schema_id
		WHERE i.is_disabled = 0
		AND	alloc_unit_type_desc <> 'LOB_DATA'
		AND o.object_id not in (select object_id from sys.indexes where index_id = 0) -- This table is a heap and probably needs a clustered index. Rebuilding will do no good. Ignore. 
	) x
GROUP BY x.DB , x.[schema_name] , x.[table_name], x.page_count,  x.partition_number, x.partition_count, x.[rows], x.index_name
HAVING 1=1
--AND	SUM(page_count) > 1280 --1280 pages is 10mb, ignore anything smaller
--AND AVG(avg_fragmentation_pct) > 50 
--ORDER BY  avg_fragmentation_pct desc, page_count desc;
ORDER BY SQL_Reorg
 

 