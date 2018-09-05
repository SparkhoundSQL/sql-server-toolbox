use w
go

--RUN ENTIRE SCRIPT
DROP TABLE IF EXISTS dbo.fragmented_table_int
go
CREATE TABLE dbo.fragmented_table_int
	(
	fragid int NOT NULL IDENTITY(1,1),
	fragtext varchar(4000) NOT NULL
	)  
GO
ALTER TABLE dbo.fragmented_table_int ADD CONSTRAINT
	PK_fragmented_table_int PRIMARY KEY CLUSTERED 
	(
	fragid
	) WITH(FILLFACTOR =100)
go
CREATE NONCLUSTERED INDEX IDX_NC_fragmented_table_int
ON dbo.fragmented_table_int (FRAGTEXT) WITH(FILLFACTOR =100)
GO


--Insert roughly 131072k records

	insert into dbo.fragmented_table_int (fragtext) 
	select replicate(char(round(rand()*100,0)),round(rand()*100,0))
go
declare @x integer
set @x = 1 
while @x < 18
begin
	insert into dbo.fragmented_table_int (fragtext) 
	select replicate(char(round(rand()*100,0)),round(rand()*100,0))
	from fragmented_table_int
set @x = @x + 1
end
go
select count(1) from dbo.fragmented_table_int




