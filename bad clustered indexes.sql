--Any rows returned in here probably need to be re-designed. Bad designs.

select 
	Database_name = DB_NAME()
,	Table_Name	= '[' + s.name + '].[' + o.name + ']'
,	Index_Name	= i.name
,	Column_Name = c.name
,	Data_Type	= t.name
from sys.columns c 
inner join sys.types t on c.user_type_id = t.user_type_id
inner join sys.objects o on o.object_id = c.object_id
inner join sys.schemas s on o.schema_id = s.schema_id
inner join sys.indexes i on i.object_id = o.object_id 
inner join sys.index_columns ic on ic.index_id = i.index_id and ic.column_id = c.column_id and ic.object_id = o.object_id
where
	(t.name = 'float' or t.name = 'uniqueidentifier' or t.max_length = -1) --GUID or (n)varchar(max) data types or float
and i.index_id = 1 --the clustered index
and o.is_ms_shipped = 0

