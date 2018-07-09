
--Reference: https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-databases-transact-sql?view=sql-server-2017
select name, log_reuse_wait ,log_reuse_wait_desc 
from sys.databases 
GO

/* If REPLICATION, consider the following but be aware of the consequences:
--Safe for snapshot-only replication, not that safe for other replication if you're not synced

USE [database]
GO
EXEC sp_repldone @xactid = NULL, @xact_segno = NULL, @numtrans = 0,     @time = 0, @reset = 1
GO
CHECKPOINT --must follow with checkpoint!
GO


