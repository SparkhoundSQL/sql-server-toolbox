
--change to text mode
--Log in with denyprincipal

use securitydemo
go
select * from dbo.DenyTable
go
select * from dbo.DenyTableview
go
exec dbo.DenyTablesproc
go
exec dbo.DenyTablesproc_adhoc
go
select * from dbo.DenyFunc()

/*

SELECT ORIGINAL_LOGIN(), CURRENT_USER;

*/