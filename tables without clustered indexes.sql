--Doesn't work on 2000 databases or databases in 2000 compatability mode.  

select 
	[Database Name] = db_name()
,	[Table Name]	= s.name + '.' + o.name
,	[rows]			= sum(ps.row_count) 

from 
	sys.objects  o
inner join 
	sys.schemas s
on o.schema_id = s.schema_id
inner join 
	sys.dm_db_partition_stats ps
	on ps.object_id = o.object_id
	and index_id = 0
WHERE 
	o.name <> 'dtproperties'
and is_ms_shipped = 0
and o.type = 'u'
group by  s.name + '.' + o.name
order by rows desc
go

