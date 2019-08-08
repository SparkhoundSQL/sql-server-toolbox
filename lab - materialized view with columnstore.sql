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
GO 25 --roughly 100 million records in each table

INSERT INTO whatever2 (number2) values (4),(5),(6)
GO
INSERT INTO whatever2 select number2+1 from whatever2
GO 25 --roughly 100 million records in each table
GO

select count(1) from whatever1
select count(1) from whatever2
GO
CREATE VIEW dbo.whateverview1 with schemabinding
AS
--Sample view, there limitations with what you can do and the data types you use
--And remember, gotta have a unique key in here somewhere.
SELECT whatever1.id, whatever1.number1, whatever2.number2 
from dbo.whatever1 --gotta use two-part names in here. not one, not three
INNER JOIN dbo.whatever2 
ON whatever1.id = whatever2.id
GO
--gotta have a unique clustered index on the view first. Identity columns come in handy.
CREATE UNIQUE CLUSTERED INDEX idx_cl_u_whatever1 on dbo.whateverview1 (id)
GO

--DROP INDEX idx_cl_cs_whatever1_covering on dbo.whateverview1
GO
set statistics time on 
set statistics io on 
GO

SELECT avg(number1), AVG(number2) FROM dbo.whateverview1 
where number1 > 16 --clustered index scan

set statistics time off
set statistics io off
GO
--The Magic
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_cl_cs_whatever1_covering on dbo.whateverview1  (number1, number2)
GO
set statistics time on 
set statistics io on 
GO

SELECT avg(number1), AVG(number2) 
FROM dbo.whateverview1 --WITH (NOEXPAND) --With Enterprise edition of SQL or Azure SQL, explore the use of WITH (NOEXPAND), it may benefit performance greatly. It also may not be necessary.
where number1 > 16 --columnstore index scan
GO
set statistics time off
set statistics io off
go

set statistics time on 
set statistics io on 
GO

SELECT avg(number1), AVG(number2) 
FROM dbo.whateverview1 WITH (NOEXPAND) --With Enterprise edition of SQL or Azure SQL, explore the use of WITH (NOEXPAND), it may benefit performance greatly. It also may not be necessary.
where number1 > 16 --columnstore index scan
GO
set statistics time off
set statistics io off
go

--run the inserts above to add more rows, these queries will update view

go
/*
--see also toolbox\defrag columnstore.sql for maintaining columnstore indexes. They need care/feeding just like any other index.
ALTER INDEX idx_cl_cs_whatever1_covering ON whateverview1 REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);   
ALTER INDEX idx_cl_cs_whatever1_covering ON whateverview1 REORGANIZE; 
ALTER INDEX idx_cl_cs_whatever1_covering ON whateverview1 REORGANIZE; 
--Consolidate the Open rowgroups with COMPRESS_ALL_ROW_GROUPS, 
--then again to compress the COMPRESSED rowgroups,
--then a third time if necessary to remove the TOMBSTONE rowgroups
*/

/*



 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 7 ms.
SQL Server parse and compile time: 
   CPU time = 2326 ms, elapsed time = 5329 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

(1 row affected)
Table 'whateverview1'. Scan count 3, logical reads 387110, physical reads 2, read-ahead reads 385578, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 14532 ms,  elapsed time = 39549 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 31 ms, elapsed time = 134 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

(1 row affected)
Table 'whateverview1'. Scan count 4, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 99607, lob physical reads 157, lob read-ahead reads 366683.
Table 'whateverview1'. Segment reads 97, segment skipped 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 45517 ms,  elapsed time = 24854 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

   */