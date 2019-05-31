--Get members of a windows security group from within SQL
--Returns members but NOT subgroups! There isn't a way in SQL to see subgroups.
EXEC master..xp_logininfo 
@acctname = 'domain\groupname',
@option = 'members'

--Instead, use PowerShell:
--Get-ADGroupMember -identity 'Development' -recursive | select name

--or the windows plugin "Active Directory Users and Computers"