--Index/partitions in current database
select SizeMb= (p.in_row_reserved_page_count*8.)/1024.
,	indexname = i.name
,	tablename = '[' + s.name + '].[' + o.name + ']'
,	pr.data_compression_desc
,	p.partition_number
,  rebuildcompress = 
CASE WHEN pr.data_compression_desc = 'columnstore' THEN NULL ELSE
	'ALTER INDEX [' + i.name + '] ON [' + s.name + '].[' + o.name + '] REBUILD ' + 
	CASE WHEN MAX(p.partition_number) OVER (PARTITION by i.name)  > 1 THEN 
	'PARTITION = ' + cast(p.partition_number as varchar(5)) ELSE ''  END +
	' WITH (SORT_IN_TEMPDB = ON
	, DATA_COMPRESSION = PAGE) ' + CHAR(10) + CHAR(13)
END
, *
from sys.dm_db_partition_stats p
inner join sys.partitions pr on p.partition_id = pr.partition_id
inner join sys.objects o on p.object_id = o.object_id 
inner join sys.schemas s on s.schema_id = o.schema_id
left outer join sys.indexes i on i.object_id = o.object_id and i.index_id = p.index_id
WHERE o.is_ms_shipped = 0

order by SizeMb desc

/* --Estimate size savings with compression using 
--Example:
use [database]
go
exec sp_estimate_data_compression_savings  
      @schema_name =  'dbo'   
   ,  @object_name =  'whatevertable'  
   ,  @index_id = null --null for all indexes on table, or try a specific index. The compression savings will vary.
   ,  @partition_number =  null --specify partitions if applicable
   ,  @data_compression =  'PAGE'; --or ROW, or for columnstore, can use COLUMNSTORE

*/