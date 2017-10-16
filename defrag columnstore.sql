--This script only works for SQL 2016+, when nonclustered columnstore indexes are writeable
--https://docs.microsoft.com/en-us/sql/relational-databases/indexes/columnstore-indexes-defragmentation

SELECT 
SCHEMA_NAME (gps.object_id), object_name(gps.object_id), i.name, RowGroup_count = count(gps.row_group_id) , gps.state_desc, RowGroup_rows = sum(gps.total_rows) ,
CASE WHEN state_desc = 'open' and count(row_group_id) > 1 and sum(total_rows)>0 THEN 
'ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);   
ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE; 
ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE; 
--Consolidate the Open rowgroups with COMPRESS_ALL_ROW_GROUPS, then again to compress the COMPRESSED rowgroups, then a third time to remove the TOMBSTONE rowgroups'
ELSE '' END
FROM sys.dm_db_column_store_row_group_physical_stats as gps
INNER JOIN sys.indexes i on gps.object_id = i.object_id and gps.index_id = i.index_id
--WHERE object_name(gps.object_id)= 'DimShipTo'
GROUP BY i.name, gps.state_desc, gps.object_id
GO
