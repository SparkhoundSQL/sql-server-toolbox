--Create an SAS credential

--A PS script to create the storage account and SAS keys is here: https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/sql-server-backup-to-url?view=sql-server-2017#Examples

--But if the storage account already exists, how to get key using Azure Storage Explorer?
--Click on "Get Shared Access Signature..." key for the container. Specify permissions and a far-off expiration date.
--The Secret is the Query String minus the leading ?
--From the Azure portal, use the Shared Access Signature page of the storage account, "Generate SAS and Connection string", then use the SAS Token minus the leading ?.

--drop credential [https://container.blob.core.windows.net/folder]
GO

CREATE CREDENTIAL [https://container.blob.core.windows.net/folder] --No trailing /, folder name should be included, folder name must not include a hyphen.
WITH IDENTITY='Shared Access Signature'
, SECRET='sv=2018-03-28&ss=bfqt&srt=sco&sp=rwdlacup&se=2099-08-19T23:56:04Z&st=2019-08-19T15:56:04Z&spr=https&sig=ZWHPwhateverD'; --this is a sample only

--IMPORTANT: Backup up this CREDENTIAL creation script here once created!!