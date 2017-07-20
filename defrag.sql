 
go
--select db_id()

--CREATE TABLE sqlIndexREBUILD (
--	id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
--	SQLString varchar(200) NOT NULL,
--	Fraglevel Decimal(19,3) NOT NULL,
--)
--GO
--CREATE PROCEDURE dbo.spDetectIndexFragmentation
--AS
--
--INSERT INTO sqlIndexRebuild (SQLString, FragLevel)
SELECT DISTINCT
	SQL_Reorg = 'ALTER INDEX ALL ON ' + x.dbname + '.' + x.schemaname + '.' + x.[table] + ' REORGANIZE' 
,	SQL_Status = 'UPDATE STATISTICS ' + x.dbname + '.' + x.schemaname + '.' + x.[table]  + CHAR(10)+ CHAR(13)+'GO'
,	SQL_Rebuild = 'ALTER INDEX ALL ON ' + x.dbname + '.' + x.schemaname + '.' + x.[table] + ' REBUILD '  
--,	FragLevel	=	sum(FragLevel)
,	avg_fragmentation_in_percent	=	avg(avg_fragmentation_in_percent)
,	page_count	=	sum(page_count)
--, * 
FROM 
(
select 
	--[fraglevel] = (power(s.avg_fragmentation_in_percent,2) *page_count)/power(10,7),
	avg_fragmentation_in_percent = s.avg_fragmentation_in_percent
,	page_count = page_count
,	dbname		= db_name(s.database_id)
,	[table]		= o.name
,	schemaname	= sc.name
--, index_name = i.name, s.index_type_desc, alloc_unit_type_desc, s.avg_fragmentation_in_percent, page_count, fragment_count, avg_fragment_size_in_pages
--select *
from sys.dm_db_index_physical_stats (DB_ID(),null,null, null,'limited') s
inner join --select * from
sys.indexes i on s.object_id = i.object_id and s.index_id = i.index_id
inner join  --select * from
sys.objects o on o.object_id = s.object_id
inner join --select * from
sys.schemas sc
on o.schema_id = sc.schema_id

WHERE 
		i.is_disabled = 0
and		i.type_desc = 'CLUSTERED'
and		s.database_id = db_id()
and		alloc_unit_Type_desc <> 'LOB_DATA'
--and page_count > 100

) x
WHERE avg_fragmentation_in_percent > 70
group by x.dbname , x.schemaname , x.[table]
order by page_count desc, avg_fragmentation_in_percent desc

GO

/*
ALTER INDEX ALL ON WideWorldImporters.Sales.Invoices REBUILD
WITH (MAXDOP = 1, ONLINE = ON);
*/
