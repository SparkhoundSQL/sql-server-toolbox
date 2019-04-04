--Get members of a windows security group from within SQL
--Returns members but NOT subgroups! There isn't a way in SQL to see subgroups.
EXEC master..xp_logininfo 
@acctname = 'domain\groupname',
@option = 'members'
