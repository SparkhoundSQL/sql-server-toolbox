--Check to see if the SQL Server Database Engine service has instant_file_initialization_enabled.
--Works on SQL 2016 SP1, 2012 SP4+
Use TempDB

select servicename, instant_file_initialization_enabled, @@VERSION
from sys.dm_server_services
where filename like '%sqlservr.exe%'