SELECT 
  OBJECT_NAME(ms.object_id)
, memory_allocated_for_table_and_indexes_GB = ((memory_allocated_for_table_kb + memory_allocated_for_indexes_kb)/1024./1024.)
, memory_allocated_for_table_GB = memory_allocated_for_table_kb/1024./1024.
, memory_allocated_for_indexes_GB = memory_allocated_for_indexes_kb/1024./1024.
, Row_Count = p.rows
FROM sys.dm_db_xtp_table_memory_stats  ms
INNER JOIN sys.partitions p 
ON p.object_id = ms.object_id
 WHERE 
  p.index_id <= 1
 --and ms.object_id = object_id('dbo.memopt1')  
 