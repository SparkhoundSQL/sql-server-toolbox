use w
go
DROP TABLE IF EXISTS dbo.ActivateTable 
GO
CREATE TABLE dbo.ActivateTable 
(	id int IDENTITY (1,1) NOT NULL
,	whatevernumber int NOT NULL
,	whatevervarchar varchar(10) NOT NULL
,	CONSTRAINT PK_ActivateTable PRIMARY KEY (id)
,	INDEX IDX_NC_whatevernumber_whatevervarchar (whatevernumber, whatevervarchar) --to magnify the imapct of clustered index size
)
GO
INSERT INTO dbo.ActivateTable (whatevernumber, whatevervarchar) VALUES (1, 'test1')
GO
INSERT INTO dbo.ActivateTable (whatevernumber, whatevervarchar) SELECT whatevernumber, whatevervarchar FROM dbo.ActivateTable
GO 20

select 
  DB = db_name(s.database_id)
, [schema_name] = sc.name
, [table_name] = o.name
, index_name = i.name
, s.index_type_desc
, s.partition_number
, avg_fragmentation_pct = s.avg_fragmentation_in_percent
, s.page_count
, p.rows
from sys.indexes as i 
CROSS APPLY sys.dm_db_index_physical_stats (DB_ID(),i.object_id,i.index_id, null,'limited') as s
INNER JOIN sys.partitions as p ON p.object_id = i.object_id AND p.index_id = i.index_id AND s.partition_number = p.partition_number
INNER JOIN sys.objects as o ON o.object_id = s.object_id
INNER JOIN sys.schemas as sc ON o.schema_id = sc.schema_id
WHERE o.object_id = object_id('dbo.ActivateTable')
GO
/*
DB	schema_name	table_name	index_name	index_type_desc	partition_number				avg_fragmentation_pct	page_count	rows
w	dbo	ActivateTable	PK_ActivateTable	CLUSTERED INDEX	1							0.192641109612791		5191		1048576
w	dbo	ActivateTable	IDX_NC_whatevernumber_whatevervarchar	NONCLUSTERED INDEX	1	0.353430353430353		4810		1048576
*/

use w
go
DROP TABLE IF EXISTS dbo.ActivateTable_guid 
GO
CREATE TABLE dbo.ActivateTable_guid
(	id uniqueidentifier NOT NULL CONSTRAINT DF_id_ActivateTable_guid DEFAULT (newid()) 
,	whatevernumber int NOT NULL
,	whatevervarchar varchar(10) NOT NULL
,	CONSTRAINT PK_ActivateTable_guid PRIMARY KEY (id)
,	INDEX IDX_NC_whatevernumber_whatevervarchar (whatevernumber, whatevervarchar) --to magnify the imapct of clustered index size
)
GO
INSERT INTO dbo.ActivateTable_guid (whatevernumber, whatevervarchar) VALUES (1, 'test1')
GO
INSERT INTO dbo.ActivateTable_guid (whatevernumber, whatevervarchar) SELECT whatevernumber, whatevervarchar FROM dbo.ActivateTable_guid 
GO 20

select 
  DB = db_name(s.database_id)
, [schema_name] = sc.name
, [table_name] = o.name
, index_name = i.name
, s.index_type_desc
, s.partition_number
, avg_fragmentation_pct = s.avg_fragmentation_in_percent
, s.page_count
, p.rows
from sys.indexes as i 
CROSS APPLY sys.dm_db_index_physical_stats (DB_ID(),i.object_id,i.index_id, null,'limited') as s
INNER JOIN sys.partitions as p ON p.object_id = i.object_id AND p.index_id = i.index_id AND s.partition_number = p.partition_number
INNER JOIN sys.objects as o ON o.object_id = s.object_id
INNER JOIN sys.schemas as sc ON o.schema_id = sc.schema_id
WHERE o.object_id = object_id('dbo.ActivateTable_guid')
GO
/*
DB	schema_name	table_name	index_name	index_type_desc	partition_number					avg_fragmentation_pct	page_count	rows
w	dbo	ActivateTable_guid	PK_ActivateTable_guid	CLUSTERED INDEX	1						79.5706431625796		11459		1048576
w	dbo	ActivateTable_guid	IDX_NC_whatevernumber_whatevervarchar	NONCLUSTERED INDEX	1	80.202338964173			10774		1048576
*/

