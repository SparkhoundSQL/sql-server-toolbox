use master
go
declare @sql_handle binary(20)
select *, DBName = db_name(dbid) from sys.sysprocesses sysprc 
where spid <> @@SPID
--and db_name(dbid)  = 'LPMS_BE'
order by blocked desc, spid asc 

declare cursyssysprocesses cursor fast_forward for 
select sql_handle from sys.sysprocesses 
where spid >= 50 
and sql_handle <> convert(binary(20), 0x0000000000000000000000000000000000000000)--status='runnable';
and spid <> @@SPID
order by spid

open cursyssysprocesses;
	fetch next from cursyssysprocesses into @sql_handle; 
	while (@@FETCH_STATUS =0) 
	BEGIN 
		select 
			spid
		,	sql_handle
		,	b.hostname
		,	c.name
		,	b.program_name
		,	b.loginame
		,	b.spid
		,	getsql.text
		,	getsql.objectid
		,	DatabaseName	=	db_name(getsql.dbid)	
		,	getsql.dbid
		from sys.fn_get_sql(@sql_handle) getsql
		cross join sysprocesses b
		inner join  sys.sysdatabases c on c.dbid=b.dbid
		where b.sql_handle =@sql_handle
		fetch next from cursyssysprocesses into @sql_handle;
	END 
close cursyssysprocesses
deallocate cursyssysprocesses
