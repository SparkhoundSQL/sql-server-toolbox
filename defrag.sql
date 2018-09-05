USE w 
go
--Using ALTER INDEX ALL isn't efficient. Instead, consider index-level or index-partition-level REBUILDs.
--See also \toolbox\automated index rebuild w online 2016.sql
--See also \toolbox\defrag columnstore.sql

--Consider also DATA_COMPRESSION, SORT_IN_TEMPDB, ONLINE, MAXDOP options

SELECT DISTINCT
	SQL_Reorg = 'ALTER INDEX ALL ON ' + x.DB + '.' + x.[schema_name] + '.' + x.[table_name] + ' REORGANIZE; 
		UPDATE STATISTICS ' + x.DB + '.' + x.[schema_name] + '.' + x.[table_name]  + ';'
,	SQL_Rebuild = 'ALTER INDEX ALL ON ' + x.DB + '.' + x.[schema_name] + '.' + x.[table_name] + ' REBUILD;'  
,	avg_fragmentation_pct	=	avg(avg_fragmentation_pct)
,	page_count	=	sum(page_count)
--, * 
FROM 
(
select 
  DB = db_name(s.database_id)
, [schema_name] = sc.name
, [table_name] = o.name
, index_name = i.name
, s.index_type_desc
, s.partition_number
, avg_fragmentation_pct = s.avg_fragmentation_in_percent
, s.page_count
from sys.indexes as i 
CROSS APPLY sys.dm_db_index_physical_stats (DB_ID(),i.object_id,i.index_id, null,'limited') as s
INNER JOIN sys.objects as o ON o.object_id = s.object_id
INNER JOIN sys.schemas as sc ON o.schema_id = sc.schema_id
WHERE i.is_disabled = 0
--AND s.page_count > 12800 --12800 pages is 100mb
AND	alloc_unit_type_desc <> 'LOB_DATA'

) x
WHERE avg_fragmentation_pct > 70
group by x.DB , x.[schema_name] , x.[table_name]
order by page_count desc, avg_fragmentation_pct desc

GO

/*
--Consider also adding
WITH (MAXDOP = 1, ONLINE = ON);


ALTER INDEX ALL ON w.dbo.ActivateTable_guid REORGANIZE; 
		UPDATE STATISTICS w.dbo.ActivateTable_guid;
ALTER INDEX ALL ON w.dbo.fragmented_table REORGANIZE; 
		UPDATE STATISTICS w.dbo.fragmented_table;

*/
