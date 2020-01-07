--Lab for testing nested sproc transaction rollback/commit.

create table testingonly
(id int not null identity(1,1) primary key
, testvarchar varchar(100) )
go
select * from testingonly
go

Create or ALTER procedure sproc2
as 
begin
	set xact_abort on
	begin tran t2;
	begin try 

	select 'sproc2'
	insert into testingonly (testvarchar) values ('inserted into sproc2')
	select 1/0;
	

	commit tran t2
	end try
	begin catch
	select 'in sproc2 catch' + str(@@TRANCOUNT)
	IF @@TRANCOUNT > 0
			rollback tran;
	select 'rollback in sproc2', error_message()
	throw
	end catch
end
go

create or ALTER procedure sproc1
as
begin
	set xact_abort on
	begin tran t1;
	begin try
		select 'sproc1'

		insert into testingonly (testvarchar) values ('inserted into sproc1 1')
		exec sproc2
		insert into testingonly (testvarchar) values ('inserted into sproc1 2')
	commit tran t1;
	end try
	begin catch
		select 'in sproc1 catch' + str(@@TRANCOUNT)
		IF @@TRANCOUNT > 0
			rollback tran;
		select 'rollback in sproc1', error_message()
		--throw --comment out if you want the parent not to throw an error.
	end catch
END
GO


exec sproc1 
go
select * from testingonly

go
drop table if exists testingonly
drop procedure if exists sproc1
drop procedure if exists sproc2
go

