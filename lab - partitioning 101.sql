use testdb
go

DROP TABLE IF EXISTS  dbo.HorizontalPartitionTable
go
DROP PARTITION SCHEME PartitionScheme_TestHorizontalPartitioning_Single
DROP PARTITION FUNCTION PartitionFunc_TestHorizontalPartitioning_Single
go

CREATE PARTITION FUNCTION PartitionFunc_TestHorizontalPartitioning_Single (int)
AS RANGE RIGHT FOR VALUES (0,1); --Sets up three partitions for values <0, 0, >0 (this is unusual, just for demonstration purposes)
GO
CREATE PARTITION SCHEME PartitionScheme_TestHorizontalPartitioning_Single
AS PARTITION PartitionFunc_TestHorizontalPartitioning_Single
ALL TO ('PRIMARY'); --if you wanted to move the partitions to different volumes, use different file groups here in this syntax
GO

CREATE TABLE dbo.HorizontalPartitionTable
	(
		ID int NOT NULL IDENTITY (1, 1) 
	,	Period_ID int NOT NULL 
	,	Period_DESC varchar(50) NOT NULL  INDEX IDX_NC_HorizontalPartitionTable_Period_DESC ON PartitionScheme_TestHorizontalPartitioning_Single (Period_ID)
	,	CONSTRAINT PK_HorizontalPartitionTable PRIMARY KEY CLUSTERED (ID, Period_ID)
	,	CONSTRAINT IDX_NCU_HorizontalPartitionTable_Period_ID UNIQUE NONCLUSTERED (Period_ID) ON PartitionScheme_TestHorizontalPartitioning_Single (Period_ID)
	)  ON PartitionScheme_TestHorizontalPartitioning_Single (Period_ID)
	--)  ON [PRIMARY]
GO
--Add value 0
INSERT INTO HorizontalPartitionTable (Period_ID, Period_DESC) values (0, 'testing')
GO
--Add values over 0
while (select MAX(period_ID) from HorizontalPartitionTable) < 1600
BEGIN
INSERT INTO HorizontalPartitionTable (Period_ID, Period_DESC)
	select TOP 1 Period_ID = MAX(Period_ID) + 1 
		,	Period_DESC = 'testing ' + convert(varchar(30), GETDATE(), 113)
	FROM HorizontalPartitionTable
END
go
--Add values under 0
while (select MIN(period_ID) from HorizontalPartitionTable) > -1600
BEGIN
INSERT INTO HorizontalPartitionTable (Period_ID, Period_DESC)
	select TOP 1 Period_ID = MIN(Period_ID) - 1 
		,	Period_DESC = 'testing ' + convert(varchar(30), GETDATE(), 113)
	FROM HorizontalPartitionTable
END
go

--What data is in the table, in what partitions?
select  
 Partition_Number = $PARTITION.PartitionFunc_TestHorizontalPartitioning_Single(Period_ID)
, min_value_found = MIN(Period_id)
, max_value_found = MAX(Period_id)
, row_count = count(1)  
from dbo.HorizontalPartitionTable
group by $PARTITION.PartitionFunc_TestHorizontalPartitioning_Single(Period_ID)

GO

select prv.boundary_id, prv.parameter_id, prv.value, 
value_data_type = type_name(pp.user_type_id),
function_name = pf.name,
scheme_name = ps.name,
pf.type_desc,
number_of_partitions_resulting = pf.fanout,
pf.boundary_value_on_right --1 = right, 0 = left
from sys.partition_range_values prv
inner join sys.partition_functions pf
on pf.function_id = prv.function_id
inner join sys.partition_parameters pp
on pp.parameter_id = prv.parameter_id
inner join sys.partition_schemes ps
on ps.function_id = pf.function_id



GO

--Now let's demonstrate basic partition switching
--We create "partner" tables to receive the old data and process in new data. The tables must be EXACTLY the same schema including all indexes. 
--Careful! when adding an index to the main table, you must also add the same index to the partner tables, or the switching will break.
--Imagine all reporting is based on the main table, dbo.HorizontalPartitionTable. Users/reports/apps aren't even aware of HorizontalPartitionTable_Dump and HorizontalPartitionTable_Stage

