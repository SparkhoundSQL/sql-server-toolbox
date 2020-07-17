drop table if exists test
create table test
(id int not null Identity(1,1) constraint pk_test primary key
, null1 varchar(10) NULL Constraint DF_test_null1 DEFAULT ('')
, null2 varchar(10) NULL Constraint DF_test_null2 DEFAULT ('')
)
GO
insert into test (null1) values ('1') 
insert into test (null1) values (null) --despite a default constraint, the NULL WILL INSERT.
GO

select * from test 