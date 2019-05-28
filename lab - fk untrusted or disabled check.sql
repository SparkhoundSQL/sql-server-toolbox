--Instead try the .ipynb file of the same name in Azure Data Studio
--Lab to demonstrate the difference between a trusted and enabled FK, and the eventual performance impact.

--drop table table2
--drop table table1 
GO
create table table1
(
	id int not null IDENTITY(1,1) CONSTRAINT PK_table1 PRIMARY KEY
,
	whatever varchar(100)
)
create table table2
(
	id int not null IDENTITY(1,1) CONSTRAINT PK_table2 PRIMARY KEY
,
	table1id int not null CONSTRAINT FK_table2_table1 FOREIGN KEY REFERENCES dbo.table1 (id) --No WITH CHECK needed here. Creates the FK trusted.
,
	whatever varchar(100)
)
GO
INSERT INTO table1
	(whatever)
values
	('abc')
GO
INSERT INTO table1
	(whatever)
select left(whatever + str(id),100)
from table1 
GO 15 --2^15 or 32,768 rows
GO
INSERT INTO [dbo].[table2]
	(table1id, whatever)
select id, whatever
from [dbo].[table1]
GO
SELECT
	Table_Name	= s.name + '.' +o.name 
, FK_Name		= fk.name 
, fk.is_not_trusted
, fk.is_disabled
FROM sys.foreign_keys as fk
	INNER JOIN sys.objects as o ON fk.parent_object_id = o.object_id
	INNER JOIN sys.schemas as s ON o.schema_id = s.schema_id
where o.name in ('table1','table2')

/*

The origin of the problem is when you script out the FK with SSMS.

Let's reproduce by using the same code SSMS produces when you script out drop/creating a FK.
*/


ALTER TABLE [dbo].[table2] DROP CONSTRAINT [FK_table2_table1]
GO
ALTER TABLE [dbo].[table2]  WITH NOCHECK ADD  CONSTRAINT [FK_table2_table1] FOREIGN KEY([table1id]) --Note the NOCHECK here. The FK is enabled but not Trusted.
REFERENCES [dbo].[table1] ([id])
GO
ALTER TABLE [dbo].[table2] CHECK CONSTRAINT [FK_table2_table1] --This doesn't re-trust the FK!
GO

SELECT  
	Table_Name	= s.name + '.' +o.name 
,	FK_Name		= fk.name 
,	fk.is_not_trusted
,	fk.is_disabled
FROM    sys.foreign_keys as FK
        INNER JOIN sys.objects as o ON fk.parent_object_id = o.object_id
        INNER JOIN sys.schemas as s ON o.schema_id = s.schema_id
where o.name in ('table1','table2')


/*

Let's try to insert a value that shouldn't be allowed.

The Insert is blocked even though the FK isn't trusted, because it is still enabled. We do get an error.

*/

INSERT INTO [dbo].[table2] (table1id, whatever) 
OUTPUT inserted.table1id, inserted.whatever
VALUES (-1, 'whatever')
GO
SELECT  
	Table_Name	= s.name + '.' +o.name 
,	FK_Name		= fk.name 
,	fk.is_not_trusted
,	fk.is_disabled
FROM    sys.foreign_keys as FK
        INNER JOIN sys.objects as o ON fk.parent_object_id = o.object_id
        INNER JOIN sys.schemas as s ON o.schema_id = s.schema_id
where o.name in ('table1','table2')
GO

/*
The concept of disabling a FK vs not trusting a FK is important.

A disabled FK will allow invalid data into the child table at any time.

A FK can be created without trust so that it will allow EXISTING invalid data in the child table, but still block NEW invalid data in the child table.
*/

ALTER TABLE [dbo].[table2] 
NOCHECK CONSTRAINT [FK_table2_table1] --Note: no WITH, just NOCHECK, this DISABLES the FK. 
GO
SELECT  
	Table_Name	= s.name + '.' +o.name 
,	FK_Name		= fk.name 
,	fk.is_not_trusted
,	fk.is_disabled
FROM    sys.foreign_keys as FK
        INNER JOIN sys.objects as o ON fk.parent_object_id = o.object_id
        INNER JOIN sys.schemas as s ON o.schema_id = s.schema_id
where o.name in ('table1','table2')
GO
--Try to insert a value that shouldn't be allowed
--The Insert is NOT blocked because the FK is disabled.
INSERT INTO [dbo].[table2] (table1id, whatever) 
OUTPUT inserted.table1id, inserted.whatever
VALUES (-1, 'whatever')
GO
ALTER TABLE [dbo].[table2] 
CHECK CONSTRAINT [FK_table2_table1] --Note: Enables the foreign key but does not mark it as trusted. Re-enabling the FK with invalid data in the child table still works!
GO
SELECT  
	Table_Name	= s.name + '.' +o.name 
