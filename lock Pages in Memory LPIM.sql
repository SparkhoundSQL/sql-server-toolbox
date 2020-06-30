--SQL 2016 SP1 or above only!!!
use TempDB;
GO
select sql_memory_model_Desc 
--Conventional = Lock Pages in Memory privilege is not granted
--LOCK_PAGES = Lock Pages in Memory privilege is granted
--LARGE_PAGES = Lock Pages in Memory privilege is granted in Enterprise mode with Trace Flag 834 ON
from sys.dm_os_sys_info;


/* 
If LPIM is enabled, MAX SERVER MEMORY MUST BE CONFIGURED conservatively. It WILL cause problems with Windows if memory is exhausted.
FWIW LPIM not used in Azure, because they do not have issues with working set trim problems. 
*/