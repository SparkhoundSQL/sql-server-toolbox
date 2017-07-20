
/* Drop and Recreate Table objects
This script drops and recreated default constraints, triggers and check constraints
for any table inserted into ##Drop_and_Recreate_Objects.
It does not recreate foreign keys, partitions or indexes.
*/

/*
--SAMPLE SETUP CODE

drop table tabledc1
drop table tabledc2
go
create table tabledc1
(	id int identity(1,1) not null primary key
,	dfcol1 int not null			CONSTRAINT DF_tabledc1_dfcol1 DEFAULT (0) 
,	dfcol2 varchar (4) not null CONSTRAINT DF_tabledc1_dfcol2 DEFAULT ('test') 
,	dfcol3 datetime not null	CONSTRAINT DF_tabledc1_dfcol3 DEFAULT (getdate()) 
,	dfcol4 bit not null			CONSTRAINT DF_tabledc1_dfcol4 DEFAULT (1)
,	dfcol5 int not null			DEFAULT (0)
,	dfcol6 bit not null			DEFAULT (1)
)
create table tabledc2
(	id int identity(1,1) not null primary key
,	dfcol1 int not null			CONSTRAINT DF_tabledc2_dfcol1 DEFAULT (0) 
,	dfcol2 varchar (4) not null CONSTRAINT DF_tabledc2_dfcol2 DEFAULT ('test') 
,	dfcol3 datetime not null	CONSTRAINT DF_tabledc2_dfcol3 DEFAULT (getdate()) 
,	dfcol4 bit not null			CONSTRAINT DF_tabledc2_dfcol4 DEFAULT (1)
,	dfcol5 int not null			DEFAULT (0)
,	dfcol6 bit not null			DEFAULT (1)
)

ALTER TABLE dbo.tabledc1 ADD CONSTRAINT CK_Vendor_CreditRating CHECK (dfcol1 >= 0 AND dfcol1 <= 5)
ALTER TABLE dbo.tabledc2 ADD CHECK (dfcol1 >= 0 AND dfcol1 <= 5)

drop view view1
drop table tablet1
drop table tablet2
go
create table tablet1 (id int identity(1,1) not null primary key)
create table tablet2 (id int identity(1,1) not null primary key)
go
create view view1 as  select * from tablet1
go
CREATE TRIGGER [dbo].view1_trigger1 ON  dbo.view1 INSTEAD OF INSERT,UPDATE  AS
BEGIN
DECLARE @invno AS float
SELECT @invno = id FROM inserted
END
go
CREATE TRIGGER [dbo].tablet1_trigger1 ON  dbo.tablet1 AFTER INSERT,UPDATE,DELETE AS
BEGIN
DECLARE @invno AS float
SELECT @invno = id FROM inserted
END
go
CREATE TRIGGER [dbo].tablet1_trigger2 ON  dbo.tablet1 INSTEAD OF INSERT,UPDATE,DELETE AS
BEGIN
DECLARE @invno AS float
SELECT @invno = id FROM inserted
END
go
CREATE TRIGGER [dbo].tablet1_trigger3  ON  dbo.tablet1 FOR INSERT,UPDATE,DELETE AS
BEGIN
DECLARE @invno AS float
SELECT @invno = id FROM inserted
END
go
CREATE TRIGGER [dbo].tablet2_trigger1 ON  dbo.tablet2 AFTER INSERT,UPDATE,DELETE AS
BEGIN
DECLARE @invno AS float
SELECT @invno = id FROM inserted
END
go
CREATE TRIGGER [dbo].tablet2_trigger2  ON  dbo.tablet2 INSTEAD OF INSERT,UPDATE,DELETE AS
BEGIN
DECLARE @invno AS float
SELECT @invno = id FROM inserted
END
go
CREATE TRIGGER [dbo].tablet2_trigger3 ON  dbo.tablet2 FOR INSERT,UPDATE,DELETE AS
BEGIN
DECLARE @invno AS float
SELECT @invno = id FROM inserted
END
go
exec sp_settriggerorder @Triggername = N'dbo.tablet1_trigger1', @order = 'first', @stmttype = 'update'
exec sp_settriggerorder @Triggername = N'dbo.tablet1_trigger3', @order = 'last', @stmttype = 'delete'
exec sp_settriggerorder @Triggername = N'dbo.tablet2_trigger1', @order = 'first', @stmttype = 'update'
exec sp_settriggerorder @Triggername = N'dbo.tablet2_trigger3', @order = 'last', @stmttype = 'delete'
go

BEGIN TRY 
DROP TABLE ##Drop_and_Recreate_Objects;
END TRY
BEGIN CATCH
END CATCH 

CREATE TABLE ##Drop_and_Recreate_Objects (	table_object_id int not null PRIMARY KEY ) 
go

--Example of how to add a table to get its DFs, TRs and CKs recreated.
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_tax_brkdwn_headers]')) 
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tabledc2]')) 
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tablet1]')) 
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tablet2]')) 
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[view1]')) 
--GO
go
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[testonlinerebuild]')) 
insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fktable1]')) 
insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fktable2]')) 
insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fktable3]')) 
insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fktable4]')) 
insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fktable5]')) 
insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fktable6]')) 
insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fktable7]')) 
insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fktable8]')) 
insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fktable9]')) 
insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fktable10]')) 
insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fktable11]')) 
go
select object_name(table_object_id), * from ##Drop_and_Recreate_Objects where object_name(table_object_id) is not null order by object_name(table_object_id)

insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[pohdr]'))
go
exec dbo.Drop_and_Store_Table_Objects   @testingMode = 0, @AuditingMode = 1
exec dbo.Alter_Floats_to_Decimal		@testingMode = 0, @AuditingMode = 1
exec dbo.Recreate_Stored_Table_Objects  @testingMode = 0, @AuditingMode = 1

*/

BEGIN TRY 
DROP TABLE ##Drop_and_Recreate_Objects;
END TRY
BEGIN CATCH
END CATCH 

CREATE TABLE ##Drop_and_Recreate_Objects (	table_object_id int not null PRIMARY KEY ) 
go



--if OBJECT_ID('dbo.Fix_Duplicate_PK_Floats') is not null
--drop procedure dbo.Fix_Duplicate_PK_Floats
--go
--create procedure dbo.Fix_Duplicate_PK_Floats (@TestingMode bit = 0, @AuditingMode bit = 0)
--WITH RECOMPILE
--AS 
--BEGIN 

--	SET XACT_ABORT ON

--	declare @PKtableTSQL as varchar(8000), @FKTableTSQL as varchar(8000), @Referenced_object_id as int, @referenced_object_name as varchar(200), @pkcol as varchar(200)
--	,	@fkcol as varchar(200) = '', @referencing_object_name as varchar(200) = '', @Referencing_object_id as int = ''
--	,	@previous_Referenced_object_id as int = 0

	
--	BEGIN TRY 
--	DROP TABLE ##ChangeKey;	
--	END TRY
--	BEGIN CATCH
--	END CATCH 



--	CREATE TABLE ##ChangeKey (pkcol decimal(19,6) not null  , newpkcol decimal(19,6) not null,  UNIQUE CLUSTERED (pkcol,newpkcol))

--	DECLARE fixDupFloats CURSOR FAST_FORWARD FOR 
--	--select DISTINCT
--	--	Referenced_object_id	
--	--,	referenced_object_name	
--	--,	pkcol	
--	--FROM ##DupPK_Floats_to_Drop_and_Recreate pk
--	--INNER JOIN sys.objects o
--	--on pk.Referenced_object_id = o.object_id
--	--inner join sys.columns c
--	--on c.object_id = o.object_id and c.name = pk.pkcol
--	--inner join sys.types t 
--	--on t.user_type_id = c.user_type_id
--	--WHERE Referenced_object_id is not null
--	--and t.name in ('float', 'real')

--	select DISTINCT
--		Referenced_object_id	
--	,	referenced_object_name	
--	,	pkcol					
--	,	fkcol					
--	,	referencing_object_name 
--	,	Referencing_object_id	
--	FROM ##DupPK_Table_Floats_to_Drop_and_Recreate pk
--	INNER JOIN sys.objects o
--	on pk.Referenced_object_id = o.object_id
--	inner join sys.columns c
--	on c.object_id = o.object_id and c.name = pk.pkcol
--	inner join sys.types t 
--	on t.user_type_id = c.user_type_id
--	WHERE Referenced_object_id is not null
--	and t.name in ('float', 'real')

--	OPEN fixDupFloats 
--		FETCH NEXT FROM fixDupFloats INTO @Referenced_object_id, @referenced_object_name, @pkcol, @fkcol, @referencing_object_name, @Referencing_object_id	
--		WHILE @@FETCH_STATUS = 0
--		BEGIN

--			If @previous_Referenced_object_id <> @Referenced_object_id --Check is same referenced object as last loop. We expected this.
--			BEGIN

--					TRUNCATE TABLE ##ChangeKey
	
--					IF @AuditingMode = 1 	
--					select DISTINCT
--							Referenced_object_id	
--						,	referenced_object_name	
--						,	pkcol					
--						,	fkcol					
--						,	referencing_object_name 
--						,	Referencing_object_id	
--						FROM ##DupPK_Table_Floats_to_Drop_and_Recreate
--					WHERE Referenced_object_id = @Referenced_object_id

