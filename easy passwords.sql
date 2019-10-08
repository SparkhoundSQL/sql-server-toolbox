-- Easy passwords hash comparison
-- SQL 2012+ only.
-- WARNING this script may take ~1 hour to complete.

-- Complete two TODO items below before executing

-- Rampant use of COLLATE sql_latin1_general_cp1_cs_as is to allow for case sensitivity in databases with case insensitive collation.
-- Passwords are case sensitive, sql login names are not.

--First, check for sql logins without policy.
select name, is_policy_checked from sys.sql_logins where is_policy_checked =0 order by name 
GO
use master
go
drop table 
if exists  --SQL 2016+ only
#easypasswords

CREATE TABLE #easypasswords 
(id int not null identity(1,1) primary key
, pw nvarchar(400) 
	INDEX IDX1 CLUSTERED --this line is SQL 2014+ only
)

--TODO: insert corporate/department names and acronym here here
insert into #easypasswords (pw) values ('sparkhound'),('sparky')

--TODO: Add regional and local references, sports, etc.
insert into #easypasswords (pw) values ('lsutigers'),('lsu'),('Lsu'),('Lsu'),('texas'),('tx'), ('mardigras'), ('MardiGras'),('astros'), ('astro'),('whodat'),('nola'),('saints'),('cowboys'),('texans')

--Most common passwords found online in various password dumps and common penetration tests
insert into #easypasswords (pw) values (' '),('password'),('sa'),('test'),('qwerty'),('asdf'),('qwertyuiop'),('zxcv')
,('sql'),('db'),('database'),('sequel'),('corp'),('ssa')
,('sp'),('sharepoint'),('dev'),('prod'),('bi'),('test')
, ('x'),('Zz'),('St@rt123'),('1'),('P@ssword'),('bl4ck4ndwhite'),('admin'),('administrator'),('sysadmin'),('sudo'),('root'),('site'),('siteadmin'),('pw')
,('alex'),('.......'),('demo'),('pos')
, ('123456789'),('12345678'),('1234567'),('123456'),('12345'),('1234'),('123'),('111111'),('123123'),('666666'),('2000'),('987')
, ('baseball'),('dragon'),('football'),('monkey'),('letmein'),('baseball'),('mustang'),('access'),('shadow'),('master'),('michael'),('trustno1')
,('batman'),('696969'),('superman'),('jesus'),('christ'),('love'),('freedom'),('iloveyou'),('shalom'),('asdfghj'),('prod'),('test'),('dev'),('stayout'),('production'),('prod'),('real')
, ('abc123'),('ABC123'),('ABC123abc'),('abc123abc'),('abc123ABC'), ('abcd'), ('abcde'), ('abcdef')

