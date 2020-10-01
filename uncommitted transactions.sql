--Returns information on uncommitted transactions

--current database (see below for all databases)
select Observed = sysdatetimeoffset(), tat.transaction_id, tat.transaction_begin_time, tst.session_id 
,	[database_name]	= db_name(s.database_id)
,	transaction_duration_s = datediff(s, tat.transaction_begin_time, sysdatetime())
--https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-tran-active-transactions-transact-sql?view=sql-server-ver15
,	transaction_type = CASE tat.transaction_type	WHEN 1 THEN 'Read/write transaction'
												WHEN 2 THEN 'Read-only transaction'
												WHEN 3 THEN 'System transaction'
												WHEN 4 THEN 'Distributed transaction' END
,	input_buffer	= ib.event_info
,	transaction_uow	--for distributed transactions. 
,	transaction_state= CASE tat.transaction_state	
						WHEN 0 THEN 'The transaction has not been completely initialized yet.'
						WHEN 1 THEN 'The transaction has been initialized but has not started.'
						WHEN 2 THEN 'The transaction is active - has not been committed or rolled back.'
						WHEN 3 THEN 'The transaction has ended. This is used for read-only transactions.'
						WHEN 4 THEN 'The commit process has been initiated on the distributed transaction. This is for distributed transactions only. The distributed transaction is still active but further processing cannot take place.'
						WHEN 5 THEN 'The transaction is in a prepared state and waiting resolution.'
						WHEN 6 THEN 'The transaction has been committed.'
						WHEN 7 THEN 'The transaction is being rolled back.'
						WHEN 8 THEN 'The transaction has been rolled back.' END 
,	transaction_name = tat.name
,	azure_dtc_state	--Applies to: Azure SQL Database (Initial release through current release).
				=	CASE dtc_state 
					WHEN 1 THEN 'ACTIVE'
					WHEN 2 THEN 'PREPARED'
					WHEN 3 THEN 'COMMITTED'
					WHEN 4 THEN 'ABORTED'
					WHEN 5 THEN 'RECOVERED' END
,	tst.is_user_transaction, tst.is_local
,	session_open_transaction_count = tst.open_transaction_count --uncommitted and unrolled back transactions open. 
,	s.login_time, s.host_name, s.program_name, s.client_interface_name, s.login_name, s.is_user_process, s.cpu_time, s.logical_reads, s.reads, s.writes
,	request_status = r.status

FROM sys.dm_tran_active_transactions tat 
INNER JOIN sys.dm_tran_session_transactions tst  on tat.transaction_id = tst.transaction_id
INNER JOIN Sys.dm_exec_sessions s on s.session_id = tst.session_id 
LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
CROSS APPLY sys.dm_exec_input_buffer(s.session_id, null) AS ib 
WHERE s.database_id = db_id() and s.session_id <> @@SPID


/*
--Optional, insert into table.
DROP TABLE IF EXISTS [dbo].[uncommitted_transactions]
CREATE TABLE [dbo].[uncommitted_transactions](
	ID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_uncommitted_transactions PRIMARY KEY,
	[Observed] [datetimeoffset](7) NOT NULL INDEX IDX_uncommitted_transactions_Observed,
	[transaction_id] [bigint] NOT NULL,
	[transaction_begin_time] [datetime] NOT NULL,
	[session_id] [int] NOT NULL,
	[database_name] [nvarchar](128) NULL,
	[transaction_duration_s] [int] NULL,
	[transaction_type] [varchar](23) NULL,
	[input_buffer] [nvarchar](max) NULL,
	[transaction_uow] [uniqueidentifier] NULL,
	[transaction_state] [varchar](198) NULL,
	[transaction_name] [nvarchar](32) NOT NULL,
	[azure_dtc_state] [varchar](9) NULL,
	[is_user_transaction] [bit] NOT NULL,
	[is_local] [bit] NOT NULL,
	[session_open_transaction_count] [int] NOT NULL,
	[login_time] [datetime] NOT NULL,
	[host_name] [nvarchar](128) NULL,
	[program_name] [nvarchar](128) NULL,
	[client_interface_name] [nvarchar](32) NULL,
	[login_name] [nvarchar](128) NOT NULL,
	[is_user_process] [bit] NOT NULL,
	[cpu_time] [int] NOT NULL,
	[logical_reads] [bigint] NOT NULL,
	[reads] [bigint] NOT NULL,
	[writes] [bigint] NOT NULL,
	[request_status] [nvarchar](30) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

*/
--all databases
--Note optional INSERT 
exec sp_msforeachdb N'insert into dbo.uncommitted_transactions
select Observed = sysdatetimeoffset(), tat.transaction_id, tat.transaction_begin_time, tst.session_id 
,	database_name	= db_name(s.database_id) 
,	trn_duration_s = datediff(s, tat.transaction_begin_time, sysdatetime())
,	trn_type = CASE tat.transaction_type WHEN 1 THEN ''Read/write tran''
	WHEN 2 THEN ''Read-only''
	WHEN 3 THEN ''System''
	WHEN 4 THEN ''Distributed trn'' END
,	input_buffer	= ib.event_info
,	transaction_uow	 
,	trn_state= CASE tat.transaction_state WHEN 0 THEN ''trn has not been completely initialized yet.''
WHEN 1 THEN ''trn has been initialized but has not started.''
WHEN 2 THEN ''trn is active - has not been committed or rolled back.''
WHEN 3 THEN ''trn has ended. This is used for read-only trns.''
WHEN 4 THEN ''commit process has been initiated on the distributed trn.''
WHEN 5 THEN ''trn is in a prepared state and waiting resolution.''
WHEN 6 THEN ''trn has been committed.''
WHEN 7 THEN ''trn is being rolled back.''
WHEN 8 THEN ''trn has been rolled back.'' END 
,	trn_name = tat.name
,	azure_dtc_state	 =	CASE dtc_state WHEN 1 THEN ''ACTIVE''
WHEN 2 THEN ''PREPARED''
WHEN 3 THEN ''COMMITTED''
WHEN 4 THEN ''ABORTED''
WHEN 5 THEN ''RECOVERED'' END
,	tst.is_user_transaction, tst.is_local
,	session_open_trn_count = tst.open_transaction_count  
,	s.login_time, s.host_name, s.program_name, s.client_interface_name, s.login_name, s.is_user_process, s.cpu_time, s.logical_reads, s.reads, s.writes
,	request_status = r.status 
FROM sys.dm_tran_active_transactions tat 
INNER JOIN sys.dm_tran_session_transactions tst  on tat.transaction_id = tst.transaction_id
INNER JOIN Sys.dm_exec_sessions s on s.session_id = tst.session_id 
LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
CROSS APPLY sys.dm_exec_input_buffer(s.session_id, null) AS ib 
WHERE db_name(s.database_id)=''?'' and s.session_id <> @@SPID
'
go
select * from dbo.uncommitted_transactions