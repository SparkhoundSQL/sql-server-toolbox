use w
go
select top 100 objectname, indexname, [object_id], index_id, Buffer_MB = SUM(Buffer_MB)
from
(
	SELECT 
		objectname	=	obj.[name],
		indexname	=	i.[name],
		obj.[object_id],
		i.[index_id],
		i.[type_desc],
		--count(*)AS Buffered_Page_Count ,
		count(*) * 8192.0 / (1024.0 * 1024.0) as Buffer_MB
		-- ,obj.name ,obj.index_id, i.[name]
	FROM sys.dm_os_buffer_descriptors AS bd 
		INNER JOIN 
		(
			SELECT object_name(object_id) AS name 
				,index_id ,allocation_unit_id, object_id
			FROM sys.allocation_units AS au
				INNER JOIN sys.partitions AS p 
					ON au.container_id = p.hobt_id 			
		) AS obj 
			ON bd.allocation_unit_id = obj.allocation_unit_id
	LEFT OUTER JOIN sys.indexes i on i.object_id = obj.object_id AND i.index_id = obj.index_id
	
	WHERE database_id = db_id()
	
	
	GROUP BY obj.name, obj.index_id , i.[name],i.[type_desc], obj.[object_id], i.index_id
) x
	GROUP BY objectname, indexname, [type_desc], [object_id], index_id
	order by Buffer_MB desc
