--TODO: Change Master key name to include instance name. 
--TODO: Change password to complex, unique password for this key.
--You may also want to check for database master keys that need to be backed up: toolbox\backup database master keys.sql

BACKUP SERVICE MASTER KEY --not actually important for TDE, but important overall and should be backed up regardless.
TO FILE = 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\InstanceNameHere_SQLServiceMasterKey_20120314.snk' 
    ENCRYPTION BY PASSWORD = 'complexpasswordhere'

--THEN, TODO:
--Move the file to enterprise security vault, along with its password, associated with the SQL instance. 


/*
--To restore, in the event of a restoring a master database to a new install, for example:

RESTORE SERVICE MASTER KEY FROM FILE = 'path_to_file'   
    DECRYPTION BY PASSWORD = 'password' FORCE

*/