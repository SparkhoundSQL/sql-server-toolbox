
select 
	[Database Name] = db_name()
,	[Table Name]	= s.name + '.' + o.name
,	[Column Name]	= c.name
,	[Total_rows]	= sum(ps.row_count) 
--Review the distribution of the data in the table
,	TSQL_Testing	= 'select [' + c.name + '], count(1) from ['+ s.name + '].[' + o.name+'] group by [' + c.name + ']' 
from 
	sys.objects  o
inner join 
	sys.schemas s
	on o.schema_id = s.schema_id
inner join 
	sys.dm_db_partition_stats ps
	on ps.object_id = o.object_id
	and index_id <= 1 --heap or cluster index, ignore NC indexes

left outer join 
	sys.columns c on c.object_id = o.object_id 
left outer join 
	sys.types t on c.user_type_id = t.user_type_id
WHERE 
	o.name <> 'dtproperties'
and is_ms_shipped = 0
and o.type = 'u'
and (c.name like 'is%' or c.name like '%active%' or c.name like '%ignore%' 
or c.name like '%current%' or c.name like '%archived%' or c.name like '%flag%' 
or c.name like '%bit%' or t.name = 'bit' 
--Add any more naming conventions here
)
group by c.name, s.name, o.name
having sum(ps.row_count) > 100000
order by rows desc
go

/*
--Potential Filtered index opportunities
select iscurrentphase, count(1) from RepairOrderRepairPhases group by IsCurrentPhase
select isEnabled, count(1) from dbo.Users group by IsEnabled
select [ISPUBLIC], count(1) from [dbo].[TNOTE] group by [ISPUBLIC]

--Potential filtered index
CREATE INDEX IDX_NC_F_Testing on dbo.testtable (Whatever1, whatever2) INCLUDE (whatever3)
WHERE IsActive = 1;

*/