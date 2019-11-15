--Demonstrate wait type reduction with new OPTIMIZE_FOR_SEQUENTIAL_KEY in SQL 2019
-- First run without OPTIMIZE_FOR_SEQUENTIAL_KEY, then run with OPTIMIZE_FOR_SEQUENTIAL_KEY

use w
go
dbcc freeproccache
dbcc dropcleanbuffers
go
--RUN ENTIRE SCRIPT
DROP TABLE IF EXISTS dbo.fragmented_table_int
go
CREATE TABLE dbo.fragmented_table_int
	(
	fragid int NOT NULL IDENTITY(1,1),
	fragtext varchar(100) NOT NULL
	)  
GO
ALTER TABLE dbo.fragmented_table_int ADD CONSTRAINT
	PK_fragmented_table_int PRIMARY KEY CLUSTERED 
	(
	fragid
	) 
	 WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON --SQL 2019 only!
	)

go
CREATE NONCLUSTERED INDEX IDX_NC_fragmented_table_int
ON dbo.fragmented_table_int (FRAGTEXT) 
--  WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON --SQL 2019 only!
-- 	)

GO

create table #tempcounter (id int not null identity(1,1) primary key, counter_name sysname, cntr_value bigint, whenobserved datetimeoffset(2) not null constraint df_cntr_temp_when default (sysdatetimeoffset()))
insert into #tempcounter (counter_name, cntr_value)
select counter_name, cntr_value FROM sys.dm_os_performance_counters
where counter_name = 'Page Splits/sec'

create table #waitcounter (id int not null identity(1,1) primary key, wait nvarchar(60), val bigint, whenobserved datetimeoffset(2) not null constraint df_wait_temp_when default (sysdatetimeoffset()))
insert into #waitcounter (wait, val)
select wait_type, wait_time_ms
from sys.dm_exec_session_wait_stats
where wait_type like '%PAGELATCH%'  and session_id = @@SPID

go
--Run this block from multiple query connections simultaneously.
	insert into dbo.fragmented_table_int (fragtext) 
	select replicate(char(round(rand()*100,0)),round(rand()*100,0))
go 20000
select count(1) from dbo.fragmented_table_int
GO
insert into #waitcounter (wait, val)
select wait_type, wait_time_ms
from sys.dm_exec_session_wait_stats
where wait_type like '%PAGELATCH%'  and session_id = @@SPID
GO
insert into #tempcounter (counter_name, cntr_value)
select counter_name, cntr_value FROM sys.dm_os_performance_counters
where counter_name = 'Page Splits/sec'
GO

select a1.counter_name, a2.cntr_value - a1.cntr_value 
from #tempcounter a1
inner join #tempcounter a2 on a1.counter_name = a2.counter_name
WHERE a1.id = 1 and a2.id = 2;

select a1.wait, wait_ms = a2.val - a1.val, sum(a2.val - a1.val) OVER ()
--select * 
from #waitcounter a1
inner join #waitcounter a2 on a1.wait = a2.wait  and a2.id > a1.id
order by a1.wait, wait_ms desc
GO

drop table #tempcounter;
drop table #waitcounter;
