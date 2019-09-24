use tempdb
go
select * from Sys.dm_db_file_space_usage

--Is the version store taking up a lot of space?
SELECT version_store_Gb = (SUM(version_store_reserved_page_count)*8/1024./1024.)  
,	total_tempdb_Gb = sum(total_page_count)*8/1024./1024.
,	pct_of_tempdb_dedicated_to_version_store = round((sum(version_store_reserved_page_count)*1./sum(total_page_count)*1.)*100.,2)
FROM sys.dm_db_file_space_usage; 

--If version store is very large, need to find out what transactions are holding onto it. 
--It is not possible to associate versionstore allocation to individual sessions
--But these queries would be responsible for version store-leveraging transactions
SELECT              Observed = SYSDATETIMEOFFSET(),
					tst.session_id,
					tat.transaction_id,
					s.login_name,
					s.host_name,
					s.program_name,
					tat.[name],
                    tat.transaction_begin_time ,
                    elapsed_min = DATEDIFF(mi, tat.transaction_begin_time, sysdatetime()),
                    transaction_type_desc = CASE tat.transaction_type
											    WHEN 1 THEN 'Read/write'
												WHEN 2 THEN 'Read-only'
												WHEN 3 THEN 'System'
												WHEN 4 THEN 'Distributed'
												END ,
                   transaction_description = CASE tat.transaction_state
                                         WHEN 0 THEN 'The transaction has not been completely initialized yet.'
                                         WHEN 1 THEN 'The transaction has been initialized but has not started.'
                                         WHEN 2 THEN 'The transaction is active.'
                                         WHEN 3 THEN 'The transaction has ended. This is used for read-only transactions.'
                                         WHEN 4 THEN 'The commit process has been initiated on the distributed transaction. This is for distributed transactions only. The distributed transaction is still active but further processing cannot take place.'
                                         WHEN 5 THEN 'The transaction is in a prepared state and waiting resolution.'
                                         WHEN 6 THEN 'The transaction has been committed.'
                                         WHEN 7 THEN 'The transaction is being rolled back.'
                                         WHEN 8 THEN 'The transaction has been rolled back.'
                    END 
				, non_versionstore_total_tempdb_allocatd_Gb =		(		sum (ssu.internal_objects_alloc_page_count) - sum (ssu.internal_objects_dealloc_page_count)
										+	sum (ssu.user_objects_alloc_page_count)	 - sum (ssu.user_objects_dealloc_page_count)
										+	sum (tsu.internal_objects_alloc_page_count) - sum (tsu.internal_objects_dealloc_page_count)
										+	sum (tsu.user_objects_alloc_page_count) - sum (tsu.user_objects_dealloc_page_count)
										)*8/1024./1024.
FROM tempdb.sys.dm_tran_active_snapshot_database_transactions sdt
inner join sys.dm_tran_active_transactions tat on tat.transaction_id = sdt.transaction_id
left outer join sys.dm_tran_session_transactions tst on tat.transaction_id = tst.transaction_id
left outer join sys.dm_exec_sessions s on s.session_id = tst.session_id
left outer join tempdb.sys.dm_db_session_space_usage ssu      on ssu.session_id = tst.session_id
inner join tempdb.sys.dm_db_task_space_usage tsu      on ssu.session_id = tsu.session_id
group by tst.session_id, tat.transaction_id,
					s.login_name,
					s.host_name,
					s.program_name,
					tat.[name], tat.transaction_begin_time, tat.transaction_type, tat.transaction_state
order by transaction_begin_time asc

/*
--Which database has the most data stored in tempdb's version store?
--WARNING this query can have a performance impact!
select database_id, sum(aggregated_record_length_in_bytes) 
from sys.dm_tran_top_version_generators WITH (NOLOCK)
group by database_id
*/


--https://blogs.msdn.microsoft.com/deepakbi/2010/04/13/monitoring-tempdb-transactions-and-space-usage/
--https://blogs.technet.microsoft.com/beatrice_popa/2013/05/21/sql-server-tempdb-database-and-disk-space-issues/
