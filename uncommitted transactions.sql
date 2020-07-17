--Returns information on uncommitted transactions

--current database
select Observed = sysdatetimeoffset(), *  FROM sys.dm_tran_active_transactions tat 
INNER JOIN sys.dm_tran_session_transactions tst  on tat.transaction_id = tst.transaction_id
INNER JOIN sys.dm_exec_connections ec ON tst.session_id = ec.session_id
INNER JOIN Sys.dm_exec_requests r on r.transaction_id = tst.transaction_id
WHERE r.database_id = db_id()


--all databases
exec sp_msforeachdb N'use [?]; select database_name = ''?'', Observed = sysdatetimeoffset(), * FROM sys.dm_tran_active_transactions tat 
INNER JOIN sys.dm_tran_session_transactions tst  on tat.transaction_id = tst.transaction_id
INNER JOIN sys.dm_exec_connections ec ON tst.session_id = ec.session_id
INNER JOIN Sys.dm_exec_requests r on r.transaction_id = tst.transaction_id
WHERE r.database_id = db_id()'
