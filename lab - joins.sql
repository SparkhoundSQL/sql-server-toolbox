declare  @t1 table (id int not null  primary key
, test1 varchar(10) null)

declare  @t2 table (id int not null  primary key
, test1 varchar(10) null)

insert into @t1 values (1,'a'),(2,'b')
insert into @t2 values (2,'b'),(3,'c')

select * from @t1 t1 inner join @t2 t2 on t1.id = t2.id
select * from @t1 t1 join @t2 t2 on t1.id = t2.id --same as inner join, but confusing
select * from @t1 t1 left outer join @t2 t2 on t1.id = t2.id 
select * from @t1 t1 right outer join @t2 t2 on t1.id = t2.id 
select * from @t1 t1 cross join @t2 t2 
select * from @t1 t1 cross apply @t2 t2 --apply is intended for use with functions, not tables, but behaves the same as cross join here
select * from @t1 t1 outer apply @t2 t2 --apply is intended for use with functions, not tables, but behaves similarly as cross join here, but in different order
