--This script only works for SQL 2016+, when nonclustered columnstore indexes are writeable
--https://docs.microsoft.com/en-us/sql/relational-databases/indexes/columnstore-indexes-defragmentation

SELECT 
	TableName = SCHEMA_NAME (o.schema_id) + '.' + o.name
,	IndexName = i.name
,	RowGroup_count = count(gps.row_group_id) , RowGroup_State = gps.state_desc, RowGroup_rows = sum(gps.total_rows)
,	Rebuild_TSQL_if_needed = CASE WHEN state_desc = 'open' and count(row_group_id) > 1 and sum(total_rows)>0 THEN 
'ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);   
ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE; 
ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE; 
--Consolidate the Open rowgroups with COMPRESS_ALL_ROW_GROUPS, 
--then again to compress the COMPRESSED rowgroups,
--then a third time to remove the TOMBSTONE rowgroups'
ELSE '' END
,	Rebuild_TSQL =				'ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);   
ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE; 
ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE; 
--Consolidate the Open rowgroups with COMPRESS_ALL_ROW_GROUPS, 
--then again to compress the COMPRESSED rowgroups,
--then a third time to remove the TOMBSTONE rowgroups'
								
FROM sys.dm_db_column_store_row_group_physical_stats as gps
INNER JOIN sys.indexes i on gps.object_id = i.object_id and gps.index_id = i.index_id
INNER JOIN sys.objects o on i.object_id = o.object_id 
--WHERE object_name(gps.object_id)= 'DimShipTo'
GROUP BY o.name, gps.state_desc, gps.object_id, o.schema_id, i.name
ORDER BY o.name, i.name
GO