--					IF @AuditingMode = 1 	
--					set @PKTableTSQL = 'select dupkeyfound =  ''' + @referenced_object_name + ''', ['+@pkcol+'_rounded] = round(['+@pkcol+'],2), ['+@pkcol+'], [' + replace(@pkcol, ' ','_') + '_count], instance 						
--																from (		select	['+@pkcol+']  
--																			,		['+replace(@pkcol, ' ','_')+'_count] = count(['+@pkcol+']) over (partition by round(['+@pkcol+'],2)  )
--																			,		instance = rank() over (partition by round(['+@pkcol+'],2) order by round(['+@pkcol+'],14))
--																			from  ' + @referenced_object_name + ' as ih 
--																		) x
--																		where ['+replace(@pkcol, ' ','_') + '_count] > 1  order by 1,2,3'
--					--IF @AuditingMode = 1 
--					print @PKTableTSQL
--					--IF @AuditingMode = 1 
--					exec (@PKTableTSQL)

	
--					select @PKTableTSQL = 'IF EXISTS ( select round(['+@pkcol+'], 2), count(1)  from '+@referenced_object_name+' group by round(['+@pkcol+'],2) having count(1) > 1) 
--						 BEGIN 
						 
--						 ;with cteDups ( ['+@pkcol+'], ['+replace(@pkcol, ' ','_')+'_count], instance ) as
--						(   select ['+@pkcol+'], '+replace(@pkcol, ' ', '_')+ '_count, instance 
--							from (
--								select ['+@pkcol+']
--								,	['+replace(@pkcol, ' ','_')+ '_count] = count(['+@pkcol+']) over (partition by round(['+@pkcol+'],2)  )
--								,    instance = row_number() over (partition by round(['+@pkcol+'],2) order by round(['+@pkcol+'],14))
--								from '+@referenced_object_name+' as ih 
--							) x
--							where ['+replace(@pkcol, ' ','_')+ '_count] > 1 ) 
				
--						INSERT INTO ##ChangeKey (pkcol, newpkcol)
--						SELECT DISTINCT
--							pkcol	=	d2.['+@pkcol+']
--						,	newpkcol=	convert(decimal(19,6), d2.['+@pkcol+']) + ((d2.instance -1) * .01)
--						--UPDATE ii  set 
--						--	   [' + @pkcol + ']  =      convert(decimal(19,6), d2.['+@pkcol+']) + ((d2.instance -1) * .01)
--						from	' + @referenced_object_name + ' ii
--						inner join 
--							   cteDups d1
--						on     ii.['+@pkcol+'] = d1.['+@pkcol+']
--						inner join 
--							   cteDups d2
--						on     d1.['+@pkcol+'] = d2.['+@pkcol+'];


--						UPDATE ii  set 
--							   [' + @pkcol + ']  =      newpkcol
--						from	' + @referenced_object_name + ' ii
--						inner join ##ChangeKey ck on round(ii.[' + @pkcol + '],2) = round(ck.pkcol,2)
--						WHERE round(ii.[' + @pkcol + '],2) =     newpkcol
		
--					END;';	

--					IF @AuditingMode = 1 			print 'Fixing duplicate PK on ' + @referenced_object_name + CHAR(10) + CHAR(13)
--					IF @AuditingMode = 1			select * from ##ChangeKey
--					--IF @AuditingMode = 1			print @PKTableTSQL
--					IF @TestingMode  = 0			exec (@PKTableTSQL)

--					IF @AuditingMode = 1 	
--					set @PKTableTSQL = 'select dupkeyfound =  ''' + @referenced_object_name + ''', ['+@pkcol+'_rounded] = round(['+@pkcol+'],2), ['+@pkcol+'], [' + replace(@pkcol, ' ','_') + '_count], instance 						
--										from (		select	['+@pkcol+']  
--													,		['+replace(@pkcol, ' ','_')+'_count] = count(['+@pkcol+']) over (partition by round(['+@pkcol+'],2)  )
--													,		instance = row_number() over (partition by round(['+@pkcol+'],2) order by round(['+@pkcol+'],14))
--													from  ' + @referenced_object_name + ' as ih 
--												) x
--												where ['+replace(@pkcol, ' ','_') + '_count] > 1  order by 1,2,3'
--					--IF @AuditingMode = 1			print @PKTableTSQL
--					IF @AuditingMode = 1 			exec (@PKTableTSQL)

--			END -- Check if same reference object

--			--Fix the FK records in each FK table
--			---- this isn't going to work becuase it can't tell the rows apart.
--			set @FKTableTSQL = '
--				UPDATE ii  set 
--						[' + @fkcol + ']  =      newpkcol
--				from	' + @referencing_object_name + ' ii
--				inner join ##ChangeKey ck on round(ii.[' + @fkcol + '],2) = round(ck.pkcol,2) 
--				WHERE round(ii.[' + @fkcol + '],2) = newpkcol;'

--			IF @AuditingMode = 1 
--			print @PKTableTSQL
--			IF @AuditingMode = 1 
--			exec (@PKTableTSQL)
					
--			FETCH NEXT FROM fixDupFloats INTO @Referenced_object_id, @referenced_object_name, @pkcol, @fkcol, @referencing_object_name, @Referencing_object_id	
			
--		END
--		CLOSE fixDupFloats;
--		DEALLOCATE fixDupFloats;

--		DROP TABLE ##ChangeKey;

--END
--GO

if OBJECT_ID('dbo.Alter_Floats_to_Decimal') is not null
drop procedure dbo.Alter_Floats_to_Decimal
go
create procedure dbo.Alter_Floats_to_Decimal (@TestingMode bit = 0, @AuditingMode bit = 0)
WITH RECOMPILE
AS 
BEGIN 

	SET XACT_ABORT ON

	DECLARE @tsql nvarchar(max)
	DECLARE AlterCol CURSOR FAST_FORWARD FOR 

		select 
		Alter_TSQL = 
		--'IF NOT EXISTS (SELECT TOP 1 * FROM sys.change_tracking_tables WHERE Object_id = object_id(''' + s.name + '.' + o.name + '''))'
		--+ ' ALTER TABLE [' + s.name + '].[' + o.name + '] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);' 
		+ ' ALTER TABLE [' + s.name + '].[' + o.name + '] ALTER COLUMN [' + c.name + '] DECIMAL (19,6) ' + case c.is_nullable when 1 THEN ' NULL ' ELSE ' NOT NULL ' END + ';'
		--+ ' ALTER TABLE [' + s.name + '].[' + o.name + '] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);' 		
		
		from ##Drop_and_Recreate_Objects dro
		inner join sys.objects o
		on o.object_id = dro.table_object_id
		inner join sys.columns c
		on o.object_id = c.object_id
		inner join sys.types t
		on t.user_type_id = c.user_type_id
		inner join sys.schemas s
		on s.schema_id = o.schema_id
		where t.name = 'float'
		and o.type_desc = 'user_table'

	OPEN AlterCol 
	FETCH NEXT FROM AlterCol  INTO @tsql
	WHILE @@FETCH_STATUS = 0
	BEGIN

		BEGIN TRY
			print @tsql;
			IF @TestingMode = 0 exec sp_executesql @tsql;
			FETCH NEXT FROM AlterCol  INTO @tsql
		END TRY
		BEGIN CATCH
			THROW;
			SET NOEXEC ON;
		END CATCH
	END
	CLOSE AlterCol;
	DEALLOCATE AlterCol;

END
GO

if OBJECT_ID('dbo.Drop_and_Store_Table_Objects') is not null
drop procedure dbo.Drop_and_Store_Table_Objects
go
create procedure dbo.Drop_and_Store_Table_Objects (@TestingMode bit = 0, @AuditingMode bit = 0)
WITH RECOMPILE
AS 
BEGIN 
	SET XACT_ABORT ON

	IF NOT EXISTS(select 1 from tempdb.sys.objects where name like '##Drop_and_Recreate_Objects%')
	BEGIN
		THROW 51000, '##Drop_and_Recreate_Objects does not exist.', 1;
		SET NOEXEC ON
	END

	/* 
	Reference only:
	CREATE TABLE ##Drop_and_Recreate_Objects
		(	table_object_id int not null PRIMARY KEY )
	*/

	--truncate table ##Drop_and_Recreate_Objects
	--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[pohdr]'))

	select object_name(table_object_id), * from ##Drop_and_Recreate_objects
	
	--Commented out recursion - should not be needed.
	--declare @fksadded int = 1
	--WHILE (@fksadded > 0)
	--BEGIN

	if @AuditingMode = 1 print 'Adding FK tables'

	DECLARE @FKloop int = 1

	WHILE (@FKloop > 0)
	BEGIN
		
			insert into ##Drop_and_Recreate_objects (table_object_id)
			select fk.parent_object_id --, FKTable = object_name(fk.parent_object_id), PKTable = object_name( dro.table_object_id), *
			from ##Drop_and_Recreate_objects dro
			inner join sys.foreign_keys fk on fk.referenced_object_id = dro.table_object_id
			where fk.parent_object_id not in (select table_object_id from ##Drop_and_Recreate_objects)
			group by fk.parent_object_id
		
			set @FKloop = @@ROWCOUNT 

			if @AuditingMode = 1 print 'Added ' + str(@FKLoop) + ' more referencing foreign key tables to ##Drop_and_Recreate_objects'
	END
	
	BEGIN TRY 
	DROP TABLE ##DefaultConstraints_to_Drop_and_Recreate;
	END TRY
	BEGIN CATCH
	END CATCH 

	IF @AuditingMode = 1 PRINT 'create temp tables'
	
	CREATE TABLE ##DefaultConstraints_to_Drop_and_Recreate
	(	id int not null identity (1,1) primary key
	,	object_name sysname null
	,	new_object_name sysname null
	,	object_id int not null
	,	drop_tsql	nvarchar(max) null
	,	create_tsql nvarchar(max) null
	)

	BEGIN TRY 
	DROP TABLE ##Triggers_to_Drop_and_Recreate;
	END TRY
	BEGIN CATCH
	END CATCH 

	CREATE TABLE ##Triggers_to_Drop_and_Recreate
	(	id int not null identity (1,1) primary key
	,	object_name sysname null
	,	object_id int not null
	,	drop_tsql	nvarchar(max) null
	,	create_tsql nvarchar(max) null
	)

	BEGIN TRY 
	DROP TABLE ##CheckConstraints_to_Drop_and_Recreate;
	END TRY
	BEGIN CATCH
	END CATCH 

	CREATE TABLE ##CheckConstraints_to_Drop_and_Recreate
	(	id int not null identity (1,1) primary key
	,	object_name sysname null
	,	new_object_name sysname null
	,	object_id int not null
	,	drop_tsql	nvarchar(max) null
	,	create_tsql nvarchar(max) null
	)

	BEGIN TRY 
	DROP TABLE ##Indexes_to_Drop_and_Recreate;
	END TRY
	BEGIN CATCH
	END CATCH 

	CREATE TABLE ##Indexes_to_Drop_and_Recreate
	(	id int not null identity (1,1) primary key
	,	object_name sysname null
	,	object_id int not null
	,	index_id int not null
	,	drop_tsql	nvarchar(max) null
	,	create_tsql nvarchar(max) null
	)

	BEGIN TRY 
	DROP TABLE ##IndexConstraints_to_Drop_and_Recreate;
	END TRY
	BEGIN CATCH
	END CATCH 

	CREATE TABLE ##IndexConstraints_to_Drop_and_Recreate
	(	id int not null identity (1,1) primary key
	,	object_name sysname null
	,	object_id int not null
	,	index_id int not null
	,	drop_tsql	nvarchar(max) null
	,	create_tsql nvarchar(max) null
	)

	BEGIN TRY 
	DROP TABLE ##ForeignKeys_to_Drop_and_Recreate;
	END TRY
	BEGIN CATCH
	END CATCH 

	CREATE TABLE ##ForeignKeys_to_Drop_and_Recreate
	(	id int not null identity (1,1) primary key
	,	fk_name sysname null
	,	drop_tsql	nvarchar(max) null
	,	create_tsql nvarchar(max) null
	)

	BEGIN TRY 
	DROP TABLE ##DupPK_Floats_to_Drop_and_Recreate;
	END TRY
	BEGIN CATCH
	END CATCH 
	
	CREATE TABLE ##DupPK_Floats_to_Drop_and_Recreate
	(	id int not null identity (1,1) primary key
	,	Referenced_object_id int not null
	,	referenced_object_name nvarchar(max) not null
	,	pkcol nvarchar(max) not null
	)

	BEGIN TRY 
	DROP TABLE ##DupPK_Table_Floats_to_Drop_and_Recreate;
	END TRY
	BEGIN CATCH
	END CATCH 

	CREATE TABLE ##DupPK_Table_Floats_to_Drop_and_Recreate
	(	id int not null identity (1,1) primary key
	,	Referenced_object_id int not null
	,	referenced_object_name nvarchar(max) not null
	,	pkcol nvarchar(max) not null
	,	fkcol nvarchar(max) not null
	,	referencing_object_name nvarchar(max) not null
	,	Referencing_object_id int not null
	)



	--Load up working tables.
	insert into ##DefaultConstraints_to_Drop_and_Recreate (object_id)
	select tr.object_id from sys.Default_Constraints tr 
	inner join ##Drop_and_Recreate_Objects dro
	on tr.parent_object_id = dro.table_object_id

	insert into ##Triggers_to_Drop_and_Recreate (object_id)
	select tr.object_id from sys.triggers tr 
	inner join ##Drop_and_Recreate_Objects dro
	on tr.parent_id = dro.table_object_id
	
	insert into ##CheckConstraints_to_Drop_and_Recreate (object_id)
	select tr.object_id from sys.check_constraints tr 
	inner join ##Drop_and_Recreate_Objects dro
	on tr.parent_object_id = dro.table_object_id;
		
	INSERT INTO ##DupPK_Floats_to_Drop_and_Recreate ( Referenced_object_id, referenced_object_name,  pkcol) 
	select DISTINCT
		Referenced_object_id	= referenced_o.object_id
	,	referenced_object_name	= '[' + referenced_s.name + '].[' + referenced_o.name + ']'
	,	pkcol					= referenced_c.name
	--,	fkcol					= child_c.name
	--,	referencing_object_name = '[' + child_s.name + '].[' + child_o.name + ']'
	--,	Referencing_object_id	= child_o.object_id
	--select *
	FROM sys.objects referenced_o
	inner join ##Drop_and_Recreate_Objects dro on dro.table_object_id = referenced_o.object_id
	inner join sys.schemas referenced_s on referenced_o.schema_id = referenced_s.schema_id
	inner join sys.columns referenced_c on referenced_c.object_id = referenced_o.object_id
	inner join sys.indexes i on i.object_id = referenced_o.object_id and i.is_primary_key = 1
	inner join sys.index_columns ic on i.index_id = ic.index_id and ic.object_id = referenced_o.object_id and referenced_c.column_id = ic.column_id
	inner join sys.types t on t.user_type_id = referenced_c.user_type_id
	WHERE referenced_o.object_id is not null
	and t.name in ('float', 'real')

	INSERT INTO ##DupPK_Table_Floats_to_Drop_and_Recreate (Referenced_object_id, referenced_object_name, pkcol, fkcol, referencing_object_name, Referencing_object_id)
	select DISTINCT
		Referenced_object_id	= referenced_o.object_id
	,	referenced_object_name	= '[' + referenced_s.name + '].[' + referenced_o.name + ']'
	,	pkcol					= referenced_c.name
	,	fkcol					= child_c.name
	,	referencing_object_name = '[' + child_s.name + '].[' + child_o.name + ']'
	,	Referencing_object_id	= child_o.object_id
	FROM sys.objects referenced_o
	inner join ##Drop_and_Recreate_Objects dro on dro.table_object_id = referenced_o.object_id
	inner join sys.schemas referenced_s on referenced_o.schema_id = referenced_s.schema_id
	inner join sys.columns referenced_c on referenced_c.object_id = referenced_o.object_id
	inner join sys.indexes i on i.object_id = referenced_o.object_id and i.is_primary_key = 1
	inner join sys.index_columns ic on i.index_id = ic.index_id and ic.object_id = referenced_o.object_id and referenced_c.column_id = ic.column_id
	inner join sys.foreign_keys fk on fk.referenced_object_id = referenced_o.object_id
	inner join sys.foreign_key_columns referenced_fkc on  referenced_fkc.constraint_object_id = fk.object_id and referenced_fkc.referenced_column_id = referenced_c.column_id
	inner join sys.foreign_key_columns child_fkc on  child_fkc.constraint_object_id = fk.object_id
	inner join sys.columns child_c on child_c.column_id = child_fkc.parent_column_id
	inner join sys.objects child_o on child_o.object_id = child_fkc.parent_object_id and child_c.object_id = child_o.object_id
	inner join sys.schemas child_s on child_s.schema_id = child_o.schema_id
	inner join sys.types t on t.user_type_id = referenced_c.user_type_id
	WHERE referenced_c.object_id is not null
	and t.name in ('float', 'real');

	/* BEGIN FOREIGN KEYS */
		
	WITH cteColumnNames_Base (FKName, ReferencingColumnNames, FKingRank,  ReferencedColumnNames, FKedRank)
	 as	(	SELECT  FKName					=	f.name 
			,		ReferencingColumnNames	=	CAST(c.name	as varchar(8000))
			,		FKingRank				=	ROW_NUMBER() OVER (PARTITION BY f.Name ORDER BY rc.column_id )
			,		ReferencedColumnNames	=	CAST(rc.name	as varchar(8000))
			,		FKedRank				=	ROW_NUMBER() OVER (PARTITION BY f.Name ORDER BY rc.column_id)
			FROM		sys.foreign_keys f 
			inner join	sys.objects o on f.parent_object_Id = o.object_id 
			inner join	sys.schemas s on o.schema_id = s.schema_id
			inner join	sys.objects ro on f.referenced_object_Id = ro.object_id 
			inner join	sys.schemas rs on ro.schema_id = rs.schema_id
			inner join  ##Drop_and_Recreate_Objects dro on	dro.table_object_id = o.object_id 
			inner join	sys.foreign_key_columns fc on fc.constraint_object_id = f.object_id and fc.parent_object_id = o.object_id and fc.referenced_object_id = ro.object_id
			inner join	sys.columns c on c.object_id = o.object_id and c.column_id = fc.parent_column_id
			inner join	sys.columns rc on ro.object_id = rc.object_id and rc.column_id = fc.referenced_column_id	)
	,	cteColumnNames_Concat (FKName, ReferencingColumnNames, ReferencedColumnNames, FKingRank, FKedRank )
	as	(	SELECT FKName
				,	ReferencingColumnNames
				,	ReferencedColumnNames
				,	FKingRank 
				,	FKedRank
			FROM cteColumnNames_Base
			where FKingRank = 1
			or FKedRank = 1
			UNION ALL
			SELECT  b.FKName
				,	c.ReferencingColumnNames + '], [' + b.ReferencingColumnNames
				,	c.ReferencedColumnNames + '], [' + b.ReferencedColumnNames
				,	b.FKingRank
				,	b.FKedRank
			FROM cteColumnNames_Base b
			INNER JOIN cteColumnNames_Concat c
			on b.FKName = c.FKName
			and (	b.FKingRank = c.FKingRank + 1
			or		b.FKedRank = c.FKedRank + 1)	
			and (b.FKingRank <> 1	and b.FKedRank <> 1)
		)
	,	cteReferencingColumnNames (FKName, ReferencingColumnNames, TopRank)
	as	(SELECT FKName
			,	ReferencingColumnNames
			,	TopRank					=	RANK() OVER (PARTITION BY FKName ORDER BY FKingRank Desc)
		FROM  cteColumnNames_Concat c	)
	,	cteReferencedColumnNames (FKName, ReferencedColumnNames, TopRank)
	as	(SELECT FKName
			,	ReferencedColumnNames
			,	TopRank					=	RANK() OVER (PARTITION BY FKName ORDER BY FKedRank Desc)
		FROM  cteColumnNames_Concat c	)	
	,	cteFK (pktable, fktable) 
	as (   select             
				pktable = s1.name + '.' + o1.name 
		   ,    fktable = isnull(s2.name + '.' + o2.name, '')        
		   from sys.objects o1       
		   inner join  ##Drop_and_Recreate_Objects dro on	dro.table_object_id = o1.object_id 
		   left outer join sys.sysforeignkeys fk on o1.object_id = fk.fkeyid        
		   left outer join sys.objects o2 on o2.object_id = fk.rkeyid        
		   left outer join sys.schemas s1 on o1.schema_id = s1.schema_id
		   left outer join sys.schemas s2 on o2.schema_id = s2.schema_id
		   where o1.type_desc = 'user_table'       
		   and o1.name not in ('dtproperties','sysdiagrams')        
		   and o1.is_ms_shipped = 0
		   group by s1.name + '.' + o1.name 
	   			,	isnull(s2.name + '.' + o2.name, '') 	     )
	, cteRec (tablename, fkcount) 
	as (   select tablename = pktable 
		   ,    fkcount = 0
		   from cteFK    
	      
		   UNION ALL       
       
		   select tablename = pktable 
		   ,	fkcount = 1
		   from cteFK  
		   cross apply cteRec        
		   where cteFK.fktable = cteRec.tablename    
	) 


	Insert into ##ForeignKeys_to_Drop_and_Recreate (fk_name, drop_tsql, create_tsql)
	select --distinct
		FKName = f.name 
	--,	ReferencingTableName = s.name + '.' + o.name
	--,	ReferencingColumnName = '[' + con.ReferencingColumnNames + ']' 
	--,	ReferencedTableName	=	rs.name + '.' + ro.name
	--,	ReferencedColumnName = '[' + rcon.ReferencedColumnNames + ']' 
	,	[Drop_TSQL]		=	'IF EXISTS (select * from sys.foreign_keys where name = ''' + f.name + ''')' + CHAR(10) + CHAR(13) 
							+ 'ALTER TABLE	[' + s.name + '].[' + o.name + ']  DROP CONSTRAINT [' + f.name + '] '
	,	[Create_TSQL]	=	'IF NOT EXISTS (select * from sys.foreign_keys where name = ''' + f.name + ''')' + CHAR(10) + CHAR(13) 
							+ 'ALTER TABLE	[' + s.name + '].[' + o.name + ']  WITH CHECK ADD  CONSTRAINT [' + f.name + '] FOREIGN KEY([' + con.ReferencingColumnNames + ']) ' + CHAR(10)+ CHAR(13)
							+ 'REFERENCES [' + rs.name + '].[' + ro.name + '] (['+rcon.ReferencedColumnNames+']) '
							+ ' ON UPDATE  ' + CASE update_referential_action	WHEN 0 THEN 'No action'
																				WHEN 1 THEN 'Cascade'
																				WHEN 2 THEN 'Set null'
																				WHEN 3 THEN 'Set default' END 
							+ ' ON DELETE ' + CASE delete_referential_action		WHEN 0 THEN 'No action'
																				WHEN 1 THEN 'Cascade'
																				WHEN 2 THEN 'Set null'
																				WHEN 3 THEN 'Set default' END 
	--,	Order				=	dense_rank() OVER ( ORDER BY max(x.fkcount) desc )
	FROM		sys.foreign_keys f 
	inner join	sys.objects o on f.parent_object_Id = o.object_id 
	inner join	sys.schemas s on o.schema_id = s.schema_id
	inner join	sys.objects ro on f.referenced_object_Id = ro.object_id 
	inner join	sys.schemas rs on ro.schema_id = rs.schema_id
	inner join  ##Drop_and_Recreate_Objects dro on	dro.table_object_id = o.object_id 
	inner join	sys.foreign_key_columns fc on fc.constraint_object_id = f.object_id and fc.parent_object_id = o.object_id and fc.referenced_object_id = ro.object_id
	inner join	sys.columns c on c.object_id = o.object_id and c.column_id = fc.parent_column_id
	inner join	sys.columns rc on ro.object_id = rc.object_id and rc.column_id = fc.referenced_column_id
	inner join	cteReferencingColumnNames con on con.FKName = f.Name and con.TopRank = 1
	inner join	cteReferencedColumnNames rcon on rcon.FKName = f.Name and rcon.TopRank = 1
	inner join (   select tablename = fktable
			   ,      fkcount = 0 
			   from cteFK 
			   group by fktable    
			   UNION ALL    
			   select 
					tablename = tablename
			   ,	fkcount = sum(ISNULL(fkcount,0))   
			   from cteRec      
			   group by tablename
			 ) x 
			 on x.tablename = rs.name + '.' + ro.name

	group by f.name, s.name, o.name, rs.name, ro.name, con.ReferencingColumnNames, rcon.ReferencedColumnNames, update_referential_action, delete_referential_action, x.tablename
	order by dense_rank() OVER ( ORDER BY max(x.fkcount) desc ) asc, f.name--, ReferencingTableName, ReferencedTableName


	DECLARE @tsql nvarchar(max)
	DECLARE dropFKs CURSOR FAST_FORWARD FOR select drop_tsql from  ##ForeignKeys_to_Drop_and_Recreate where drop_tsql is not null order by id asc
	OPEN dropFKs 
	FETCH NEXT FROM dropFKs  INTO @tsql
	WHILE @@FETCH_STATUS = 0
	BEGIN

		BEGIN TRY
			print @tsql;
			IF @TestingMode = 0 exec sp_executesql @tsql;
			FETCH NEXT FROM dropFKs  INTO @tsql
		END TRY
		BEGIN CATCH
			THROW;
			SET NOEXEC ON;
		END CATCH
	END
	CLOSE dropFKs;
	DEALLOCATE dropFKs;

	/* Now that FK's are down, we can update floats that will create PK's when they get updated to decimal. */


	


	/* END FOREIGN KEYS */

	
	/* DEFAULT CONSTRAINTS */
	/* These next two commands should be run after all needed DefaultConstraints have been inserted into ##DefaultConstraints_to_Drop_and_Recreate and are ready to be dropped. */
	UPDATE otrtemp set
	--select *,
		object_name = object_name (otrtemp.object_id)
	,	new_object_name = CASE WHEN tr.is_system_named = 1 or tr.name like '%__%__%' 
							THEN 'DF_'+replace(ot.name,' ','_')+'_'+replace(c.name,' ','_') 
							ELSE object_name (otrtemp.object_id) 
							END
	,	drop_tsql = 'IF EXISTS (select top 1 * from sys.default_constraints dc where name = '''+tr.name+''') ' + CHAR(13) 
	+ CHAR(9) +	'ALTER TABLE ['+s.name + '].[' + ot.name + '] DROP CONSTRAINT [' + tr.name + '];' 
	,	create_tsql = 'IF (OBJECT_ID(N''[' + tr.name + ']'') IS NULL AND OBJECT_ID(N''['+CASE WHEN tr.is_system_named = 1 or tr.name like '%__%__%' 
							THEN 'DF_'+replace(ot.name,' ','_')+'_'+replace(c.name,' ','_') 
							ELSE object_name (otrtemp.object_id) 
							END+']'') IS NULL)' + CHAR(13) + CHAR(9) +	
		 'ALTER TABLE ['+s.name + '].[' + ot.name + '] ADD CONSTRAINT ['+
					CASE WHEN tr.is_system_named = 1 or tr.name like '%__%__%' 
							THEN 'DF_'+replace(ot.name,' ','_')+'_'+replace(c.name,' ','_') 
							ELSE object_name (otrtemp.object_id) 
							END
						+'] DEFAULT (' + tr.definition + ') FOR ['+c.name+'];' + CHAR(13) 
	from ##DefaultConstraints_to_Drop_and_Recreate otrtemp
	inner join sys.Default_Constraints tr
	on otrtemp.object_id = tr.object_id
	inner join sys.objects ot
	on ot.object_id = tr.parent_object_id
	inner join sys.schemas s 
	on s.schema_id = ot.schema_id 
	inner join sys.columns c 
	on c.object_id = ot.object_id
	and tr.parent_column_id = c.column_id

	--This query for testing only. Compare to the same query run at the end to verify DefaultConstraints were created/recreated correctly.
	IF @AuditingMode = 1 
	select '##DefaultConstraints_to_Drop_and_Recreate ', * from ##DefaultConstraints_to_Drop_and_Recreate otrtemp
	inner join sys.Default_Constraints tr
	on otrtemp.object_name = object_name(tr.object_id)
	inner join sys.objects ot
	on ot.object_id = tr.parent_object_id
	inner join sys.schemas s 
	on s.schema_id = ot.schema_id 
	inner join sys.columns c 
	on c.object_id = ot.object_id
	and tr.parent_column_id = c.column_id
	order by ot.object_id, c.name

	/* Here is where we actually drop the DefaultConstraints. Only the DefaultConstraints inserted into ##DefaultConstraints_to_Drop_and_Recreate will be dropped.*/
	--DROP DefaultConstraints STEP
	--DECLARE @tsql nvarchar(max)
	DECLARE dropDefaultConstraints CURSOR FAST_FORWARD FOR select drop_tsql from  ##DefaultConstraints_to_Drop_and_Recreate where drop_tsql is not null order by id asc
	OPEN dropDefaultConstraints 
	FETCH NEXT FROM dropDefaultConstraints  INTO @tsql
	WHILE @@FETCH_STATUS = 0
	BEGIN

		BEGIN TRY
			print @tsql;
			IF @TestingMode = 0 exec sp_executesql @tsql;
			FETCH NEXT FROM dropDefaultConstraints  INTO @tsql
		END TRY
		BEGIN CATCH
			THROW;
			SET NOEXEC ON;
		END CATCH
	END
	CLOSE dropDefaultConstraints;
	DEALLOCATE dropDefaultConstraints;

	/* CHECK CONSTRAINTS */

	/* These next two commands should be run after all needed CheckConstraints have been inserted into ##CheckConstraints_to_Drop_and_Recreate and are ready to be dropped. */
	UPDATE otrtemp set
	--select *,
		object_name = object_name (otrtemp.object_id)
	,	new_object_name = CASE WHEN tr.is_system_named = 1 or tr.name like '%__%__%' 
							THEN 'CK_'+replace(ot.name,' ','_')+'_'+replace(c.name,' ','_') 
							ELSE object_name (otrtemp.object_id) 
							END
	,	drop_tsql = 'IF EXISTS (select top 1 * from sys.Check_constraints dc where name = '''+tr.name+''') ' + CHAR(10)+CHAR(13)
	+ CHAR(9) +	'ALTER TABLE ['+s.name + '].[' + ot.name + '] DROP CONSTRAINT [' + tr.name + '];' 
	,	create_tsql = 'IF (OBJECT_ID(N''[' + tr.name + ']'') IS NULL AND OBJECT_ID(N''[CK_'+replace(ot.name,' ','_')+'_'+replace(c.name,' ','_') + ']'') IS NULL)' + CHAR(10)+CHAR(13) + CHAR(9) +	
		 'ALTER TABLE ['+s.name + '].[' + ot.name + '] ADD CONSTRAINT ['+ CASE WHEN tr.is_system_named = 1 or tr.name like '%__%__%' 
						THEN 'CK_'+replace(ot.name,' ','_')+'_'+replace(c.name,' ','_') 
						ELSE object_name (otrtemp.object_id) 
						END +'] Check (' + tr.definition + ')'
	from ##CheckConstraints_to_Drop_and_Recreate otrtemp
	inner join sys.Check_Constraints tr
	on otrtemp.object_id = tr.object_id
	inner join sys.objects ot
	on ot.object_id = tr.parent_object_id
	inner join sys.schemas s 
	on s.schema_id = ot.schema_id 
	inner join sys.columns c 
	on c.object_id = ot.object_id
	and tr.parent_column_id = c.column_id

	--This query for testing only. Compare to the same query run at the end to verify CheckConstraints were created/recreated correctly.
	IF @AuditingMode = 1 
	select CheckConstraints_to_Drop_and_Recreate = '##CheckConstraints_to_Drop_and_Recreate', * from ##CheckConstraints_to_Drop_and_Recreate otrtemp
	inner join sys.Check_Constraints tr
	on otrtemp.object_name = object_name(tr.object_id)
	inner join sys.objects ot
	on ot.object_id = tr.parent_object_id
	inner join sys.schemas s 
	on s.schema_id = ot.schema_id 
	inner join sys.columns c 
	on c.object_id = ot.object_id
	and tr.parent_column_id = c.column_id
	order by ot.object_id, c.name

	/* Here is where we actually drop the CheckConstraints. Only the CheckConstraints inserted into ##CheckConstraints_to_Drop_and_Recreate will be dropped.*/
	--DROP CheckConstraints STEP
	--DECLARE @tsql nvarchar(max)
	DECLARE dropCheckConstraints CURSOR FAST_FORWARD FOR select drop_tsql from  ##CheckConstraints_to_Drop_and_Recreate where drop_tsql is not null order by id asc
	OPEN dropCheckConstraints 
	FETCH NEXT FROM dropCheckConstraints  INTO @tsql
	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY 
			print @tsql;
			IF @TestingMode = 0 exec sp_executesql @tsql;
			FETCH NEXT FROM dropCheckConstraints  INTO @tsql
		END TRY
		BEGIN CATCH
			THROW;
			SET NOEXEC ON;
		END CATCH

	END
	CLOSE dropCheckConstraints;
	DEALLOCATE dropCheckConstraints;

	/* BEGIN DROP TRIGGERS */

	/* These next two commands should be run after all needed triggers have been inserted into ##Triggers_to_Drop_and_Recreate and are ready to be dropped. */
	UPDATE otrtemp
	set
		object_name = object_name (otrtemp.object_id)
	,	drop_tsql = N'IF OBJECT_ID(N''[' + str.name + '].[' + otr.name +']'') IS NOT NULL '  + CHAR(10) + CHAR(13) + ' DROP TRIGGER [' + str.name + '].[' + otr.name +']'
	,	create_tsql = LTRIM(m.definition)
	from ##Triggers_to_Drop_and_Recreate otrtemp
	inner join sys.sql_modules m
	on otrtemp.object_id = m.object_id
	inner join sys.objects otr
	on m.object_id = otr.object_id
	inner join sys.schemas str
	on str.schema_id = otr.schema_id 
	inner join sys.objects ot
	on ot.object_id = otr.parent_object_id
	inner join sys.schemas s 
	on s.schema_id = ot.schema_id 
	inner join sys.triggers tr
	on otr.object_id = tr.object_id
	where otr.type_desc = 'SQL_TRIGGER'
	and tr.is_disabled = 0

	INSERT INTO ##Triggers_to_Drop_and_Recreate  (object_id, create_tsql)
	select 
		m.object_id
	,	create_tsql = LTRIM(case	when te.is_first =1 THEN N'exec sp_settriggerorder @Triggername = N'''+str.name+'.'+otr.name+N''', @order = ''first'', @stmttype = '''+te.type_desc+N''';' COLLATE SQL_Latin1_General_CP1_CI_AS
							when te.is_last = 1 THEN N'exec sp_settriggerorder @Triggername = N'''+str.name+'.'+otr.name+N''', @order = ''last'', @stmttype = '''+te.type_desc+N''';' COLLATE SQL_Latin1_General_CP1_CI_AS
							else null
						end)
	from sys.sql_modules m
	inner join sys.objects otr
	on m.object_id = otr.object_id
	inner join sys.schemas str
	on str.schema_id = otr.schema_id 
	inner join sys.objects ot
	on ot.object_id = otr.parent_object_id
	inner join sys.schemas s 
	on s.schema_id = ot.schema_id 
	inner join sys.trigger_events te
	on te.object_id = otr.object_id
	inner join sys.triggers tr
	on otr.object_id = tr.object_id
	where otr.type_desc = 'SQL_TRIGGER'
	and (is_first  =1 or is_last = 1)
	and tr.is_disabled = 0
		
	--This query for testing only. Compare to the same query run at the end to verify triggers were created/recreated correctly.
	IF @AuditingMode = 1
	select Triggers_to_Drop_and_Recreate = '##Triggers_to_Drop_and_Recreate', * from 
	##Triggers_to_Drop_and_Recreate tdr
	inner join sys.sql_modules m
	on tdr.object_name = object_name(m.object_id)
	inner join sys.objects otr
	on m.object_id = otr.object_id
	inner join sys.schemas str
	on str.schema_id = otr.schema_id 
	inner join sys.objects ot
	on ot.object_id = otr.parent_object_id
	inner join sys.schemas s 
	on s.schema_id = ot.schema_id 
	inner join sys.trigger_events te
	on te.object_id = otr.object_id
	inner join sys.triggers tr
	on otr.object_id = tr.object_id
	where otr.type_desc = 'SQL_TRIGGER'
	and tr.is_disabled = 0
	order by tdr.object_id, m.definition

	/* Here is where we actually drop the triggers. Only the triggers inserted into ##Triggers_to_Drop_and_Recreate will be dropped.*/
	--DROP TRIGGERS STEP
	--DECLARE @tsql nvarchar(max)
	DECLARE droptriggers CURSOR FAST_FORWARD FOR select drop_tsql from  ##Triggers_to_Drop_and_Recreate where drop_tsql is not null order by id asc
	OPEN droptriggers 
	FETCH NEXT FROM droptriggers  INTO @tsql
	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
			print @tsql;
			IF @TestingMode = 0 exec sp_executesql @tsql;
			FETCH NEXT FROM droptriggers  INTO @tsql
		END TRY
		BEGIN CATCH
			THROW;
			SET NOEXEC ON;
		END CATCH

	END
	CLOSE droptriggers;
	DEALLOCATE droptriggers;

	/* END DROP TRIGGERS */

	/* BEGIN DROP INDEXES */

		DECLARE @counter int, @maxcounter int, @colsholder nvarchar(max), @includesholder nvarchar(max), @SQLHolder nvarchar(max)
		
		
		BEGIN TRY 
		DROP TABLE ##IndexObjects_Working;
		END TRY
		BEGIN CATCH
		END CATCH 

		CREATE TABLE ##IndexObjects_Working (
			ID	int IDENTITY(1,1) PRIMARY KEY
		,	ObjectID int NOT NULL
		,	IndexID int NOT NULL
		,	Index_type nvarchar(150) NOT NULL
		,	Index_name nvarchar(150) NOT NULL
		,	Primary_Key bit NOT NULL
		,	Unique_Constraint bit NOT NULL
		,	Is_Unique bit not null
		,	table_name nvarchar(150) NOT NULL
		,	Cols nvarchar(max) NULL
		,	Includes nvarchar(max) NULL
		,	Set_FillFactor	tinyint NOT NULL
		,	Set_PADINDEX bit NOT NULL
		,	Set_ALLOW_ROW_LOCKS  bit NOT NULL
		,	Set_ALLOW_PAGE_LOCKS bit NOT NULL
		,	DATA_COMPRESSION varchar(10) NULL
		)

		INSERT INTO ##IndexObjects_Working (
				ObjectID 
			,	IndexID 
			,	Index_type 
			,	Index_name 
			,	Primary_Key 
			,	Unique_Constraint
			,	Is_Unique
			,	table_name 
			,	Cols 
			,	Includes 
			,	Set_FillFactor
			,	Set_PADINDEX 
			,	Set_ALLOW_ROW_LOCKS  
			,	Set_ALLOW_PAGE_LOCKS 
			,	DATA_COMPRESSION
		)
		SELECT 
			ObjectID	= o.[object_ID]
		,	IndexID		= i.index_id
		,	Index_type	= i.type_desc
		,	Index_name	= i.name
		,	Primary_Key = i.is_primary_key
		,	Unique_Constraint = i.is_unique_constraint
		,	Is_Unique	= i.is_unique
		,	table_name	= N'[' + s.name + N'].[' + o.name + ']'
		,	Cols		= NULL
		,	Includes	= NULL
		,	Set_FillFactor	= i.fill_factor
		,	Set_PADINDEX = i.is_padded
		,	Set_ALLOW_ROW_LOCKS  = i.allow_row_locks
		,	Set_ALLOW_PAGE_LOCKS = i.allow_page_locks
		,	DATA_COMPRESSION = ISNULL(p.data_compression_desc, 'NONE')
		FROM 		sys.objects o
		inner join	sys.indexes i 
						on o.[object_id] = i.[object_id]
		inner join	sys.schemas s
						on s.schema_id = o.schema_id
		inner join	sys.partitions p
						on p.index_id = i.index_id
						and p.object_id = o.object_id
		inner join ##Drop_and_Recreate_Objects dro
						on dro.table_object_id = o.object_id 
		where	1=1
		and	o.type = 'u'
		and i.index_id >= 1
		ORDER BY is_Primary_key desc
		
		SELECT @counter = 1, @colsholder = null, @includesholder = null, @maxcounter = max(T.id) FROM ##IndexObjects_Working T

		WHILE @counter <= @maxcounter 
		BEGIN
	
			SELECT @colsholder = CASE WHEN @colsholder IS NULL THEN '' ELSE @colsholder + N', ' END + N'[' + c.name + N'] ' + CASE WHEN ic.is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END
			FROM ##IndexObjects_Working T
			inner join	sys.index_columns ic
						on ic.[object_id] = T.objectid
						and ic.index_id = T.indexid
			inner join	sys.columns c
						on c.[object_id] = T.objectid
						and c.column_id = ic.column_id
			WHERE T.id = @counter
			and		is_included_column = 0 -- key field
			ORDER BY Index_column_id

			UPDATE ##IndexObjects_Working
			SET Cols = @colsholder
			WHERE ID = @counter

			SELECT @includesholder = CASE WHEN @includesholder IS NULL THEN '' ELSE @includesholder + N', ' END + N'[' + c.name + N'] ' 
			FROM ##IndexObjects_Working T
			inner join	sys.index_columns ic
						on ic.[object_id] = T.objectid
						and ic.index_id = T.indexid
			inner join	sys.columns c
						on c.[object_id] = T.objectid
						and c.column_id = ic.column_id
			WHERE T.id = @counter
			and		is_included_column = 1 -- included field
			ORDER BY Index_column_id

			UPDATE ##IndexObjects_Working
			SET Includes = @includesholder
			WHERE ID = @counter
			SELECT @counter = @counter + 1, @colsholder = null, @includesholder = null

		END
		
			-- Unique Constraint
			INSERT INTO ##IndexConstraints_to_Drop_and_Recreate  (object_name, object_id, Index_id, drop_tsql, create_tsql) 
			SELECT 
				Object_name =	'[' + Index_Name + ']'
			,	Object_Id	=	t.ObjectID 
			,	Index_id	=	t.IndexID
			,	drop_tsql	=	--CASE WHEN EXISTS (SELECT 1 FROM sys.change_tracking_tables where OBJECT_ID = t.ObjectID) THEN 
								'IF EXISTS (SELECT TOP 1 * FROM sys.change_tracking_tables WHERE Object_id = ' + str(t.ObjectID) + ')' + CHAR(10)+CHAR(13)
								+ 'ALTER TABLE ' + table_name + ' DISABLE CHANGE_TRACKING;' --ELSE '' END 
								+ CHAR(10)+CHAR(13)
								+ 'IF EXISTS (SELECT top 1 * from sys.indexes i where i.object_id = '+ cast (ObjectID as varchar(30)) +' and  i.name = '''+Index_Name+''')'+ CHAR(10)+CHAR(13)
								+ ' ALTER TABLE ' + table_name + ' DROP CONSTRAINT [' + Index_Name + ']'
			,	create_tsql	=	'IF NOT EXISTS (SELECT top 1 * from sys.indexes i where i.object_id = N'''+ cast (ObjectID as varchar(30)) +''' and i.name = '''+Index_Name+''')'+ CHAR(10)+CHAR(13)
								+ ' ALTER TABLE ' + table_name + ' ADD  CONSTRAINT [' + Index_Name + ']'
								+ CASE WHEN Primary_Key = 1 THEN ' PRIMARY KEY ' WHEN  Unique_Constraint = 1 THEN ' UNIQUE ' ELSE '' END
								+ Index_Type + ' (' + Cols + ') '
								--Add for extended options
								+ '  WITH (PAD_INDEX = ' + CASE WHEN Set_PADINDEX = 0 THEN ' OFF' ELSE ' ON' END 
								+ ', ALLOW_ROW_LOCKS = ' + CASE WHEN Set_ALLOW_ROW_LOCKS = 0 THEN ' OFF' ELSE ' ON' END 
								+ ', ALLOW_PAGE_LOCKS = ' + CASE WHEN Set_ALLOW_PAGE_LOCKS = 0 THEN ' OFF' ELSE ' ON' END 
								+ CASE WHEN Set_FillFactor = 0 THEN ''  ELSE  ', FILLFACTOR = ' + CONVERT(VARCHAR(10),Set_FillFactor)   END
								+ ', DATA_COMPRESSION = ' + t.data_compression + ')'   + CHAR(10)+CHAR(13)
								-- + CASE WHEN EXISTS (SELECT 1 FROM sys.change_tracking_tables where OBJECT_ID = ObjectID) THEN 
								+ 'IF EXISTS (SELECT TOP 1 * FROM sys.change_tracking_tables WHERE Object_id = ' + str(ObjectID) + ')' + CHAR(10)+CHAR(13) 
									+ ' ALTER TABLE ' + table_name + ' ENABLE CHANGE_TRACKING ' 
									+ CASE WHEN EXISTS (SELECT 1 FROM sys.change_tracking_tables where is_track_columns_updated_on =1 and OBJECT_ID = t.ObjectID) THEN ' WITH (TRACK_COLUMNS_UPDATED = ON)' ELSE ';' END
								--ELSE '' END 
			FROM ##IndexObjects_Working t
			WHERE Primary_Key = 1 OR Unique_Constraint = 1
		
			-- Nonclustered Index
			INSERT INTO ##Indexes_to_Drop_and_Recreate (object_name, object_id, Index_id, drop_tsql, create_tsql) 
			SELECT 
				Object_name =	'[' + Index_Name + ']'
			,	Object_Id	=	ObjectID 
			,	Index_id	=	IndexID
			,	drop_tsql	=	'IF EXISTS (SELECT top 1 * from sys.indexes i where i.object_id = '+ cast (ObjectID as varchar(30)) +' and  i.name = '''+Index_Name+''')'+ CHAR(10)+CHAR(13)
								+ ' DROP INDEX [' + Index_Name + '] ON ' + table_name + ' WITH ( ONLINE = OFF ) '
			,	create_tsql	=	'IF NOT EXISTS (SELECT top 1 * from sys.indexes i where i.object_id = '+ cast (ObjectID as varchar(30)) +' and  i.name = '''+Index_Name+''')'+ CHAR(10)+CHAR(13)+ 
								+ 'CREATE ' + CASE t.Is_Unique WHEN 1 THEN ' UNIQUE ' ELSE '' END
								+ Index_Type + ' INDEX [' + Index_Name + '] ON ' + table_name + ' (' + Cols + ') '
								+ CASE WHEN Includes is null then '' ELSE ' INCLUDE (' + Includes + ') ' END
								+ ' WITH (PAD_INDEX = ' + CASE WHEN Set_PADINDEX = 0 THEN ' OFF ' ELSE ' ON ' END 
								+ ', ALLOW_ROW_LOCKS = ' + CASE WHEN Set_ALLOW_ROW_LOCKS = 0 THEN ' OFF ' ELSE ' ON ' END 
								+ ', ALLOW_PAGE_LOCKS = ' + CASE WHEN Set_ALLOW_PAGE_LOCKS = 0 THEN ' OFF ' ELSE ' ON ' END 
								+ CASE WHEN Set_FillFactor = 0 THEN ''  ELSE  ', FILLFACTOR = ' + CONVERT(VARCHAR(10),Set_FillFactor)   END
								+ ', DATA_COMPRESSION = ' + t.data_compression + ')'
	 		FROM ##IndexObjects_Working t
			WHERE Primary_Key = 0 AND Unique_Constraint = 0
	
		--select * from ##IndexObjects_Working  where index_name like '%UIX__invoice_export_history__invoice_number__export_date%'
		--select * from ##IndexConstraints_to_Drop_and_Recreate where object_name like '%UIX__invoice_export_history__invoice_number__export_date%'

			DECLARE dropIndexes CURSOR FAST_FORWARD FOR select drop_tsql from  ##Indexes_to_Drop_and_Recreate where drop_tsql is not null order by id asc
			OPEN dropIndexes 
			FETCH NEXT FROM dropIndexes  INTO @tsql
			WHILE @@FETCH_STATUS = 0
			BEGIN
				BEGIN TRY
					print @tsql;
					IF @TestingMode = 0 exec sp_executesql @tsql;
					FETCH NEXT FROM dropIndexes  INTO @tsql
				END TRY
				BEGIN CATCH
					THROW;
					SET NOEXEC ON;
				END CATCH
			END
			CLOSE dropIndexes;
			DEALLOCATE dropIndexes;

			DECLARE dropIndexConstraints CURSOR FAST_FORWARD FOR select drop_tsql from  ##IndexConstraints_to_Drop_and_Recreate where drop_tsql is not null order by id asc
			OPEN dropIndexConstraints 
			FETCH NEXT FROM dropIndexConstraints  INTO @tsql
			WHILE @@FETCH_STATUS = 0
			BEGIN
				BEGIN TRY
					print @tsql;
					IF @TestingMode = 0 exec sp_executesql @tsql;
					FETCH NEXT FROM dropIndexConstraints  INTO @tsql
				END TRY
				BEGIN CATCH
					THROW;
					SET NOEXEC ON;
				END CATCH
			END
			CLOSE dropIndexConstraints;
			DEALLOCATE dropIndexConstraints;
			
	/* END DROP INDEXES */


END

GO	

if OBJECT_ID('dbo.Recreate_Stored_Table_Objects') is not null
drop procedure dbo.Recreate_Stored_Table_Objects
go

CREATE PROCEDURE dbo.Recreate_Stored_Table_Objects (@TestingMode bit = 0, @AuditingMode bit = 0)
WITH RECOMPILE
AS
BEGIN

	SET XACT_ABORT ON

	IF NOT EXISTS(select 1 from tempdb.sys.objects where name like '##Drop_and_Recreate_Objects%')
	BEGIN
		THROW 51000, '##Drop_and_Recreate_Objects does not exist.', 1;
		SET NOEXEC ON
	END

	/* IndexConstraints */

				--This query for testing only. 
			IF @AuditingMode = 1
			select IndexConstraints_to_Drop_and_Recreate=  '##IndexConstraints_to_Drop_and_Recreate', * from 
			##IndexConstraints_to_Drop_and_Recreate tdr
			order by tdr.object_id, tdr.index_id

	BEGIN TRY
	BEGIN TRAN CREATEIndexConstraints
			--RECREATE TRIGGERS STEP
			DECLARE @tsql nvarchar(max)
			DECLARE createtriggers CURSOR FAST_FORWARD FOR select create_tsql from  ##IndexConstraints_to_Drop_and_Recreate where create_tsql is not null order by id asc
			OPEN createtriggers 
			FETCH NEXT FROM createtriggers  INTO @tsql
			WHILE @@FETCH_STATUS = 0
			BEGIN
				BEGIN TRY 
					print @tsql;
					IF @TestingMode = 0 exec sp_executesql @tsql;
					FETCH NEXT FROM createtriggers  INTO @tsql
				END TRY
				BEGIN CATCH
					THROW;
					SET NOEXEC ON;
				END CATCH

			END
			CLOSE createtriggers;
			DEALLOCATE createtriggers;

			--This query for testing only. 
			IF @AuditingMode = 1
			select IndexConstraints_to_Drop_and_Recreate = '##IndexConstraints_to_Drop_and_Recreate', * from 
			##IndexConstraints_to_Drop_and_Recreate tdr
			inner join sys.objects otr
			on tdr.object_id = otr.object_id
			inner join sys.schemas str
			on str.schema_id = otr.schema_id 
			inner join sys.indexes i
			on i.index_id = tdr.index_id
			and i.object_id = tdr.object_id 
			order by tdr.object_id, tdr.index_id

			IF	(	ISNULL((SELECT COUNT(distinct object_id) from ##IndexConstraints_to_Drop_and_Recreate),0)
				=	ISNULL((SELECT COUNT(distinct otr.object_id) from ##IndexConstraints_to_Drop_and_Recreate t inner join sys.objects otr on t.object_id = otr.object_id),0)
				)
				BEGIN;
					COMMIT TRAN CREATEIndexConstraints;
					PRINT 'Index Constraints count validation successful.'
					DROP TABLE ##IndexConstraints_to_Drop_and_Recreate
					DROP TABLE ##IndexObjects_Working

				END;
			ELSE
				BEGIN;
					THROW 51000, 'The number of IndexConstraints that should exist does not match the number of IndexConstraints that exist! Problems re-creating IndexConstraints. Examine print statements generated by cursors for errors. The temp table containing the IndexConstraints has not been dropped, but no IndexConstraints currently exist in the database. Remediation is necessary!', 1;
				END;
			END TRY
			BEGIN CATCH
				IF @@TRANCOUNT > 0
				ROLLBACK TRAN CREATEIndexConstraints;
				THROW;

			END CATCH




	/* DEFAULT CONSTRAINTS */

	BEGIN TRY
	IF @TestingMode = 0 BEGIN TRAN CREATEDefaultConstraints

			--RECREATE DefaultConstraints STEP
			--DECLARE @tsql nvarchar(max)
			DECLARE createDefaultConstraints CURSOR FAST_FORWARD FOR select create_tsql from ##DefaultConstraints_to_Drop_and_Recreate where create_tsql is not null order by id asc
			OPEN createDefaultConstraints 
			FETCH NEXT FROM createDefaultConstraints  INTO @tsql
			WHILE @@FETCH_STATUS = 0
			BEGIN
				BEGIN TRY
					print @tsql;
					IF @TestingMode = 0 exec sp_executesql @tsql;
					FETCH NEXT FROM createDefaultConstraints  INTO @tsql
				END TRY
				BEGIN CATCH
					THROW;
					SET NOEXEC ON;
				END CATCH

			END
			CLOSE createDefaultConstraints;
			DEALLOCATE createDefaultConstraints;

			--This query for testing only. Compare to the same query run at the beginning to verify DefaultConstraints were created/recreated correctly.
			IF @AuditingMode = 1 
			select DefaultConstraints_to_Drop_and_Recreate =  '##DefaultConstraints_to_Drop_and_Recreate', * from ##DefaultConstraints_to_Drop_and_Recreate otrtemp
			inner join sys.Default_Constraints tr
			on otrtemp.new_object_name = object_name(tr.object_id)
			inner join sys.objects ot
			on ot.object_id = tr.parent_object_id
			inner join sys.schemas s 
			on s.schema_id = ot.schema_id 
			inner join sys.columns c 
			on c.object_id = ot.object_id
			and tr.parent_column_id = c.column_id
			order by ot.object_id, c.name;

			IF	(	ISNULL((SELECT COUNT(distinct object_id) from ##DefaultConstraints_to_Drop_and_Recreate),0)
				=	ISNULL((SELECT COUNT(distinct dc.object_id) from ##DefaultConstraints_to_Drop_and_Recreate t inner join sys.Default_Constraints dc on t.new_object_name = object_name(dc.object_id)),0)
				)	
				BEGIN;
					IF @TestingMode = 0 COMMIT TRAN CREATEDefaultConstraints;
					IF @TestingMode = 0 PRINT 'Default Constraint count validation successful.'

					DROP TABLE ##DefaultConstraints_to_Drop_and_Recreate;
				END;
			ELSE
				BEGIN;
					IF @TestingMode = 0 THROW 51000, 'The number of DefaultConstraints that should exist does not match the number of DefaultConstraints that exist! Problems re-creating DefaultConstraints. Examine print statements generated by cursors for errors. The temp table containing the defaultconstraints has not been dropped, but no defaultconstraints currently exist in the database. Remediation is necessary!', 1;
				END;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 IF @TestingMode = 0 ROLLBACK TRAN CREATEDefaultConstraints;
		THROW;

	END CATCH

	
	
	/* CHECK CONSTRAINTS */

	BEGIN TRY
	IF @TestingMode = 0 BEGIN TRAN CREATECheckConstraints

			--RECREATE CheckConstraints STEP
			--DECLARE @tsql nvarchar(max)
			DECLARE createCheckConstraints CURSOR FAST_FORWARD FOR select create_tsql from  ##CheckConstraints_to_Drop_and_Recreate where create_tsql is not null order by id asc
			OPEN createCheckConstraints 
			FETCH NEXT FROM createCheckConstraints  INTO @tsql
			WHILE @@FETCH_STATUS = 0
			BEGIN
				BEGIN TRY
					print @tsql;
					IF @TestingMode = 0 exec sp_executesql @tsql;
					FETCH NEXT FROM createCheckConstraints  INTO @tsql
				END TRY
				BEGIN CATCH
					THROW;
					SET NOEXEC ON;
				END CATCH

			END
			CLOSE createCheckConstraints;
			DEALLOCATE createCheckConstraints;

			--This query for testing only. Compare to the same query run at the beginning to verify CheckConstraints were created/recreated correctly.
			IF @AuditingMode = 1 
			select CheckConstraints_to_Drop_and_Recreate = '##CheckConstraints_to_Drop_and_Recreate', * from ##CheckConstraints_to_Drop_and_Recreate otrtemp
			inner join sys.Check_Constraints tr
			on otrtemp.new_object_name = object_name(tr.object_id)
			inner join sys.objects ot
			on ot.object_id = tr.parent_object_id
			inner join sys.schemas s 
			on s.schema_id = ot.schema_id 
			inner join sys.columns c 
			on c.object_id = ot.object_id
			and tr.parent_column_id = c.column_id
			order by ot.object_id, c.name;

			IF	(	ISNULL((SELECT COUNT(distinct object_id) from ##CheckConstraints_to_Drop_and_Recreate),0)
				=	ISNULL((SELECT COUNT(distinct dc.object_id) from ##CheckConstraints_to_Drop_and_Recreate t inner join sys.Check_Constraints dc on t.new_object_name = object_name(dc.object_id)),0)
				)	
				BEGIN;
					IF @TestingMode = 0 COMMIT TRAN CREATECheckConstraints;
					IF @TestingMode = 0 PRINT 'Check Constraint count validation successful.'

					DROP TABLE ##CheckConstraints_to_Drop_and_Recreate;
				END;
			ELSE
				BEGIN;
					IF @TestingMode = 0 THROW 51000, 'The number of CheckConstraints that should exist does not match the number of CheckConstraints that exist! Problems re-creating CheckConstraints. Examine print statements generated by cursors for errors. The temp table containing the Checkconstraints has not been dropped, but no Checkconstraints currently exist in the database. Remediation is necessary!', 1;
				END;
	END TRY
	BEGIN CATCH

		IF @@TRANCOUNT > 0 IF @TestingMode = 0 ROLLBACK TRAN CREATECheckConstraints;
		THROW;

	END CATCH



	/* TRIGGERS */

	IF @AuditingMode = 1
	select Triggers_to_Drop_and_Recreate = '##Triggers_to_Drop_and_Recreate', * from 
	##Triggers_to_Drop_and_Recreate tdr

	BEGIN TRY
	BEGIN TRAN CREATETRIGGERS
			--RECREATE TRIGGERS STEP
			--DECLARE @tsql nvarchar(max)
			DECLARE createtriggers CURSOR FAST_FORWARD FOR select create_tsql from  ##Triggers_to_Drop_and_Recreate where create_tsql is not null order by id asc
			OPEN createtriggers 
			FETCH NEXT FROM createtriggers  INTO @tsql
			WHILE @@FETCH_STATUS = 0
			BEGIN
				BEGIN TRY 
					print @tsql;
					IF @TestingMode = 0 exec sp_executesql @tsql;
					FETCH NEXT FROM createtriggers  INTO @tsql
				END TRY
				BEGIN CATCH
					THROW;
					SET NOEXEC ON;
				END CATCH

			END
			CLOSE createtriggers;
			DEALLOCATE createtriggers;

			--This query for testing only. Compare to the same query run at the beginning to verify triggers were created/recreated correctly.
			IF @AuditingMode = 1
			select Triggers_to_Drop_and_Recreate = '##Triggers_to_Drop_and_Recreate', * from 
			##Triggers_to_Drop_and_Recreate tdr
			inner join sys.sql_modules m
			on tdr.object_name = object_name(m.object_id)
			inner join sys.objects otr
			on m.object_id = otr.object_id
			inner join sys.schemas str
			on str.schema_id = otr.schema_id 
			inner join sys.objects ot
			on ot.object_id = otr.parent_object_id
			inner join sys.schemas s 
			on s.schema_id = ot.schema_id 
			inner join sys.trigger_events te
			on te.object_id = otr.object_id
			inner join sys.triggers tr
			on otr.object_id = tr.object_id
			where otr.type_desc = 'SQL_TRIGGER'
			and tr.is_disabled = 0
			order by tdr.object_id, m.definition

			IF	(	ISNULL((SELECT COUNT(distinct object_id) from ##Triggers_to_Drop_and_Recreate),0)
				=	ISNULL((SELECT COUNT(distinct otr.object_id) from ##Triggers_to_Drop_and_Recreate t inner join sys.objects otr on t.object_name = object_name(otr.object_id)),0)
				)
				BEGIN;
					COMMIT TRAN CREATETRIGGERS;
					PRINT 'Trigger count validation successful.'

					DROP TABLE ##Triggers_to_Drop_and_Recreate

				END;
			ELSE
				BEGIN;
					THROW 51000, 'The number of Triggers that should exist does not match the number of Triggers that exist! Problems re-creating Triggers. Examine print statements generated by cursors for errors. The temp table containing the Triggers has not been dropped, but no Triggers currently exist in the database. Remediation is necessary!', 1;
				END;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		ROLLBACK TRAN CREATETRIGGERS;
		THROW;

	END CATCH

	/* INDEXES */

				--This query for testing only. 
			IF @AuditingMode = 1
			select Indexes_to_Drop_and_Recreate= '##Indexes_to_Drop_and_Recreate', * from 
			##Indexes_to_Drop_and_Recreate tdr
			order by tdr.object_id, tdr.index_id


	BEGIN TRY
	BEGIN TRAN CREATEINDEXES
			--RECREATE INDEXES STEP
			--DECLARE @tsql nvarchar(max)
			DECLARE CREATEINDEXES CURSOR FAST_FORWARD FOR select create_tsql from  ##Indexes_to_Drop_and_Recreate where create_tsql is not null order by id asc
			OPEN CREATEINDEXES 
			FETCH NEXT FROM CREATEINDEXES  INTO @tsql
			WHILE @@FETCH_STATUS = 0
			BEGIN
				BEGIN TRY 
					print @tsql;
					IF @TestingMode = 0 exec sp_executesql @tsql;
					FETCH NEXT FROM CREATEINDEXES  INTO @tsql

				END TRY
				BEGIN CATCH
					THROW;
					SET NOEXEC ON;
				END CATCH

			END
			CLOSE CREATEINDEXES;
			DEALLOCATE CREATEINDEXES;
			
			--This query for testing only. 
			IF @AuditingMode = 1
			select Indexes_to_Drop_and_Recreate = '##Indexes_to_Drop_and_Recreate', * from 
			##Indexes_to_Drop_and_Recreate tdr
			inner join sys.objects otr
			on tdr.object_id = otr.object_id
			inner join sys.schemas str
			on str.schema_id = otr.schema_id 
			inner join sys.indexes i
			on i.index_id = tdr.index_id
			and i.object_id = tdr.object_id
			where tdr.create_tsql is not null 
			order by tdr.object_id, i.index_id

			IF	(	ISNULL((SELECT COUNT(object_id) from ##Indexes_to_Drop_and_Recreate),0)
				=	ISNULL((SELECT COUNT(otr.object_id) from ##Indexes_to_Drop_and_Recreate t inner join sys.objects otr on t.object_id = otr.object_id),0)
				)
				BEGIN;
					COMMIT TRAN CREATEINDEXES;
					PRINT 'Index count validation successful.'
					DROP TABLE ##Indexes_to_Drop_and_Recreate

				END;
			ELSE
				BEGIN;
					THROW 51000, 'The number of Indexes that should exist does not match the number of Indexes that exist! Problems re-creating Indexes. Examine print statements generated by cursors for errors. The temp table containing the Indexes has not been dropped, but no Indexes currently exist in the database. Remediation is necessary!', 1;
				END;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		ROLLBACK TRAN CREATEINDEXES;
		THROW;

	END CATCH


	
	/* FOREIGN KEYS */

		--This query for testing only. 
	IF @AuditingMode = 1
	select ForeignKeys_to_Drop_and_Recreate = '##ForeignKeys_to_Drop_and_Recreate', * from 
	##ForeignKeys_to_Drop_and_Recreate tdr
	order by tdr.fk_name
		

	BEGIN TRY
	BEGIN TRAN CREATEForeignKeys
			
			--RECREATE ForeignKeys STEP
			--DECLARE @tsql nvarchar(max)
			DECLARE CREATEForeignKeys CURSOR FAST_FORWARD FOR select create_tsql from  ##ForeignKeys_to_Drop_and_Recreate where create_tsql is not null order by id asc
			OPEN CREATEForeignKeys 
			FETCH NEXT FROM CREATEForeignKeys  INTO @tsql
			WHILE @@FETCH_STATUS = 0
			BEGIN
				BEGIN TRY 
					print @tsql;
					IF @TestingMode = 0 exec sp_executesql @tsql;
					FETCH NEXT FROM CREATEForeignKeys  INTO @tsql

				END TRY
				BEGIN CATCH
					THROW;
					SET NOEXEC ON;
				END CATCH

			END
			CLOSE CREATEForeignKeys;
			DEALLOCATE CREATEForeignKeys;
			
			--This query for testing only. 
			IF @AuditingMode = 1
			select ForeignKeys_to_Drop_and_Recreate=  '##ForeignKeys_to_Drop_and_Recreate', * from 
			##ForeignKeys_to_Drop_and_Recreate tdr
			inner join sys.foreign_keys fk
			on fk.name = tdr.fk_name
			where tdr.create_tsql is not null 
			order by tdr.fk_name

			IF	(	ISNULL((SELECT COUNT(fk_name) from ##ForeignKeys_to_Drop_and_Recreate),0)
				=	ISNULL((SELECT COUNT(t.fk_name) from ##ForeignKeys_to_Drop_and_Recreate t inner join sys.foreign_keys fk on fk.name = t.fk_name),0)
				)
				BEGIN;
					COMMIT TRAN CREATEForeignKeys;
					PRINT 'Foreign Key count validation successful.'
					DROP TABLE ##ForeignKeys_to_Drop_and_Recreate

				END;
			ELSE
				BEGIN;
					THROW 51000, 'The number of ForeignKeys that should exist does not match the number of ForeignKeys that exist! Problems re-creating ForeignKeys. Examine print statements generated by cursors for errors. The temp table containing the ForeignKeys has not been dropped, but no ForeignKeys currently exist in the database. Remediation is necessary!', 1;
				END;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		ROLLBACK TRAN CREATEForeignKeys;
		THROW;

	END CATCH

	END
go

