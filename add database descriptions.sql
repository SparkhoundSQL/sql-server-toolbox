

exec sp_MSforeachdb '
if ((select db_id(''?'')) > 4 or ''?'' = ''model'' )
BEGIN
EXEC [?].sys.sp_addextendedproperty @name=N''Description'', @value=N''Change this value'';
EXEC [?].sys.sp_addextendedproperty @name=N''BusinessOwner'', @value=N''Change this value'';
END'

select * from sys.databases
exec sp_MSforeachdb 'select ''[?]'', class_desc, name, value from [?].sys.extended_properties ep where class_desc = ''database'''

