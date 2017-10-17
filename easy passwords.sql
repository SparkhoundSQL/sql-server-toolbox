
-- Easy passwords hash comparison
-- Rampant use of COLLATE sql_latin1_general_cp1_cs_as is to allow for case sensitivity in databases with case insensitive collation.
-- Passwords are case sensitive.

--First, check for sql logins without policy.
select name, is_policy_checked from sys.sql_logins where is_policy_checked =0


use master
go
drop table 
if exists  --SQL 2016+ only
#easypasswords

create table #easypasswords 
(id int not null identity(1,1) primary key
, pw nvarchar(400) 
	INDEX IDX1 CLUSTERED --this line is SQL 2014+ only
)

--TODO: insert corporate name here
insert into #easypasswords (pw) values ('sparkhound')

--All Users
insert into #easypasswords (pw) 
exec sp_MSforeachdb  N'use [?];
select name 
from sys.database_principals
where authentication_type_desc <> ''NONE''
and is_fixed_role = 0
and left(name,3) <> ''###''
and name <> ''dbo'''

--Most common passwords
insert into #easypasswords (pw) values (' '),('password'),('sa'),('test'),('qwerty'),('asdf'),('qwertyuiop')
, ('lsutigers'),('lsu'),('Lsu'),('Lsu')
,('sp'),('sharepoint'),('dev'),('prod'),('bi'),('test')
, ('x'),('Zz'),('St@rt123'),('1'),('P@ssword'),('bl4ck4ndwhite'),('admin'),('administrator'),('sysadmin'),('sudo'),('root'),('site'),('siteadmin')
,('alex'),('.......'),('demo'),('pos')
, ('123456789'),('12345678'),('1234567'),('123456'),('12345'),('1234'),('123'),('111111'),('123123'),('666666')
, ('baseball'),('dragon'),('football'),('monkey'),('letmein'),('baseball'),('mustang'),('access'),('shadow'),('master'),('michael'),('trustno1')
,('batman'),('696969'),('superman'),('jesus'),('christ'),('love'),('freedom'),('iloveyou'),('shalom'),('asdfghj'),('prod'),('test'),('dev'),('stayout'),('production'),('prod'),('real')
, ('abc123'),('ABC123'),('ABC123abc'),('abc123abc'),('abc123ABC'), ('abcd'), ('abcde'), ('abcdef')
, ('mardigras'), ('MardiGras')

--insert into #easypasswords (pw)  select distinct domain = replace(substring(service_account,0, charindex('\',service_account)),' ','' )
--from sys.dm_server_services --sql2008r2 or higher

insert into #easypasswords (pw) 
select name from sys.sql_logins l where name not like '##%'
union
select @@SERVERNAME 
union
select @@SERVICENAME
union
select name from sys.databases
union
select name from sys.credentials
union
select name from msdb.dbo.sysproxies
union
select remote_name from sys.linked_logins where remote_name is not null
union
select name from sys.servers
union
select data_source from sys.servers
union 
select convert(char(4), datepart(yyyy, getdate()))

insert into #easypasswords (pw)
select left(pw COLLATE sql_latin1_general_cp1_cs_as,2) from #easypasswords e where len(pw) > 2	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union
select left(pw COLLATE sql_latin1_general_cp1_cs_as,3) from #easypasswords e where len(pw) > 3	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union
select left(pw COLLATE sql_latin1_general_cp1_cs_as,4) from #easypasswords e where len(pw) > 4	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union
select left(pw COLLATE sql_latin1_general_cp1_cs_as,5) from #easypasswords e where len(pw) > 5	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union
select left(pw COLLATE sql_latin1_general_cp1_cs_as,6) from #easypasswords e where len(pw) > 6	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union
select left(pw COLLATE sql_latin1_general_cp1_cs_as,7) from #easypasswords e where len(pw) > 7 	 group by pw COLLATE sql_latin1_general_cp1_cs_as

insert into #easypasswords (pw)
select pw= replace(pw COLLATE sql_latin1_general_cp1_cs_as,'i','1') from #easypasswords	 group by pw  COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'e','3') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'a','@') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'o','0') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'s','$') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select pw= replace(pw COLLATE sql_latin1_general_cp1_cs_as,'i','1') from #easypasswords	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'e','3') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'a','@') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'o','0') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'s','$') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select pw= replace(pw COLLATE sql_latin1_general_cp1_cs_as,'i','1') from #easypasswords	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'e','3') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'a','@') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'o','0') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'s','$') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select pw= replace(pw COLLATE sql_latin1_general_cp1_cs_as,'i','1') from #easypasswords	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'e','3') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'a','@') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'o','0') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'s','$') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select pw= replace(pw COLLATE sql_latin1_general_cp1_cs_as,'i','1') from #easypasswords	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'e','3') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'a','@') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'o','0') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as
union select replace(pw COLLATE sql_latin1_general_cp1_cs_as,'s','$') from #easypasswords group by pw COLLATE sql_latin1_general_cp1_cs_as

insert into #easypasswords (pw)
select upper(pw COLLATE sql_latin1_general_cp1_cs_as) from #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select lower(pw COLLATE sql_latin1_general_cp1_cs_as) from #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select cast(upper(left(pw COLLATE sql_latin1_general_cp1_cs_as, 1)) as char(1)) + cast(substring(pw COLLATE sql_latin1_general_cp1_cs_as,2,399) as varchar(399)) 
from #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as

--permutations
insert into #easypasswords (pw)
select CONCAT(pw COLLATE sql_latin1_general_cp1_cs_as, '1') from #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select CONCAT(pw  COLLATE sql_latin1_general_cp1_cs_as, '123') from #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select CONCAT(pw COLLATE sql_latin1_general_cp1_cs_as , '!') from #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw) 
select CONCAT(pw  COLLATE sql_latin1_general_cp1_cs_as, '1') from #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select CONCAT(pw  COLLATE sql_latin1_general_cp1_cs_as, '!') from #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select CONCAT('1' , pw COLLATE sql_latin1_general_cp1_cs_as) from #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select CONCAT('!' , pw COLLATE sql_latin1_general_cp1_cs_as) from #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as

--Remove duplicates, case-sensitive 
delete e 
from #easypasswords e
inner join 
(select id, rn = row_number() over (partition by pw COLLATE sql_latin1_general_cp1_cs_as order by id ) 
from #easypasswords) x 
on e.id = x.id
where rn > 1

select 'checking '+ convert(varchar(30), (count(1))) + ' possible permutations' 
from #easypasswords e 

--Finally, compare our rainbow table to the hashes in sys.sql_logins.
select login = l.name, password = e.pw  COLLATE sql_latin1_general_cp1_cs_as
from sys.sql_logins l
cross apply #easypasswords e
where PWDCOMPARE(e.pw, l.password_hash) = 1
group by l.name, e.pw  COLLATE sql_latin1_general_cp1_cs_as



