--Script to test permissions

select suser_sname(); --you
execute as login = 'domain\test.user' --login name you want to test

use master
select suser_sname(), * from sys.fn_my_permissions (null, 'DATABASE') --https://msdn.microsoft.com/en-us/library/ms176097.aspx

REVERT; --undo the execute as
select suser_sname(); --you



--See also script to check security group membership - toolbox\security group members.sql