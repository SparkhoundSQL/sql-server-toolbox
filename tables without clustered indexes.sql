--Doesn't work on 2000 databases or databases in 2000 compatability mode.  

select 
	[Database Name]					= db_name()
,	[Table Name]					= '[' + s.name + '].[' + o.name + ']'
,	[rows]							= sum(ps.row_count) 
,	Already_Has_Identity_column		= c.name
,	Already_Has_Unique_index		= i.name
from 
	sys.objects  o
inner join 
	sys.schemas s
on o.schema_id = s.schema_id
inner join 
	sys.dm_db_partition_stats ps
	on ps.object_id = o.object_id
	and index_id = 0
left outer join 
	sys.columns c on c.object_id = o.object_id 
	and c.is_identity = 1
left outer join 
	sys.indexes i on i.object_id = o.object_id
	and (i.is_unique = 1 or i.is_unique_constraint = 1 or i.is_primary_key = 1)
left outer join
	sys.index_columns ic on ic.object_id = o.object_id and i.index_id = ic.index_id and ic.column_id = c.column_id
WHERE 
	o.name <> 'dtproperties'
and is_ms_shipped = 0
and o.type = 'u'
group by  s.name, o.name, i.name, c.name
order by rows desc
go

/*

create table noCL1
(id int not null IDENTITY(1,1)
,whatever1 int )


create table noCL2
(id int not null 
,whatever1 int INDEX IDX_CL UNIQUE)

*/