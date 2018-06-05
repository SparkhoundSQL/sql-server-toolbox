--Find database owners that are not desired

declare @Desired_DB_owner varchar(255) = 'sa' --'sa' is just an example, change to desired service account, example: domain\accountname

select 
	database_name = d.name
,	principal_name = SUSER_SNAME (d.owner_sid)
,	set_to_desired = 'alter authorization on database::[' + d.name + '] to [' + @Desired_DB_owner + ']' 
,	set_to_current =  case when SUSER_SNAME (d.owner_sid) <> @Desired_DB_owner THEN 'alter authorization on database::[' + d.name + '] to [' + SUSER_SNAME (d.owner_sid) + ']' ELSE NULL END
,	* 
from sys.databases d
where SUSER_SNAME (d.owner_sid) <> @Desired_DB_owner


