--To generate a deadlock: 
--Run the first half of this script first, then run toolbox\lab - deadlock part 2.sql, then the second half of this script, then the second part of this script.
--Then use toolbox\deadlocks in xevents.sql to view the deadlock.
use w
go
DROP TABLE dbo.dead
DROP TABLE dbo.lock 
go
CREATE TABLE dbo.dead (col1 INT)
INSERT INTO dbo.dead SELECT 1
CREATE TABLE dbo.lock (col1 INT)
INSERT INTO dbo.lock SELECT 1

BEGIN TRAN t1
UPDATE dbo.dead WITH (TABLOCK) SET col1 = 2

-- Part two, run the below after script 2.

UPDATE dbo.lock WITH (TABLOCK) SET col1 = 4
COMMIT TRAN t1
GO
select SYSDATETIME();





