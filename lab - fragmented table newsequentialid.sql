use w
go

--RUN ENTIRE SCRIPT
DROP TABLE IF EXISTS dbo.fragmented_table_nsi
go
CREATE TABLE dbo.fragmented_table_nsi
	(
	fragid uniqueidentifier NOT NULL DEFAULT newsequentialID(),
	fragtext varchar(4000) NOT NULL
	)  
GO
ALTER TABLE dbo.fragmented_table_nsi ADD CONSTRAINT
	PK_fragmented_table_nsi PRIMARY KEY CLUSTERED 
	(
	fragid
	) WITH(FILLFACTOR = 100) 
go
CREATE NONCLUSTERED INDEX IDX_NC_fragmented_table_nsi
ON dbo.fragmented_table_nsi (FRAGTEXT) WITH(FILLFACTOR =100)
GO


--Insert roughly 131072k records

	insert into dbo.fragmented_table_nsi (fragtext) 
	select replicate(char(round(rand()*100,0)),round(rand()*100,0))
go
declare @x integer
set @x = 1 
while @x < 18
begin
	insert into dbo.fragmented_table_nsi (fragtext) 
	select replicate(char(round(rand()*100,0)),round(rand()*100,0))
	from fragmented_table_nsi
set @x = @x + 1
end
go
select count(1) from dbo.fragmented_table_nsi




