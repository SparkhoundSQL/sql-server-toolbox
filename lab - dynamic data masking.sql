use w
go
drop table if exists dbo.Corporate
go
create table dbo.Corporate
(
	id int not null identity(1,1) PRIMARY KEY
,	sensitive_email_default varchar(35) not null
,	sensitive_email_email varchar(35) not null
,	sensitive_email_custom varchar(35) not null
,	UserEmail varchar(35) not null
,	SSN char(11) not null
,	CorporateID int not null
)
go
insert into dbo.Corporate (sensitive_email_default, sensitive_email_email, sensitive_email_custom, UserEmail, SSN, CorporateID)
values ('testing@domain.com','testing@domain.com','testing@domain.com', 'testing@domain.com','123-45-6789','1000022')
, ('abc@abc.com','abc@abc.com','abc@abc.com','abc@abc.com','234-56-7891','2000033')
go
--Functions: https://docs.microsoft.com/en-us/sql/relational-databases/security/dynamic-data-masking

alter table dbo.Corporate
alter column sensitive_email_default
add MASKED WITH (FUNCTION = 'default()')
GO
alter table dbo.Corporate
alter column sensitive_email_email
add MASKED WITH (FUNCTION = 'email()')
GO
alter table dbo.Corporate
alter column sensitive_email_custom
add MASKED WITH (FUNCTION = 'partial(1,"XXX@XXXX",4)')
GO
alter table dbo.Corporate
alter column UserEmail
add MASKED WITH (FUNCTION = 'email()')
GO
alter table dbo.Corporate
alter column SSN
add MASKED WITH (FUNCTION = 'partial(1,"XX-XX-XX",2)')
GO
alter table dbo.Corporate
alter column CorporateID
add MASKED WITH (FUNCTION = 'default()')
GO

GRANT SELECT ON dbo.Corporate to [regularuser];

GO
--can see the data, since we're a member of the sysadmin role
select * from dbo.Corporate
GO
--execute as a low-privedged user with only regular permissions
EXECUTE AS LOGIN = 'regularuser';
select * from dbo.Corporate
REVERT;
