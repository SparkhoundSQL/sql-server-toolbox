select 
	
	database_name = d.name
,	principal_name = SUSER_SNAME (d.owner_sid)
,	set_to_sa = case when sp.name <> 'sa' THEN 'alter authorization on database::' + d.name + ' to sa' ELSE null END
,	set_to_current = case when sp.name <> 'sa' THEN 'alter authorization on database::' + d.name + ' to [' + sp.name + ']' ELSE null END
,	* 
from sys.databases d
left outer join sys.server_principals sp
on d.owner_sid = sp.sid
--where sp.name <> 'sa'