--All Users
insert into #easypasswords (pw) 
exec sp_MSforeachdb  N'use [?];
select name 
from sys.database_principals
where authentication_type_desc <> ''NONE''
and is_fixed_role = 0
and left(name,3) <> ''###''
and name <> ''dbo'''

insert into #easypasswords (pw)  
select distinct domain = replace(substring(service_account,0, charindex('\',service_account)),' ','' )
from sys.dm_server_services --sql2008r2 or higher

insert into #easypasswords (pw) 
select name from sys.sql_logins l where name not like '##%'
union all
select @@SERVERNAME 
union all
select @@SERVICENAME
union all
select name from sys.databases
union all
select name from sys.credentials
union all
select name from msdb.dbo.sysproxies
union all
select remote_name from sys.linked_logins where remote_name is not null
union all
select name from sys.servers
union all
select data_source from sys.servers
union all
select convert(char(4), datepart(yyyy, getdate()))

insert into #easypasswords (pw)
select left(pw COLLATE sql_latin1_general_cp1_cs_as,2) from #easypasswords e where len(pw) > 2	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union all
select left(pw COLLATE sql_latin1_general_cp1_cs_as,3) from #easypasswords e where len(pw) > 3	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union all
select left(pw COLLATE sql_latin1_general_cp1_cs_as,4) from #easypasswords e where len(pw) > 4	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union all
select left(pw COLLATE sql_latin1_general_cp1_cs_as,5) from #easypasswords e where len(pw) > 5	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union all
select left(pw COLLATE sql_latin1_general_cp1_cs_as,6) from #easypasswords e where len(pw) > 6	 group by pw COLLATE sql_latin1_general_cp1_cs_as
union all
select left(pw COLLATE sql_latin1_general_cp1_cs_as,7) from #easypasswords e where len(pw) > 7 	 group by pw COLLATE sql_latin1_general_cp1_cs_as

insert into #easypasswords (pw)
		select pw=	 replace(pw ,'i','1'   ) FROM #easypasswords group by pw 
		union all select replace(pw ,'e','3'   ) FROM #easypasswords group by pw 
		union all select replace(pw ,'a','@'   ) FROM #easypasswords group by pw 
		union all select replace(pw ,'o','0'   ) FROM #easypasswords group by pw 
		union all select replace(pw ,'s','$'   ) FROM #easypasswords group by pw 
		union all select replace(pw ,'x','*'   ) FROM #easypasswords group by pw 
		union all select replace(pw ,'t','+'   ) FROM #easypasswords group by pw 
		union all select replace(pw ,' ','_'   ) FROM #easypasswords group by pw 
		union all select replace(pw ,'_',' '   ) FROM #easypasswords group by pw 

insert into #easypasswords (pw)
select upper(pw COLLATE sql_latin1_general_cp1_cs_as  ) FROM #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select lower(pw COLLATE sql_latin1_general_cp1_cs_as  ) FROM #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select cast(upper(left(pw COLLATE sql_latin1_general_cp1_cs_as, 1)) as char(1)) + cast(substring(pw COLLATE sql_latin1_general_cp1_cs_as,2,399) as varchar(399)) 
from #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as

--permutations
insert into #easypasswords (pw)
select CONCAT(pw COLLATE sql_latin1_general_cp1_cs_as, '1' COLLATE sql_latin1_general_cp1_cs_as  ) FROM #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select CONCAT(pw  COLLATE sql_latin1_general_cp1_cs_as, '123' COLLATE sql_latin1_general_cp1_cs_as  ) FROM #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select CONCAT(pw COLLATE sql_latin1_general_cp1_cs_as , '!' COLLATE sql_latin1_general_cp1_cs_as  ) FROM #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw) 
select CONCAT(pw  COLLATE sql_latin1_general_cp1_cs_as, '1' COLLATE sql_latin1_general_cp1_cs_as  ) FROM #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select CONCAT(pw  COLLATE sql_latin1_general_cp1_cs_as, '!' COLLATE sql_latin1_general_cp1_cs_as  ) FROM #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select CONCAT('1' COLLATE sql_latin1_general_cp1_cs_as  , pw COLLATE sql_latin1_general_cp1_cs_as   ) FROM #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as
insert into #easypasswords (pw)
select CONCAT('!' COLLATE sql_latin1_general_cp1_cs_as  , pw COLLATE sql_latin1_general_cp1_cs_as   ) FROM #easypasswords e group by pw COLLATE sql_latin1_general_cp1_cs_as

--Remove duplicates, case-sensitive 
delete e 
from #easypasswords e
inner join 
(select id, rn = row_number() over (partition by pw COLLATE sql_latin1_general_cp1_cs_as order by id ) 
from #easypasswords) x 
on e.id = x.id
where rn > 1;

select 'checking '+ convert(varchar(30), (count(1))) + ' possible permutations' 
from #easypasswords e;

--Finally, compare our rainbow table to the hashes in sys.sql_logins.
select login = l.name, password = e.pw  COLLATE sql_latin1_general_cp1_cs_as
from sys.sql_logins l
cross apply #easypasswords e
where PWDCOMPARE(e.pw, l.password_hash) = 1
group by l.name, e.pw  COLLATE sql_latin1_general_cp1_cs_as
ORDER BY l.name;
GO




