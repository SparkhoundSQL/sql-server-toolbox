--RUN ENTIRE SCRIPT
DROP TABLE IF EXISTS dbo.fragmented_table_nsi
go
CREATE TABLE dbo.fragmented_table_nsi
	(
	fragid uniqueidentifier NOT NULL DEFAULT newsequentialID(),
	fragtext varchar(100) NOT NULL,
	fragtext2 varchar(100) NOT NULL

	)  
GO
ALTER TABLE dbo.fragmented_table_nsi ADD CONSTRAINT
	PK_fragmented_table_nsi PRIMARY KEY CLUSTERED 
	(
	fragid
	)  
 WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON --SQL 2019 only!
	)
go
CREATE NONCLUSTERED INDEX IDX_NC_fragmented_table_nsi
ON dbo.fragmented_table_nsi (FRAGTEXT) 
 WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON --SQL 2019 only!
	)

GO


--Insert roughly 131072k records

	insert into dbo.fragmented_table_nsi (fragtext, fragtext2) 
	select replicate(char(round(rand()*100,0)),round(rand()*100,0)),  replicate(char(round(rand()*100,0)),round(rand()*100,0))
go
declare @x integer
set @x = 1 
while @x < 19
begin
	insert into dbo.fragmented_table_nsi (fragtext, fragtext2) 
	select replicate(char(round(rand()*100,0)),round(rand()*100,0)),  replicate(char(round(rand()*100,0)),round(rand()*100,0))
	from fragmented_table_nsi
set @x = @x + 1
end
go

--Add needle to haystack
insert into fragmented_table_nsi (fragtext, fragtext2) values ('aaa','bbb')

select count(1) from dbo.fragmented_table_nsi

