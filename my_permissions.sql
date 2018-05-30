select suser_sname(); --you
execute as login = 'whateverloginname' --login name you want to test

use Labor_Mobile_Labor
select suser_sname(), * from sys.fn_my_permissions (null, 'DATABASE') --https://msdn.microsoft.com/en-us/library/ms176097.aspx
REVERT; --undo the execute as
select suser_sname(); --you

use Labor_Mobile_Labor
--GRANT EXECUTE  to whateverusername --granting database permissions here to user. Typically, this shares the same name as the Login, but not necessarily.


--Get members of a security group from within SQL
EXEC master..xp_logininfo 
@acctname = '[group]',
@option = 'members'