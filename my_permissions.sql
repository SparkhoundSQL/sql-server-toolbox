select suser_sname(); --you
execute as login = 'sparkhound\test.user' --login name you want to test

use master
select suser_sname(), * from sys.fn_my_permissions (null, 'DATABASE') --https://msdn.microsoft.com/en-us/library/ms176097.aspx

REVERT; --undo the execute as
select suser_sname(); --you

use master
--GRANT EXECUTE  to [sparkhound\test.user] --granting database permissions here to user. Typically, this shares the same name as the Login, but not necessarily.


--Get members of a windows security group from within SQL
--Returns members but NOT subgroups! There isn't a way in SQL to see subgroups.
EXEC master..xp_logininfo 
@acctname = 'domain\groupname',
@option = 'members'
