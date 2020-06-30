--SQL and Azure SQL DB
--Typically not a lot of actionable items to find here.

use tempdb;

SELECT
	  name
	, type
	, Memory_in_use = SUM(pages_kb + virtual_memory_committed_kb + awe_allocated_kb) --Only really applicable SQL 2012+, pre-2012 use single_pages_kb
FROM  sys.dm_os_memory_clerks
GROUP BY name, type
ORDER BY memory_in_use desc

/*
Some example types:
MEMORYCLERK_SQLQERESERVATIONS - Memory Grant allocations, see toolbox\dm_exec_query_memory_grants.sql
MEMORYCLERK_SQLBUFFERPOOL - the buffer pool across the instance
OBJECTSTORE_LOCK_MANAGER - the lock manager (concurrency), fixed
XTP - hekaton
CACHESTORE_OBJCP - the procedure cache for procs, functions, triggers
CACHESTORE_PHDR - cached algebrizer trees for views, constraints and defaults
CACHESTORE_SQLCP - other batches not in the above, including ad hoc statements
USERSTORE_SCHEMAMGR - schema management especially temporary objects, note a memory leak in unpatched SQL2012/2014 KB3032476
MEMORYCLERK_SQLLOGPOOL - used tlog activities including AG change-capturing activities on the primary replicas, redo manager activities on the secondary availability replicas
MEMORYCLERK_XE - XEvent session management 

*/

--https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-memory-clerks-transact-sql?view=sql-server-ver15