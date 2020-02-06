--Will generate a script to backup all database keys, including the master key if it exists.
--Use to backup database master keys used for row-level encryption. 

--Not so useful for TDE, instead see: toolbox\lab - tde encryption workshop 2014.sql

--name = ''##MS_DatabaseMasterKey##'' is the database master key

--TODO: Add password to two places where text = passwordhere but DO NOT SAVE THIS FILE WITH PASSWORD
--		The password must be the current password for the database key. 
--		If the password is not known, you must regenerate the password and immediately re-backup the key. Note this will force all encyrypted data to be unencrypted and re-encrypted. It is transparent but could be time-consuming.
--		https://docs.microsoft.com/sql/t-sql/statements/alter-master-key-transact-sql follow directions to REGENERATE key with new password.

exec sp_msforeachdb 'use [?];
if exists(select * from sys.symmetric_keys )
begin
select ''Database key(s) found in [?]''
select ''USE [?];''
select ''OPEN MASTER KEY DECRYPTION BY PASSWORD = ''''passwordhere'''';   
BACKUP MASTER KEY TO FILE = ''''c:\temp\?_''+name+''_20200131.key''''
    ENCRYPTION BY PASSWORD = ''''passwordhere'''';
GO  ''
from sys.symmetric_keys;
END';

--exec sp_msforeachdb 'use [?]; select ''[?]'',* from sys.symmetric_keys';