--BEWARE running this script on production can harm performance by hammering IO.
--Run in each database, shows data per table. 

--Using ALTER INDEX ALL as in this example isn't efficient. 
--This script averages fragmentation for all indexes/partitions on a table. Instead, consider index-level or index+partition-level REBUILDs.

--See also \toolbox\automated index rebuild.sql
--See also \toolbox\defrag columnstore.sql
--See also \toolbox\tables without clustered indexes.sql

--Consider also DATA_COMPRESSION, ONLINE, MAXDOP options
--	WITH (MAXDOP = 1, ONLINE = ON);

SELECT DISTINCT
	SQL_Reorg					=	'ALTER INDEX ALL ON ' + x.DB + '.' + x.[schema_name] + '.' + x.[table_name] + ' REORGANIZE; 
										UPDATE STATISTICS ' + x.DB + '.' + x.[schema_name] + '.' + x.[table_name]  + ';'
,	SQL_Rebuild					=	'ALTER INDEX ALL ON ' + x.DB + '.' + x.[schema_name] + '.' + x.[table_name] + ' REBUILD WITH (ONLINE = ON, SORT_IN_TEMPDB = ON);'  
,	max_fragmentation_pct		=	MAX(avg_fragmentation_pct) -- Use the highest amount of fragmentation we find in any index on a table.
,	avg_fragmentation_pct		=	AVG(avg_fragmentation_pct) -- Use the avg amount of fragmentation we find across all indexes 
,	page_count					=	SUM(page_count)
,	number_of_indexes			=	COUNT(index_id) 
FROM (	SELECT 
		  DB					= db_name(s.database_id)
		, [schema_name]			= sc.name
		, [table_name]			= o.name
		, index_name			= i.name
		, s.index_type_desc
		, s.partition_number
		, avg_fragmentation_pct = s.avg_fragmentation_in_percent
		, s.page_count
		, i.index_id
		from sys.indexes as i 
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

ORDER BY  AVG(avg_fragmentation_pct) desc, SUM(page_count) desc;
