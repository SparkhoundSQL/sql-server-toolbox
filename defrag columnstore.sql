--This script only works for SQL 2016+, when nonclustered columnstore indexes are writeable
--https://docs.microsoft.com/en-us/sql/relational-databases/indexes/columnstore-indexes-defragmentation

SELECT 
	TableName = SCHEMA_NAME (o.schema_id) + '.' + o.name
,	IndexName = i.name
,	RowGroup_count = count(gps.row_group_id) 
,	RowGroup_State = gps.state_desc
,	gps.partition_number
,	gps.Number_of_partitions 
,	RowGroup_rows = sum(gps.total_rows)
,	Size_GB = SUM(gps.size_in_bytes/1024./1024.)
,	Rebuild_TSQL_if_needed = CASE WHEN state_desc <> 'COMPRESSED'  and sum(total_rows)>0 THEN 
'ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE '+CASE WHEN gps.Number_of_partitions > 1  THEN 'PARTITION = '+ cast(gps.partition_number as varchar(10)) ELSE '' END +' WITH (COMPRESS_ALL_ROW_GROUPS = ON);   
ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE  ' +CASE WHEN gps.Number_of_partitions > 1 THEN 'PARTITION = '+ cast(gps.partition_number as varchar(10)) ELSE '' END +' ; 
ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE  ' +CASE WHEN gps.Number_of_partitions > 1 THEN 'PARTITION = '+ cast(gps.partition_number as varchar(10)) ELSE '' END +' ; 
--Consolidate the Open rowgroups with COMPRESS_ALL_ROW_GROUPS, 
--then again to compress the COMPRESSED rowgroups,
--then a third time to remove the TOMBSTONE rowgroups'
ELSE '' END
,	Rebuild_TSQL =				
'ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE '+CASE WHEN gps.Number_of_partitions > 1 THEN 'PARTITION = '+ cast(gps.partition_number as varchar(10)) ELSE '' END +'  WITH (COMPRESS_ALL_ROW_GROUPS = ON);   
ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE '+CASE WHEN gps.Number_of_partitions > 1 THEN 'PARTITION = '+ cast(gps.partition_number as varchar(10)) ELSE '' END +' ; 
ALTER INDEX '+i.name+' ON '+object_name(gps.object_id)+' REORGANIZE '+CASE WHEN gps.Number_of_partitions > 1 THEN 'PARTITION = '+ cast(gps.partition_number as varchar(10)) ELSE '' END +' ; 
--Reorganize to consolidate the Open rowgroups with COMPRESS_ALL_ROW_GROUPS, 
--then Reorganize again to compress the COMPRESSED rowgroups,
--then Reorganize potentially a third time to remove any remaining TOMBSTONE rowgroups'
FROM (SELECT *, Number_of_partitions =  MAX(partition_number) OVER (PARTITION BY index_id) 
		FROM sys.dm_db_column_store_row_group_physical_stats) as gps
INNER JOIN sys.indexes i on gps.object_id = i.object_id and gps.index_id = i.index_id
INNER JOIN sys.objects o on i.object_id = o.object_id 
--WHERE object_name(gps.object_id)= 'DimShipTo'
GROUP BY o.name, gps.state_desc, gps.object_id, o.schema_id, i.name, gps.size_in_bytes,	gps.partition_number, gps.Number_of_partitions
ORDER BY o.name, i.name;
GO 