use w
go
DROP TABLE IF EXISTS dbo.ActivateTable_guid_seq
GO
CREATE TABLE dbo.ActivateTable_guid_seq
(	id uniqueidentifier NOT NULL CONSTRAINT DF_id_ActivateTable_guid_seq DEFAULT (newsequentialid())
,	whatevernumber int NOT NULL
,	whatevervarchar varchar(10) NOT NULL
,	CONSTRAINT PK_ActivateTable_guid_seq PRIMARY KEY (id)
,	INDEX IDX_NC_whatevernumber_whatevervarchar (whatevernumber, whatevervarchar) --to magnify the imapct of clustered index size
)
GO
INSERT INTO dbo.ActivateTable_guid_seq (whatevernumber, whatevervarchar) VALUES (1, 'test1')
GO
INSERT INTO dbo.ActivateTable_guid_seq (whatevernumber, whatevervarchar) SELECT  whatevernumber, whatevervarchar FROM dbo.ActivateTable_guid_seq 
GO 20

select 
  DB = db_name(s.database_id)
, [schema_name] = sc.name
, [table_name] = o.name
, index_name = i.name
, s.index_type_desc
, s.partition_number
, avg_fragmentation_pct = s.avg_fragmentation_in_percent
, s.page_count
, p.rows
from sys.indexes as i 
CROSS APPLY sys.dm_db_index_physical_stats (DB_ID(),i.object_id,i.index_id, null,'limited') as s
INNER JOIN sys.partitions as p ON p.object_id = i.object_id AND p.index_id = i.index_id AND s.partition_number = p.partition_number
INNER JOIN sys.objects as o ON o.object_id = s.object_id
INNER JOIN sys.schemas as sc ON o.schema_id = sc.schema_id
WHERE o.object_id = object_id('dbo.ActivateTable_guid_seq')
/*
DB	schema_name	table_name	index_name	index_type_desc	partition_number						avg_fragmentation_pct	page_count	rows
w	dbo	ActivateTable_guid_seq	PK_ActivateTable_guid_seq	CLUSTERED INDEX	1					0.339934968962459		6766		1048576
w	dbo	ActivateTable_guid_seq	IDX_NC_whatevernumber_whatevervarchar	NONCLUSTERED INDEX	1	0.519194461925739		6356		1048576
*/



/*
--Comparison:
DB	schema_name	table_name	index_name	index_type_desc	partition_number						avg_fragmentation_pct	page_count	rows
w	dbo	ActivateTable	PK_ActivateTable	CLUSTERED INDEX	1									0.192641109612791		5191		1048576
w	dbo	ActivateTable	IDX_NC_whatevernumber_whatevervarchar	NONCLUSTERED INDEX	1			0.353430353430353		4810		1048576
w	dbo	ActivateTable_guid	PK_ActivateTable_guid	CLUSTERED INDEX	1							79.5706431625796		11459		1048576
w	dbo	ActivateTable_guid	IDX_NC_whatevernumber_whatevervarchar	NONCLUSTERED INDEX	1		80.202338964173			10774		1048576
w	dbo	ActivateTable_guid_seq	PK_ActivateTable_guid_seq	CLUSTERED INDEX	1					0.339934968962459		6766		1048576
w	dbo	ActivateTable_guid_seq	IDX_NC_whatevernumber_whatevervarchar	NONCLUSTERED INDEX	1	0.519194461925739		6356		1048576
*/


