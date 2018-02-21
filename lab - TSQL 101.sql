DROP TABLE IF EXISTS dbo.SomeTable
GO
CREATE TABLE dbo.SomeTable
(	ID int IDENTITY(1,1) CONSTRAINT PK_SomeTable PRIMARY KEY 
,	SomeNumber decimal(9,2) not null
,	SomeWords varchar(50) not null
)
GO
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (1, 'abc')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (2, 'abc')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (3, 'abc')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (4, 'abc')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (5, 'abc')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (1, 'def')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (2, 'def')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (3, 'def')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (4, 'def')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (5, 'def')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (1, 'ghi')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (2, 'ghi')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (3, 'ghi')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (4, 'ghi')
INSERT INTO dbo.SomeTable (SomeNumber, SomeWords) VALUES (5, 'ghi')
go
SELECT * FROM dbo.SomeTable
GO
DROP TABLE IF EXISTS dbo.SomeTable2
GO
CREATE TABLE dbo.SomeTable2
(	ID int IDENTITY(1,1) CONSTRAINT PK_SomeTable2 PRIMARY KEY 
,	SomeNumber decimal(9,2) not null
,	SomeDate date not null
)
GO
INSERT INTO dbo.SomeTable2 (SomeNumber, SomeDate) VALUES (3, '2018-03-01')
INSERT INTO dbo.SomeTable2 (SomeNumber, SomeDate) VALUES (4, '2018-04-01')
INSERT INTO dbo.SomeTable2 (SomeNumber, SomeDate) VALUES (5, '2018-05-01')
INSERT INTO dbo.SomeTable2 (SomeNumber, SomeDate) VALUES (6, '2018-06-01')
INSERT INTO dbo.SomeTable2 (SomeNumber, SomeDate) VALUES (7, '2018-07-01')

go
SELECT * FROM dbo.SomeTable2
GO
--Works
SELECT * --Not best practice
FROM SomeTable  --Every table has a schema
WHERE SomeNumber > 2 --semicolon please

--Better
SELECT ID, SomeNumber, SomeWords 
FROM dbo.SomeTable  
WHERE SomeNumber > 2 

SELECT SomeWords
FROM dbo.SomeTable  
WHERE SomeWords like 'a%'
--WHERE LEFT(SomeWords, 1) = 'a'

--Works
SELECT SomeTable.SomeNumber, SomeWords, SomeDate
FROM dbo.SomeTable --No tables aliases, poor readability of code
INNER JOIN dbo.SomeTable2
ON SomeTable.SomeNumber = SomeTable2.SomeNumber 
ORDER BY SomeTable.SomeNumber; --Order by may not make business sense

--Better
SELECT t1.SomeNumber, t1.SomeWords, t2.SomeDate
FROM dbo.SomeTable AS t1
INNER JOIN dbo.SomeTable2 AS t2
ON t1.SomeNumber = t2.SomeNumber 
ORDER BY t1.SomeNumber, t1.SomeWords, t2.SomeDate;







