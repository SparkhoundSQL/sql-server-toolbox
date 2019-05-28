--Check for untrusted or disabled FK's
--Could be a silent performance drag if FK's exist but aren't trusted.
--See also: "lab - fk untrusted or disabled check.ipnynb" or "lab - fk untrusted or disabled check.sql"
--Careful! Trusting or enabling a FK could cause application errors if invalid child table entries are expected

SELECT  
	Table_Name	= s.name + '.' +o.name 
,	FK_Name		= fk.name 
,	fk.is_not_trusted
,	fk.is_disabled
,	'ALTER TABLE [' + s.name + '].[' +o.name +']
		WITH CHECK  
		CHECK CONSTRAINT ['+fk.name+'];' --trusts and enables the FK
FROM    sys.foreign_keys as fk
        INNER JOIN sys.objects as o ON fk.parent_object_id = o.object_id
        INNER JOIN sys.schemas as s ON o.schema_id = s.schema_id
where 	fk.is_not_trusted = 1 
or		fk.is_disabled = 1 

/*

--Check all databases:
--Some not trusted FK's are common in the SSRS ReportServer and ReportServerTempDB databases 
exec sp_msforeachdb 'use [?];
SELECT  
	DB_Name = ''?''
,	Table_Name	= s.name + ''.'' +o.name 
,	FK_Name		= fk.name 
,	fk.is_not_trusted
,	fk.is_disabled
,	''ALTER TABLE ['' + s.name + ''].['' +o.name +'']
		WITH CHECK  
		CHECK CONSTRAINT [''+fk.name+''];'' --trusts and enables the FK
FROM    sys.foreign_keys as fk
        INNER JOIN sys.objects as o ON fk.parent_object_id = o.object_id
        INNER JOIN sys.schemas as s ON o.schema_id = s.schema_id
where 	fk.is_not_trusted = 1 
or		fk.is_disabled = 1 ';

*/

/* --Sample:

ALTER TABLE [dbo].[table2]
		WITH CHECK  
		CHECK CONSTRAINT [FK_table2_table1];

*/