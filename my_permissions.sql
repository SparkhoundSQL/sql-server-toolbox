
execute as login = 'whateverloginname' --login name you want to test
use Labor_Mobile_Labor
select * from sys.fn_my_permissions (null, 'DATABASE') --https://msdn.microsoft.com/en-us/library/ms176097.aspx
REVERT; --undo the execute as

use Labor_Mobile_Labor
GRANT EXECUTE  to whateverusername --granting database permissions here to user. Typically, this shares the same name as the Login, but not necessarily.

