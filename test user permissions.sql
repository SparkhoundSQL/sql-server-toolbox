use w;

--test my permissions
select * from fn_my_permissions('dbo.ssisyslog', 'OBJECT') order by 1,2,3;

--Find role membership
exec xp_logininfo 'dbm\william.assaf', 'all'

/*
--test another's permissions

execute as login = 'domain\username' --or 'sqlloginname';
select * from fn_my_permissions('dbo.ssisyslog', 'OBJECT') order by 1,2,3;
REVERT; --VERY IMPORTANT, or you will continue to execute as.
*/