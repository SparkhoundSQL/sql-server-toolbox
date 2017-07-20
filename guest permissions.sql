--Check all DB's for Guest permissions.
--Guest user should NOT be disabled on system databases https://support.microsoft.com/en-us/kb/2539091

exec sp_MSforeachdb '
SELECT Db_name = ''?''
, prins.name AS grantee_name
, perms.permission_name
, state_desc
, Revoke_TSQL = CASE WHEN state_desc = ''GRANT'' and db_ID(''?'') > 4 THEN ''use [?]; REVOKE CONNECT TO GUEST;'' END
, *
FROM [?].sys.database_principals AS prins 
INNER JOIN [?].sys.database_permissions AS perms
ON perms.grantee_principal_id = prins.principal_id
WHERE prins.name = ''guest'' 
AND state_desc = ''GRANT''

'
