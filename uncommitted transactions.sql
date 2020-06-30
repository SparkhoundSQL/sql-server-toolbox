--Returns information on uncommitted transactions

--current database
select * from sys.dm_tran_active_transactions tat 
inner join sys.dm_tran_session_transactions tst  on tat.transaction_id = tst.transaction_id


--all databases
exec sp_msforeachdb N'use [?]; select database_name = ''?'', * FROM sys.dm_tran_active_transactions tat 
INNER JOIN sys.dm_tran_session_transactions tst  on tat.transaction_id = tst.transaction_id
INNER JOIN sys.dm_exec_connections ec ON tst.session_id = ec.session_id'
