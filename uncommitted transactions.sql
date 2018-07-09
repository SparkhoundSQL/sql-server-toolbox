--Returns information on uncommitted transactions

select * from sys.dm_tran_active_transactions tat 
inner join sys.dm_tran_session_transactions tst  on tat.transaction_id = tst.transaction_id
