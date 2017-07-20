use dbalogging
go
--setup kill detect blocking sessions
--drop table dbo.ExecRequestsLog  
go
create table dbo.ExecRequestsLog  (
		id int IDENTITY(1,1) not null PRIMARY KEY
	,	timecaptured datetime
	,	session_id	smallint not null 
	,	request_id	int null
	,	blocking_session_id	int null
	,	blocking_these varchar(1000) NULL
	,	request_start_time	datetime null
	,	login_time datetime not null
	,	login_name nvarchar(256) null
	,	client_interface_name nvarchar(64)
	,	session_status	nvarchar(60) null
	,	request_status	nvarchar(60) null
	,	command	nvarchar(32) null
	,	sql_handle	varbinary(64) null
	,	statement_start_offset	int null
	,	statement_end_offset	int null
	,	plan_handle	varbinary (64) null
	,	database_id	smallint null
	,	user_id	int null
	,	wait_type	nvarchar (120) null
	,	wait_time_s	int null
	,	wait_resource nvarchar(120) null
	,	last_wait_type nvarchar(120) null
	,	cpu_time_s	int null
	,	tot_time_s	int null
	,	reads	bigint null
	,	writes	bigint null
	,	logical_reads	bigint null
	,	[host_name] nvarchar(256) null
	,	[program_name] nvarchar(256) null
	,	percent_complete int null
	,	session_transaction_isolation_level varchar(20) null
	,	request_transaction_isolation_level varchar(20) null
	,	offsettext nvarchar(4000) null
	,	kill_text nvarchar(100) null
	)
