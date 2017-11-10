
--SQL 2016 SP1 or above only!!!

select sql_memory_model_Desc 
--Conventional = Lock Pages in Memory privilege is not granted
--LOCK_PAGES = Lock Pages in Memory privilege is granted
--LARGE_PAGES = Lock Pages in Memory privilege is granted in Enterprise mode with Trace Flag 834 ON
from sys.dm_os_sys_info 
