--Finds objects to drop that the Database Tuning Advisor (DTA) leaves behind when it inevitably crashes.

SELECT 'drop index [' + i.name+ '] on [' + schema_name(o.schema_id) + '].[' + object_name(i.[object_id]) + ']'
FROM sys.indexes i
INNER JOIN sys.objects o
ON i.object_id = o.object_id
WHERE 1=1 
and o.is_ms_shipped = 0
and o.type = 'u'
and i.name is not null
and i.is_hypothetical = 1 

select 'drop statistics [' + schema_name(o.schema_id) + '].[' + object_name(i.[object_id]) + '].['+ i.[name] + ']'
FROM sys.stats i
inner join sys.objects o 
on i.object_id = o.object_id 
WHERE 1=1
and o.is_ms_shipped = 0
and o.type = 'u'
and i.[name] LIKE '_dta%' 

