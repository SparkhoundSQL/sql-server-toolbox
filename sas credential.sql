--Create an SAS credential

--A PS script to create the storage account and SAS keys is here: https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/sql-server-backup-to-url?view=sql-server-2017#Examples

--But if the storage account already exists, how to get key using Azure Storage Explorer?
--Click on "Get Shared Access Signature..." key for the container. Specify permissions and a far-off expiration date.
--The Secret is the Query String minus the leading ?

CREATE CREDENTIAL [https://storageaccount.blob.core.windows.net/containername] --No trailing / 
WITH IDENTITY='Shared Access Signature'
, SECRET='st=2019-04-17T01%3A26%3A32ZwhateverwhateverDqdgo%3D'; --this is a sample only

--IMPORTANT: Backup up this CREDENTIAL creation script here once created!!