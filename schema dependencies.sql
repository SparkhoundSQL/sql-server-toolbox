
SELECT DISTINCT
      referenced_database_name = db_name()
	, referencing_entity_name = s_ing.name + '.' + OBJECT_NAME(referencing_id) 
	, referencing_type_desc = o_ing.type_desc  + CASE WHEN cc.is_persisted = 1 THEN ' PERSISTED' ELSE '' END  + CASE WHEN cc.column_id is not null THEN ' COMPUTED COLUMN' ELSE '' END 
	, referencing_minor_object = case WHEN REFERENCING_CLASS_DESC = 'OBJECT_OR_COLUMN' THEN COALESCE(COL_NAME(referencing_id, referencing_minor_id), '(n/a)') 
								  WHEN REFERENCING_CLASS_DESC = 'INDEX' THEN  i.name 
								  ELSE '(n/a)'
								END
	, referencing_class_desc = CASE WHEN referencing_class_desc = 'INDEX' and i.has_filter = 1 THEN 'FILTERED INDEX' ELSE referenced_class_desc END
	, referenced_class_desc
	, referenced_server_name = isnull(referenced_server_name, @@SERVERNAME)
	, referenced_database_name = isnull(referenced_database_name, db_name())
	--, referenced_schema_name = isnull(referenced_schema_name, 'dbo')
	, referenced_entity_name = ISNULL(s_ed.name + '.','') + referenced_entity_name
	, referenced_type_desc = ISNULL(o_ed.type_desc, CASE WHEN sed.is_ambiguous = 1 THEN 'reference is ambiguous, resolved at runtime' ELSE 'remote object type not available' END)
	, referenced_column_name = COALESCE(COL_NAME(referenced_id, referenced_minor_id), '(n/a)') 
	--, is_caller_dependent, is_ambiguous
	,*
FROM sys.sql_expression_dependencies AS sed  
INNER JOIN sys.objects AS o_ing ON sed.referencing_id = o_ing.object_id  
LEFT OUTER JOIN sys.objects AS o_ed ON sed.referenced_id = o_ed.object_id  
LEFT OUTER JOIN Sys.computed_columns AS cc on cc.object_id = o_ing.object_id and cc.column_id = sed.referencing_minor_id
INNER JOIN sys.schemas s_ing on s_ing.schema_id = o_ing.schema_id
LEFT OUTER JOIN sys.schemas s_ed on s_ed.schema_id = o_ed.schema_id
LEFT OUTER JOIN sys.indexes i on i.index_id = sed.referencing_minor_id and sed.referencing_class_desc = 'INDEX' and i.object_id = o_ing.object_id
--where s_ing.name + '.' + OBJECT_NAME(referencing_id)  = 'dbo.SH_MSRS_REPORTTITLE'
 order by sed.referenced_entity_name, referencing_entity_name
GO
--reference: https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sql-expression-dependencies-transact-sql?view=sql-server-ver15
--inspired by https://docs.microsoft.com/en-us/sql/relational-databases/stored-procedures/view-the-dependencies-of-a-stored-procedure?view=sql-server-ver15

 