,	FK_Name		= fk.name 
,	fk.is_not_trusted
,	fk.is_disabled
FROM    sys.foreign_keys as FK
        INNER JOIN sys.objects as o ON fk.parent_object_id = o.object_id
        INNER JOIN sys.schemas as s ON o.schema_id = s.schema_id
where o.name in ('table1','table2')
GO

/*

Let's try to re-trust a FK while invalid records exist in the child table.

*/

SELECT  
	Table_Name	= s.name + '.' +o.name 
,	FK_Name		= fk.name 
,	fk.is_not_trusted
,	fk.is_disabled
FROM    sys.foreign_keys as FK
        INNER JOIN sys.objects as o ON fk.parent_object_id = o.object_id
        INNER JOIN sys.schemas as s ON o.schema_id = s.schema_id
where o.name in ('table1','table2')
GO
ALTER TABLE [dbo].[table2] 
WITH CHECK  --Note: ATTEMPT to re-trust the foreign key. This command reverses the previous WITH NOCHECK. Re-trusting the FK with invalid data in the child table does NOT work! Will have to clean up data.
CHECK CONSTRAINT [FK_table2_table1] 
GO
DELETE FROM [dbo].[table2]  -- Clean up invalid data in the child table. In reality, you'll want to update invalid relations in the child table, or add new records in the parent table to make them valid. 
OUTPUT deleted.table1id, deleted.whatever
where table1id not in (select id from [dbo].[table1])
GO
ALTER TABLE [dbo].[table2] 
WITH CHECK  --Note: Re-trusts the foreign key. This is successful, and now the FK is trusted and enabled and can be used by SQL Server.
CHECK CONSTRAINT [FK_table2_table1] 
GO
SELECT  
	Table_Name	= s.name + '.' +o.name 
,	FK_Name		= fk.name 
,	fk.is_not_trusted
,	fk.is_disabled
FROM    sys.foreign_keys as FK
        INNER JOIN sys.objects as o ON fk.parent_object_id = o.object_id
        INNER JOIN sys.schemas as s ON o.schema_id = s.schema_id
where o.name in ('table1','table2')
GO

/*

What's the real impact of an untrusted FK? Let's use a simple query.

*/

ALTER TABLE [dbo].[table2] DROP CONSTRAINT [FK_table2_table1]
GO
ALTER TABLE [dbo].[table2]  
WITH NOCHECK --Creates the Foreign Key but doesn't trust it! It's not enforced.
ADD  CONSTRAINT [FK_table2_table1] FOREIGN KEY([table1id])
REFERENCES [dbo].[table1] ([id])
GO
SELECT  
	Table_Name	= s.name + '.' +o.name 
,	FK_Name		= fk.name 
,	fk.is_not_trusted
,	fk.is_disabled
FROM    sys.foreign_keys as FK
        INNER JOIN sys.objects as o ON fk.parent_object_id = o.object_id
        INNER JOIN sys.schemas as s ON o.schema_id = s.schema_id
where o.name in ('table1','table2')
GO
SET SHOWPLAN_TEXT ON
GO
select table2.id  from table1 inner join table2 on table1.id = table2.table1id
GO
SET SHOWPLAN_TEXT OFF
GO

/*

Without a trusted FK (above), SQL can't assume the data is valid in both side of the inner join. Two clustered index scans.

With a trusted FK (below), SQL can assume the data is valid in both side of the inner join. Skips the scan on table 1.

*/

ALTER TABLE [dbo].[table2] 
WITH CHECK  --Note: Re-trusts the foreign key. This command reverses the previous WITH NOCHECK. Re-trusting the FK with invalid data in the child table does NOT work! Will have to clean up data.
CHECK CONSTRAINT [FK_table2_table1] 
GO

SELECT  
	Table_Name	= s.name + '.' +o.name 
,	FK_Name		= fk.name 
,	fk.is_not_trusted
,	fk.is_disabled
FROM    sys.foreign_keys as FK
        INNER JOIN sys.objects as o ON fk.parent_object_id = o.object_id
        INNER JOIN sys.schemas as s ON o.schema_id = s.schema_id
where o.name in ('table1','table2')
GO
SET SHOWPLAN_TEXT ON
GO
select table2.id  from table1 inner join table2 on table1.id = table2.table1id
GO
SET SHOWPLAN_TEXT OFF
GO

/*

Cleanup

*/

drop table dbo.table2 
drop table dbo.table1 
