
USE [AdventureWorks2012]
GO
--dependencies by text
select s.name +'.' + o.name, o.type_desc, m.definition, LEN(m.definition)
from sys.sql_modules m 
inner join sys.objects o on m.object_id = o.object_id 
inner join sys.schemas s on s.schema_id = o.schema_id
where definition like '%JobCode%'
order by o.name


--dependencies by dependency
select 
	ReferencingObjectName = rs.name + '.' + ro.name
,	ReferencingObjectType = ro.type_desc
,	ReferencedObjectName = s.name + '.' + o.name 
,	ReferencedObjectType = o.type_desc 

from sys.sql_expression_dependencies d
inner join sys.objects o on d.referenced_id = o.object_id or d.referenced_minor_id = o.object_id
inner join sys.schemas s on o.schema_id = s.schema_id
inner join sys.objects ro on d.referencing_id = ro.object_id
inner join sys.schemas rs on ro.schema_id = rs.schema_id
where 
--	ro.is_ms_shipped = 0
--and o.is_ms_shipped = 0
--and op.type_desc = 'SQL_STORED_PROCEDURE'
--and s.name = 'Loading'
o.name like '%JobCode%'
group by rs.name , ro.name, s.name , o.name , ro.type_desc, o.type_desc
order by ro.name, o.name 


