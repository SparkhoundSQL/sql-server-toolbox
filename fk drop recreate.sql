
--Script out FK's with DROP/CREATE scripts 
--See also: toolbox\fk untrusted or disabled check.sql
	WITH cteColumnNames_Base (FKName, ReferencingColumnNames, FKingRank,  ReferencedColumnNames, FKedRank)
	 as	(	SELECT  FKName					=	f.name 
			,		ReferencingColumnNames	=	CAST(c.name	as varchar(8000))
			,		FKingRank				=	ROW_NUMBER() OVER (PARTITION BY f.Name ORDER BY rc.column_id )
			,		ReferencedColumnNames	=	CAST(rc.name	as varchar(8000))
			,		FKedRank				=	ROW_NUMBER() OVER (PARTITION BY f.Name ORDER BY rc.column_id)
			FROM		sys.foreign_keys f 
			INNER JOIN	sys.objects o on f.parent_object_Id = o.object_id 
			INNER JOIN	sys.schemas s on o.schema_id = s.schema_id
			INNER JOIN	sys.objects ro on f.referenced_object_Id = ro.object_id 
			INNER JOIN	sys.schemas rs on ro.schema_id = rs.schema_id
			INNER JOIN	sys.foreign_key_columns fc on fc.constraint_object_id = f.object_id and fc.parent_object_id = o.object_id and fc.referenced_object_id = ro.object_id
			INNER JOIN	sys.columns c on c.object_id = o.object_id and c.column_id = fc.parent_column_id
			INNER JOIN	sys.columns rc on ro.object_id = rc.object_id and rc.column_id = fc.referenced_column_id	)

	,	cteColumnNames_Concat (FKName, ReferencingColumnNames, ReferencedColumnNames, FKingRank, FKedRank )
	as	(	SELECT FKName
				,	ReferencingColumnNames
				,	ReferencedColumnNames
				,	FKingRank 
				,	FKedRank
			FROM cteColumnNames_Base
			WHERE FKingRank = 1
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
			and (b.FKingRank <> 1	and b.FKedRank <> 1) 		)

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

	--Uncomment to write this information to a table, which can be looped through with later code block
	INSERT INTO dbo.fkscripts
	select distinct
		FKName					= f.name 
	,	ReferencingTableName	= s.name + '.' + o.name
	,	ReferencingColumnName	= '[' + con.ReferencingColumnNames + ']' 
	,	ReferencedTableName		=	rs.name + '.' + ro.name
	,	ReferencedColumnName	= '[' + rcon.ReferencedColumnNames + ']' 
	,	[Drop_TSQL]				=	'IF EXISTS (select * from sys.foreign_keys where name = ''' + f.name + ''')' + CHAR(10) + CHAR(13) 
									+ 'ALTER TABLE	[' + s.name + '].[' + o.name + ']  DROP CONSTRAINT [' + f.name + '] ' + CHAR(10) + CHAR(13) 
	,	[Create_TSQL]			=	'IF NOT EXISTS (select * from sys.foreign_keys where name = ''' + f.name + ''')' + CHAR(10) + CHAR(13) 
									+ 'ALTER TABLE	[' + s.name + '].[' + o.name + ']  WITH CHECK ADD CONSTRAINT [' + f.name + '] FOREIGN KEY([' + con.ReferencingColumnNames + ']) ' + CHAR(10)+ CHAR(13)
									+ 'REFERENCES [' + rs.name + '].[' + ro.name + '] (['+rcon.ReferencedColumnNames+']) '
									+ ' ON UPDATE  ' + CASE update_referential_action	WHEN 0 THEN 'No action' WHEN 1 THEN 'Cascade' WHEN 2 THEN 'Set null'	WHEN 3 THEN 'Set default' END 
									+ ' ON DELETE ' + CASE delete_referential_action	WHEN 0 THEN 'No action' WHEN 1 THEN 'Cascade' WHEN 2 THEN 'Set null'	WHEN 3 THEN 'Set default' END 									+ CHAR(10) + CHAR(13) 
	FROM		sys.foreign_keys f 
	INNER JOIN	sys.objects o on f.parent_object_Id = o.object_id 
	INNER JOIN	sys.schemas s on o.schema_id = s.schema_id
	INNER JOIN	sys.objects ro on f.referenced_object_Id = ro.object_id 
	INNER JOIN	sys.schemas rs on ro.schema_id = rs.schema_id
	INNER JOIN	sys.foreign_key_columns fc on fc.constraint_object_id = f.object_id and fc.parent_object_id = o.object_id and fc.referenced_object_id = ro.object_id
	INNER JOIN	sys.columns c on c.object_id = o.object_id and c.column_id = fc.parent_column_id
	INNER JOIN	sys.columns rc on ro.object_id = rc.object_id and rc.column_id = fc.referenced_column_id
	INNER JOIN	cteReferencingColumnNames con on con.FKName = f.Name and con.TopRank = 1
	INNER JOIN	cteReferencedColumnNames rcon on rcon.FKName = f.Name and rcon.TopRank = 1
	ORDER BY	ReferencingTableName, ReferencedTableName;

/*
--Mechanism to drop/recreate all FK's as they were. 
	DROP TABLE IF EXISTS dbo.fkscripts
	CREATE TABLE dbo.fkscripts
	(	id int not null IDENTITY(1,1) constraint pk_fkscripts primary key
	,	FKName					sysname not null
	,	ReferencingTableName	sysname not null
	,	ReferencingColumnName	sysname not null
	,	ReferencedTableName		sysname not null
	,	ReferencedColumnName	sysname not null
	,	[Drop_TSQL]				nvarchar(4000) not null					
	,	[Create_TSQL]			nvarchar(4000) not null
	)						

	declare @id int = 1, @maxid int, @tsql nvarchar(4000) = ''
	select @maxid = max(id) from fkscripts
	print 'Dropping all foreign keys'
	while @id <= @maxid
	begin
	
		BEGIN TRY 
			select @tsql = [Drop_TSQL] from fkscripts where id = @id
			print @tsql
			exec sp_executesql @tsql
		END TRY
		BEGIN CATCH
			PRINT 'Error: ' + Error_Number() + ' ' + Error_Message()
			--THROW --do not throw, keep looping.
		END CATCH

		set @id = @id + 1
	end
	-------------------------------------------------
	declare @id int = 1, @maxid int, @tsql nvarchar(4000) = ''
	select @maxid = max(id) from fkscripts
	print 'Recreating all foreign keys'
	while @id <= @maxid
	begin
	
		BEGIN TRY 
			select @tsql = [Create_TSQL] from fkscripts where id = @id
			print @tsql
			exec sp_executesql @tsql
		END TRY
		BEGIN CATCH
			PRINT 'Error: ' + Error_Number() + ' ' + Error_Message()
			--THROW --do not throw, keep looping.
		END CATCH
		set @id = @id + 1
	end

*/


/*

--Test it out for compound PK/FK:
drop table if exists t2
drop table if exists t1
go
create table t1 
(id1 int not null
, id2 int not null
, id3 int not null
, constraint pk_t1 primary key (id1, id2, id3)
)
go
create table t2
( id int not null IDENTITY (1,1) constraint pk_t2 primary key 
, id1 int not null
, id2 int not null
, id3 int not null
, constraint fk_t2_T1 foreign key (id1, id2, id3) references t1 (id1, id2, id3)
)


*/