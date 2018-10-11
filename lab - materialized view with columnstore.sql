use w
go
--this only works on SQL 2016+ 
--will take up about 1.6GB memory
DROP VIEW IF EXISTS dbo.whateverview1 
GO

DROP TABLE IF EXISTS whatever1
GO

DROP TABLE IF EXISTS whatever2
GO

CREATE TABLE whatever1
(id int not null identity(1,1) primary key
, number1 decimal(19,4) not null) 
GO

CREATE TABLE whatever2
(id int not null identity(1,1) primary key
, number2 decimal(19,4) not null) 
GO

INSERT INTO whatever1 (number1) values (1),(2),(3)
GO
INSERT INTO whatever1 select number1+1 from whatever1
GO 20 --roughly 1.5 million records in each table

INSERT INTO whatever2 (number2) values (4),(5),(6)
GO
INSERT INTO whatever2 select number2+1 from whatever2
GO 20 --roughly 1.5 million records in each table
GO

CREATE VIEW dbo.whateverview1 with schemabinding
as
--Sample view, there limitations with what you can do and the data types you use
--And remember, gotta have a unique key in here somewhere.
SELECT whatever1.id, whatever1.number1, whatever2.number2 
from dbo.whatever1 --gotta use two-part names in here. not one, not three
INNER JOIN dbo.whatever2 
ON whatever1.id = whatever2.id
go
--gotta have a unique clustered index on the view first. Identity columns come in handy.
CREATE UNIQUE CLUSTERED INDEX idx_cl_u_whatever1 on dbo.whateverview1 (id)
go
--The Magic
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_cl_cs_whatever1_covering on dbo.whateverview1  (id, number1, number2)
go
SELECT count(1) FROM dbo.whateverview1 --columnstore index scan on 3.1million rows, should complete instantly

SELECT avg(number1), AVG(number2) FROM dbo.whateverview1 --columnstore index scan on 3.1million rows, should complete instantly

--run the inserts above to add more rows, these queries will update view

go
--see also toolbox\defrag columnstore.sql for maintaining columnstore indexes. They need care/feeding just like any other index.
ALTER INDEX idx_cl_cs_whatever1_covering ON whateverview1 REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);   
ALTER INDEX idx_cl_cs_whatever1_covering ON whateverview1 REORGANIZE; 
ALTER INDEX idx_cl_cs_whatever1_covering ON whateverview1 REORGANIZE; 
--Consolidate the Open rowgroups with COMPRESS_ALL_ROW_GROUPS, 
--then again to compress the COMPRESSED rowgroups,
--then a third time if necessary to remove the TOMBSTONE rowgroups
