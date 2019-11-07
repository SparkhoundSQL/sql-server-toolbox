--To generate a deadlock: 
--Run the first part of toolbox\lab - deadlock part 1.sql script first, then this script, then the second part of toolbox\lab - deadlock part 1.sql.
--Then use toolbox\deadlocks in xevents.sql to view the deadlock.

USE w
go
BEGIN TRAN t2
UPDATE dbo.lock WITH (TABLOCK) SET col1 = 3
UPDATE dbo.dead WITH (TABLOCK) SET col1 = 3
commit tran t2
GO
select SYSDATETIME();