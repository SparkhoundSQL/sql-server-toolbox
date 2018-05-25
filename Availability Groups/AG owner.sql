--should not be owned by named account!
--Run this on EACH replica SQL instance, it may be different.

SELECT ar.replica_server_name
	,ag.name AS ag_name
	,ar.owner_sid
	,sp.name
FROM sys.availability_replicas ar
LEFT JOIN sys.server_principals sp
	ON sp.sid = ar.owner_sid 
INNER JOIN sys.availability_groups ag
	ON ag.group_id = ar.group_id
WHERE ar.replica_server_name = SERVERPROPERTY('ServerName') ;

/*

ALTER AUTHORIZATION ON AVAILABILITY GROUP::[drAG1] to [sa] ;

*/