CREATE TABLE dbo.HorizontalPartitionTable_Stage
	(
		ID int NOT NULL IDENTITY (1, 1) 
	,	Period_ID int NOT NULL 
	,	Period_DESC varchar(50) NOT NULL  INDEX IDX_NC_HorizontalPartitionTable_Stage_Period_DESC ON PartitionScheme_TestHorizontalPartitioning_Single (Period_ID)
	,	CONSTRAINT PK_HorizontalPartitionTable_Stage PRIMARY KEY CLUSTERED (ID, Period_ID)
	,	CONSTRAINT IDX_NCU_HorizontalPartitionTable_Stage_Period_ID UNIQUE NONCLUSTERED (Period_ID) ON PartitionScheme_TestHorizontalPartitioning_Single (Period_ID)
	)  ON PartitionScheme_TestHorizontalPartitioning_Single (Period_ID)
	--)  ON [PRIMARY]
GO

CREATE TABLE dbo.HorizontalPartitionTable_Dump
	(
		ID int NOT NULL IDENTITY (1, 1) 
	,	Period_ID int NOT NULL 
	,	Period_DESC varchar(50) NOT NULL  INDEX IDX_NC_HorizontalPartitionTable_Dump_Period_DESC ON PartitionScheme_TestHorizontalPartitioning_Single (Period_ID)
	,	CONSTRAINT PK_HorizontalPartitionTable_Dump PRIMARY KEY CLUSTERED (ID, Period_ID)
	,	CONSTRAINT IDX_NCU_HorizontalPartitionTable_Dump_Period_ID UNIQUE NONCLUSTERED (Period_ID) ON PartitionScheme_TestHorizontalPartitioning_Single (Period_ID)
	)  ON PartitionScheme_TestHorizontalPartitioning_Single (Period_ID)
	--)  ON [PRIMARY]
GO

--Say we need to do a lot of insert/update/delete on the '>0' partition, which is partition_id = 3. 
--Instead of updating the live reporting table, use the _Stage table to build the new data without locking/blocking anyone.
--In reality, this step probably involves reading from multiple sources, potentially expensive logic we don't want conflicting with reads on the main table.
INSERT INTO HorizontalPartitionTable_Stage (Period_ID, Period_DESC) values (1, 'testing')
GO
while (select MAX(period_ID) from HorizontalPartitionTable_Stage) < 1700
BEGIN
INSERT INTO HorizontalPartitionTable_Stage (Period_ID, Period_DESC)
	select TOP 1 Period_ID = MAX(Period_ID) + 1 
		,	Period_DESC = 'testing switched ' + convert(varchar(30), GETDATE(), 113)
	FROM HorizontalPartitionTable_Stage
END

--Now, Stage has new data we need to get into the real table.
select  
 Partition_Number = $PARTITION.PartitionFunc_TestHorizontalPartitioning_Single(Period_ID)
, min_value_found = MIN(Period_id)
, max_value_found = MAX(Period_id)
, row_count = count(1)  
from dbo.HorizontalPartitionTable_Stage
group by $PARTITION.PartitionFunc_TestHorizontalPartitioning_Single(Period_ID)

select object_name(object_id), partition_number, rows from sys.partitions where object_id = object_id('HorizontalPartitionTable') and index_id = 1 order by partition_number
select object_name(object_id), partition_number, rows from sys.partitions where object_id = object_id('HorizontalPartitionTable_Stage') and index_id = 1 order by partition_number


GO
--Here's where the magic happens.
--Now we'll switch the old data out of the main table, and reassociate the new Staged data to the main table, quickly 
ALTER TABLE HorizontalPartitionTable SWITCH PARTITION 3 TO HorizontalPartitionTable_dump PARTITION 3 
WITH (WAIT_AT_LOW_PRIORITY (MAX_DURATION = 14 MINUTES, ABORT_AFTER_WAIT = SELF)); --We can even have the partition switching wait politely until the table is free
ALTER TABLE HorizontalPartitionTable_Stage SWITCH PARTITION 3 TO HorizontalPartitionTable PARTITION 3
WITH (WAIT_AT_LOW_PRIORITY (MAX_DURATION = 14 MINUTES, ABORT_AFTER_WAIT = SELF)); --We can even have the partition switching wait politely until the table is free
go
truncate table dbo.HorizontalPartitionTable_Dump --then we can throw away the old data
GO
select object_name(object_id), partition_number, rows from sys.partitions where object_id = object_id('HorizontalPartitionTable') and index_id = 1 order by partition_number
select object_name(object_id), partition_number, rows from sys.partitions where object_id = object_id('HorizontalPartitionTable_Stage') and index_id = 1 order by partition_number
select object_name(object_id), partition_number, rows from sys.partitions where object_id = object_id('HorizontalPartitionTable_Dump') and index_id = 1 order by partition_number

drop table test 
create table test (id int not null primary key)
insert into test (id) values  (1),(2)