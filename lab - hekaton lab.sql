USE w
GO

--Add MEMORY_OPTIMIZED_DATA filegroup to the database.
ALTER DATABASE w
ADD FILEGROUP PRIMARY_HEKATON CONTAINS MEMORY_OPTIMIZED_DATA

--Add file to the MEMORY_OPTIMIZED_DATA filegroup.
ALTER DATABASE w
ADD FILE
  ( NAME = PRIMARY_HEKATON_1,
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.SQL2K14\MSSQL\DATA\PRIMARY_HEKATON_1.mdf')
TO FILEGROUP PRIMARY_HEKATON
go
if exists (select * from sys.objects where name = 'hekaton_table_test')
drop table hekaton_table_test
go
if exists (select * from sys.objects where name = 'hekaton_table_test_2')
drop table hekaton_table_test_2
go

--Create memory optimized table and indexes on the memory optimized table.
CREATE TABLE dbo.hekaton_table_test
(	id int not null identity(1,1) 
,	text1 nvarchar(10) COLLATE Latin1_General_100_BIN2 not null
,	CONSTRAINT PK_hekaton_table_test PRIMARY KEY NONCLUSTERED (id)
,	INDEX IDX_HASH_hekaton_table_test_text1 HASH (id) WITH (BUCKET_COUNT = 8388608) --pick a power of 2 greater than, 8x the number of expected unique keys
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
go

--Create memory optimized table and indexes on the memory optimized table.
CREATE TABLE dbo.hekaton_table_test_2
(	id int not null identity(1,1) 
,	text1 nvarchar(10)  COLLATE Latin1_General_100_BIN2 not null
,	CONSTRAINT PK_hekaton_table_test_2 PRIMARY KEY NONCLUSTERED (id)
,	INDEX IDX_HASH_hekaton_table_test_2_text1 HASH (text1) WITH (BUCKET_COUNT = 8388608) --pick a power of 2 greater than, 8x the number of expected unique keys
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
go

insert into hekaton_table_test (text1)
values (replicate(char(round(rand()*100+50,0)),round(rand()*10,0)))
go
declare @x int = 1
while @x <= 20
begin
insert into hekaton_table_test (text1)
select replicate(char(round(rand()*100+50,0)),round(rand()*10,0)) from hekaton_table_test
select @x = @x +1
END
go 
insert into hekaton_table_test_2 (text1)
select text1 from hekaton_table_test
go
select count(1) from   hekaton_table_test 
go
select count(1) from   hekaton_table_test_2

select * from hekaton_table_test_2 order by id asc

select 
	DBName = db_name(mf.database_id)
,	mf.name
,	mf.physical_name
,	cf.file_type_desc
,	FileCount = count(checkpoint_file_id)
,	Total_Size_mb =	sum(file_size_in_bytes)/1024/1024
,	Used_Size_mb	=	sum(isnull(file_size_used_in_bytes,0)) /1024/1024
,	Total_inserted_row_count = sum(isnull(inserted_row_count,0))
,	Total_deleted_row_count = sum(isnull(deleted_row_count,0))
from  sys.dm_db_xtp_checkpoint_files cf
inner join sys.master_files mf on cf.container_id = mf.file_id
group by db_name(mf.database_id), mf.name, mf.physical_name, cf.file_type_desc

select 
	Name = object_name (tms.object_id)
,	memory_allocated_for_indexes_mb =	tms.memory_allocated_for_indexes_kb/1024.
,	memory_used_by_indexes_mb		=	tms.memory_used_by_indexes_kb/1024.
,	memory_allocated_for_table_mb	=	tms.memory_allocated_for_table_kb/1024.
,	memory_used_by_table_mb			=	tms.memory_used_by_table_kb/1024.
from sys.dm_db_xtp_table_memory_stats tms
where object_id > 0 --ignore system objects

select 
	Name = object_name (mc.object_id)
,	sum(allocated_bytes)/1024./1024. as total_allocated_mb
,	sum(used_bytes)/1024./1024. as total_used_mb
from sys.dm_db_xtp_memory_consumers mc
where mc.object_id > 0 --ignore system objects
group by mc.object_id
order by mc.object_id

select  
	name = object_name(his.object_id) 
,	total_bucket_count
,	empty_bucket_count
,	used_buckets	=	total_bucket_count - empty_bucket_count
,	avg_chain_length --want these LOW
,	max_chain_length --want these LOW
from sys.dm_db_xtp_hash_index_stats his