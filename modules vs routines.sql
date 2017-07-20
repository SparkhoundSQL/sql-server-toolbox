use [AdventureWorks2012]
go

select s.name +'.' + o.name, o.type_desc, m.definition, LEN(m.definition)
from sys.sql_modules m 
inner join sys.objects o on m.object_id = o.object_id 
inner join sys.schemas s on s.schema_id = o.schema_id
where definition like '%switch%partition%'
order by o.name

select r.SPECIFIC_SCHEMA + '.' + r.SPECIFIC_NAME, r.routine_type, r.ROUTINE_DEFINITION, LEN(routine_definition) 
from INFORMATION_SCHEMA.routines r
where ROUTINE_DEFINITION like '%GroupName%'
order by ROUTINE_NAME 



