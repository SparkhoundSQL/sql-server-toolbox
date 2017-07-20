use master
go
declare @easypasswords table (id int not null identity(1,1) primary key, pw nvarchar(400) 
INDEX IDX1 CLUSTERED --SQL 2014+ only
)

insert into @easypasswords (pw) 
exec sp_MSforeachdb  N'use [?];
select name 
from sys.database_principals
where authentication_type_desc <> ''NONE''
and is_fixed_role = 0
and left(name,3) <> ''###''
and name <> ''dbo'''

--TODO: insert corporate name here
insert into @easypasswords (pw) values ('sparkhound')


insert into @easypasswords (pw) values (' '),('password'),('sa'),('test'),('qwerty'),('asdf'),('qwertyuiop')
, ('lsutigers'),('lsu')
,('sp'),('sharepoint'),('dev'),('prod'),('bi'),('test')
, ('x'),('Zz'),('St@rt123'),('1'),('P@ssword'),('bl4ck4ndwhite'),('admin'),('administrator'),('alex'),('.......'),('demo'),('pos')
, ('123456789'),('12345678'),('1234567'),('123456'),('12345'),('1234'),('123'),('111111'),('123123'),('666666')
, ('baseball'),('dragon'),('football'),('monkey'),('letmein'),('baseball'),('mustang'),('access'),('shadow'),('master'),('michael'),('trustno1')
,('batman'),('696969'),('superman'),('jesus'),('christ'),('love'),('freedom'),('iloveyou'),('shalom'),('asdfghj'),('prod'),('test'),('dev'),('stayout'),('production'),('prod'),('real')
, ('abc123'),('ABC123'),('ABC123abc'),('abc123abc'),('abc123ABC'), ('abcd'), ('abcde'), ('abcdef')

--insert into @easypasswords (pw)  select distinct domain = replace(substring(service_account,0, charindex('\',service_account)),' ','' )
--from sys.dm_server_services --sql2008r2 or higher

insert into @easypasswords (pw) 
select name from sys.sql_logins l 
union
select @@SERVERNAME 
union
select @@SERVICENAME
union
select name from sys.databases
union
select name from sys.credentials
union
select remote_name from sys.linked_logins where remote_name is not null
union
select name from sys.servers
union
select data_source from sys.servers



insert into @easypasswords (pw)
select left(pw,2) from @easypasswords e where len(pw) > 2	 group by pw
union
select left(pw,3) from @easypasswords e where len(pw) > 3	 group by pw
union
select left(pw,4) from @easypasswords e where len(pw) > 4	 group by pw
union
select left(pw,5) from @easypasswords e where len(pw) > 5	 group by pw
union
select left(pw,6) from @easypasswords e where len(pw) > 6	 group by pw
union
select left(pw,7) from @easypasswords e where len(pw) > 7 	 group by pw

insert into @easypasswords (pw)
select pw= replace(pw,'i','1') from @easypasswords	 group by pw
union select replace(pw,'e','3') from @easypasswords group by pw
union select replace(pw,'a','@') from @easypasswords group by pw
union select replace(pw,'o','0') from @easypasswords group by pw
union select replace(pw,'s','$') from @easypasswords group by pw
insert into @easypasswords (pw)
select pw= replace(pw,'i','1') from @easypasswords	 group by pw
union select replace(pw,'e','3') from @easypasswords group by pw
union select replace(pw,'a','@') from @easypasswords group by pw
union select replace(pw,'o','0') from @easypasswords group by pw
union select replace(pw,'s','$') from @easypasswords group by pw
insert into @easypasswords (pw)
select pw= replace(pw,'i','1') from @easypasswords	 group by pw
union select replace(pw,'e','3') from @easypasswords group by pw
union select replace(pw,'a','@') from @easypasswords group by pw
union select replace(pw,'o','0') from @easypasswords group by pw
union select replace(pw,'s','$') from @easypasswords group by pw
insert into @easypasswords (pw)
select pw= replace(pw,'i','1') from @easypasswords	 group by pw
union select replace(pw,'e','3') from @easypasswords group by pw
union select replace(pw,'a','@') from @easypasswords group by pw
union select replace(pw,'o','0') from @easypasswords group by pw
union select replace(pw,'s','$') from @easypasswords group by pw
insert into @easypasswords (pw)
select pw= replace(pw,'i','1') from @easypasswords	 group by pw
union select replace(pw,'e','3') from @easypasswords group by pw
union select replace(pw,'a','@') from @easypasswords group by pw
union select replace(pw,'o','0') from @easypasswords group by pw
union select replace(pw,'s','$') from @easypasswords group by pw

insert into @easypasswords (pw)
select upper(pw) from @easypasswords e group by pw
insert into @easypasswords (pw)
select lower(pw) from @easypasswords e group by pw
insert into @easypasswords (pw)
select cast(upper(left(pw, 1)) as char(1)) + cast(substring(pw,2,399) as varchar(399)) from @easypasswords e group by pw

--permutations
insert into @easypasswords (pw)
select pw + '1' from @easypasswords e group by pw
insert into @easypasswords (pw)
select pw + '123' from @easypasswords e group by pw
insert into @easypasswords (pw)
select pw + '!' from @easypasswords e group by pw
insert into @easypasswords (pw) 
select pw + '1' from @easypasswords e group by pw
insert into @easypasswords (pw)
select pw + '!' from @easypasswords e group by pw
insert into @easypasswords (pw)
select '1' + pw from @easypasswords e group by pw
insert into @easypasswords (pw)
select '!' + pw from @easypasswords e group by pw

select 'checking'+str(count(1))+ ' permutations' 
from (select id, pw, rownum= row_number() over (partition by pw order by id )
from @easypasswords e ) z
where rownum =1

;with cteEZ(id, pw, rownum) as (
select id, pw, row_number() over (partition by pw order by id )
from @easypasswords e )
select distinct login = name, password = e.pw from sys.sql_logins l
cross apply cteEZ e
where PWDCOMPARE(e.pw, l.password_hash) = 1
and e.rownum = 1

select name, is_policy_checked from sys.sql_logins where is_policy_checked =0

