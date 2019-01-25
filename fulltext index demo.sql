drop table if exists dbo.fttest
go
create table dbo.fttest
(id int identity(1,1) not null constraint pk_fftest primary key
, text1 varchar(2000) 
, dateinserted datetimeoffset(2) not null constraint df_fttest_dateinserted default (sysdatetimeoffset()) 
)
insert into dbo.fttest (Text1) values ( REPLICATE (CHAR((rand()*64)+64), FLOOR(RAND()*2000)))
go
insert into dbo.fttest (Text1) 
select ( REPLICATE (CHAR((rand()*64)+64), FLOOR(RAND()*2000))) from fttest
go 14

select count(1) from  fttest
GO

IF EXISTS (  SELECT *    FROM sys.fulltext_catalogs   WHERE name = N'ft_cat')
	DROP FULLTEXT CATALOG ft_cat
GO
 
CREATE FULLTEXT CATALOG ft_cat
GO
CREATE FULLTEXT INDEX ON dbo.fttest (text1) 
	KEY INDEX pk_fftest
	ON ft_cat
	WITH (CHANGE_TRACKING = AUTO, STOPLIST = SYSTEM)
GO


--use fulltext index status.sql to observe. Wait for it to get caught up.

INSERT INTO dbo.fttest (Text1) 
SELECT ( REPLICATE (CHAR((rand()*64)+64), FLOOR(RAND()*2000))) from fttest
GO --insert a ton of rows and get the fulltext catalog "behind"
DELETE FROM fttest where text1 = 'whatever';
GO
INSERT INTO dbo.fttest (Text1) OUTPUT inserted.dateinserted select 'whatever' --insert needle in haystack
GO
SELECT sysdatetimeoffset(), * from dbo.fttest t where text1 = 'whatever'
SELECT sysdatetimeoffset(), * from dbo.fttest t where CONTAINS (Text1, '"whatever"');
GO
WHILE NOT EXISTS (select text1 from dbo.fttest t where CONTAINS (Text1, '"whatever"'))
BEGIN
	WAITFOR DELAY '00:00:01' --1s
	print 'waiting 1s';
	IF EXISTS (select text1 from dbo.fttest t where CONTAINS (Text1, '"whatever"'))
	BEGIN
		--Wait for haystack to show up in the FT index. Might be a while!!
		select Found = sysdatetimeoffset(), * from dbo.fttest t where CONTAINS (Text1, '"whatever"');
		BREAK;
	END
	ELSE
		CONTINUE;
END
GO