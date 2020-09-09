--Misc queries on database/table size

--Database files on disk
--Does not work in Azure SQL DB 
select d.name, Current_Size_mb = (size*8.)/1024., * from sys.master_files mf
inner join sys.databases d
on mf.database_id = d.database_id
order by Current_Size_mb desc
GO

--Size of files in current database
select df.name, Initial_Size_mb = df.size *8./2014.
from sys.database_files df
order by df.name

--Tables in current database
--return the number of rows in a table without doing a scan
select tablename
, total_size_mb = SUM(sizemb) -- size of all objects combined
, row_count = sum(case when index_id <= 1 THEN row_count ELSE 0 END)  --get rowcount in table from heap or clustered index only
from (
select 
  SizeMb= (p.reserved_page_count*8.)/1024.
, tablename = '[' + s.name + '].[' + o.name + ']'
, indexname = i.name, p.row_count
, i.index_id
from sys.dm_db_partition_stats p
inner join sys.objects o on p.object_id = o.object_id 
inner join sys.schemas s on s.schema_id = o.schema_id
inner join sys.indexes i on i.object_id = o.object_id and i.index_id = p.index_id
where o.is_ms_shipped = 0 
) x
group by tablename
order by total_size_mb desc

--Index/partitions in current database
select 
	tablename = '[' + s.name + '].[' + o.name + ']'
,	indexname = i.name
,	i.index_id
,	SizeMb= (p.reserved_page_count*8.)/1024.
,	p.in_row_data_page_count
,	p.in_row_used_page_count
,	p.reserved_page_count
,	p.lob_used_page_count
,	p.lob_reserved_page_count
,	p.row_overflow_used_page_count
,	p.row_overflow_reserved_page_count
,	p.used_page_count
,	p.reserved_page_count
,	p.row_count
,	pr.data_compression_desc
,	p.partition_number
,   rebuildcompress = 
CASE WHEN pr.data_compression_desc = 'columnstore' THEN NULL ELSE
	'ALTER INDEX [' + i.name + '] ON [' + s.name + '].[' + o.name + '] REBUILD ' + 
	CASE WHEN MAX(p.partition_number) OVER (PARTITION by i.name)  > 1 THEN 
	'PARTITION = ' + cast(p.partition_number as varchar(5)) ELSE ''  END +
	' WITH (SORT_IN_TEMPDB = ON
	, DATA_COMPRESSION = PAGE) ' + CHAR(10) + CHAR(13)
END 
from sys.dm_db_partition_stats p
inner join sys.partitions pr on p.partition_id = pr.partition_id
inner join sys.objects o on p.object_id = o.object_id 
inner join sys.schemas s on s.schema_id = o.schema_id
left outer join sys.indexes i on i.object_id = o.object_id and i.index_id = p.index_id
WHERE o.is_ms_shipped = 0
order by SizeMb desc

