--Find duplicate indexes based on keysets and properties

SELECT TableName, IndexName1, IndexName2
, Idx_counter, Idx_first_counter, Keyset_counter, SizeMb
,  [Drop_TSQL] = CASE	WHEN y.Idx_counter > 1 and Idx_first_counter = 1 
	THEN 'IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + TableName + ''') AND name = N''' + IndexName1 + ''')
							DROP INDEX [' + IndexName1 + '] ON ' + TableName + ';' 
	ELSE '' END
FROM (
	SELECT  TableName, IndexName1, IndexName2, SizeMb
		,	Idx_counter = row_number() OVER (PARTITION BY TableName, IndexDefinition1 order by IndexName1, IndexName2)
		,	Idx_first_counter = row_number() OVER (PARTITION BY IndexName1 ORDER BY IndexName1, TableName)
		,	Keyset_counter = dense_rank() OVER ( ORDER BY IndexDefinition1)
		FROM (
			SELECT 
			  TableName = '[' + sc.name + '].[' + o.name + ']'
			, IndexName1 = i1.name, IndexName2 = i2.name
			, IndexDefinition1= (select tablename = object_name(ic.object_id), --indexname = i.name, 
					columnname = c.name,  is_descending_key = ic.is_descending_key, i.type_desc, is_included_column = ic.is_included_column, is_primary_key = i.is_primary_key, is_unique = i.is_unique, has_filter = i.has_filter, filter_definition  = isnull(filter_definition,'') from sys.index_columns ic
					inner join sys.indexes i on i.index_id = ic.index_id and i.object_id = ic.object_id 
					inner join sys.columns c on ic.object_id = c.object_id and ic.column_id = c.column_id 
					where ic.index_id = i1.index_id and ic.object_id = o.object_id and i.index_id > 1
					FOR XML AUTO) 
			, IndexDefinition2= (select tablename = object_name(ic.object_id), --indexname = i.name, 
					columnname = c.name, is_descending_key = ic.is_descending_key, i.type_desc, is_included_column = ic.is_included_column, is_primary_key = i.is_primary_key, is_unique = i.is_unique, has_filter = i.has_filter, filter_definition  = isnull(filter_definition,'') from sys.index_columns ic
					inner join sys.indexes i on i.index_id = ic.index_id and i.object_id = ic.object_id 
					inner join sys.columns c on ic.object_id = c.object_id and ic.column_id = c.column_id 
					where ic.index_id = i2.index_id and ic.object_id = o.object_id and i.index_id > 1
					FOR XML AUTO)
			, SizeMb= (p.in_row_reserved_page_count*8.)/1024.
			from sys.indexes i1 
			inner join sys.indexes i2
			on i1.object_id  = i2.object_id 
			inner join sys.objects o 
			on i1.object_id = o.object_id
			inner join sys.schemas sc
			on sc.schema_id = o.schema_id
			inner join sys.dm_db_partition_stats p
			on p.object_id = o.object_id
			and p.index_id = i1.index_id 
			WHERE 
				i1.name <> i2.name
			and i1.index_id <> i2.index_id
			and (
				UPPER(i1.name) = UPPER(i2.name) 
				or 
				(
					(select tablename = object_name(ic.object_id), columnname = c.name, si.type_desc, is_descending_key = ic.is_descending_key, is_included_column = ic.is_included_column, is_primary_key = si.is_primary_key, is_unique = si.is_unique, has_filter = si.has_filter, filter_definition  = isnull(filter_definition,'')
					from sys.index_columns ic
					inner join sys.indexes si on si.index_id = ic.index_id and si.object_id = ic.object_id 
					inner join sys.columns c on ic.object_id = c.object_id and ic.column_id = c.column_id 
					where ic.index_id = i1.index_id and ic.object_id = o.object_id and si.index_id > 1
					FOR XML AUTO)
					= 
					(select tablename = object_name(ic.object_id), columnname = c.name, si.type_desc, is_descending_key = ic.is_descending_key, is_included_column = ic.is_included_column, is_primary_key = si.is_primary_key, is_unique = si.is_unique, has_filter = si.has_filter, filter_definition  = isnull(filter_definition,'')
					from sys.index_columns ic
					inner join sys.indexes si on si.index_id = ic.index_id and si.object_id = ic.object_id 
					inner join sys.columns c on ic.object_id = c.object_id and ic.column_id = c.column_id 
					where ic.index_id = i2.index_id and ic.object_id = o.object_id and si.index_id > 1
					FOR XML AUTO)
				)
			)
	) x
) y

ORDER BY TableName, IndexName1, IndexName2


/*


IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bAPPH]') AND name = N'biAPPHUniqueAttchID')
			DROP INDEX [biAPPHUniqueAttchID] ON [dbo].[bAPPH];
*/