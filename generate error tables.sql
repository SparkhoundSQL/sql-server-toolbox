SET NOCOUNT ON

DECLARE BuildErrorTables CURSOR FAST_FORWARD
FOR
	select 
		o.object_id 
	from sys.objects o
	inner join sys.schemas s
	on o.schema_id = s.schema_id
	where s.name = 'WH'
	and type_desc = 'USER_TABLE'
	and o.name <> 'DimDate'

OPEN BuildErrorTables

declare @object_id int

FETCH NEXT FROM BuildErrorTables 
INTO @object_id

DECLARE @BuildErrorTable TABLE 
(tsql varchar(500) null) 

WHILE @@FETCH_STATUS = 0
BEGIN

	insert into @BuildErrorTable (tsql)
	select 'IF EXISTS (SELECT * FROM sys.objects o inner join sys.schemas s on o.schema_id = s.schema_id where o.name  = '''+   object_name(@object_id) + ''' and s.name = ''ERROR'')'

	insert into @BuildErrorTable (tsql)
	select 'DROP table ERROR.[' + convert(sysname, object_name(@object_id)) + ']'

	insert into @BuildErrorTable (tsql)
	select 'GO'

	insert into @BuildErrorTable (tsql)
	select 'create table ERROR.[' + convert(sysname, object_name(@object_id)) + '] ('

	insert into @BuildErrorTable (tsql)
	select '	ID bigint not null IDENTITY(1,1) PRIMARY KEY '

	insert into @BuildErrorTable (tsql)
	select 
		column_name = ', ' + c.name + ' ' + case	when t.name in ('binary', 'sysname', 'smallint', 'int', 'bigint', 'decimal', 'float', 'real', 'date', 'time', 'datetime', 'datetime2', 'datetimeoffset'
													, 'timestamp', 'numeric', 'money', 'smallmoney')
													THEN 'varchar (100)'
									when t.name in ('bit', 'tinyint') THEN 'varchar (10)'
									when t.name in ('char','varchar') and c.max_length <= 4000	THEN 'varchar (' + cast(c.max_length * 2 as varchar(5)) + ')'
									when t.name in ('char','varchar') and c.max_length > 4000	THEN 'varchar (8000)'
									when t.name in ('nchar','nvarchar') and c.max_length <= 2000 THEN 'nvarchar (' + cast(c.max_length * 2 as varchar(5)) + ')'
									when t.name in ('nchar','nvarchar') and c.max_length > 2000 THEN 'nvarchar (4000)'
									when t.name in ('text') THEN 'varchar (8000)'
									when t.name in ('ntext') THEN 'nvarchar (4000)'
									else 'varchar(8000)'
								END + ' NULL'
	from
	sys.objects o
	inner join sys.schemas s
	on o.schema_id = s.schema_id
	inner join sys.columns c 
	on c.object_id = o.object_id
	inner join sys.types t 
	on c.user_type_id = t.user_type_id
	where 
		o.object_id = @object_id

	insert into @BuildErrorTable (tsql)
	select ', ErrorDate datetime2(0) not null constraint DF_' + replace(convert(sysname, object_name(@object_id)), ' ','_') + '_ErrorDate DEFAULT (getdate())'
	insert into @BuildErrorTable (tsql)
	select ', ErrorText varchar(100) null'
	insert into @BuildErrorTable (tsql)
	select ', ErrorCode varchar(100) null'
	insert into @BuildErrorTable (tsql)
	select ', AuditID int null'

	insert into @BuildErrorTable (tsql)
	select ');'

	insert into @BuildErrorTable (tsql)
	select 'go'

	FETCH NEXT FROM BuildErrorTables 
	INTO @object_id

END


select * from @BuildErrorTable 