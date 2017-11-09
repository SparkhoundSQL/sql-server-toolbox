Use WideworldImporters

go

--fill haystack
insert into sales.invoicelines (InvoiceLineID, InvoiceID, StockItemID, Description, PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen)
select InvoiceLineID= NEXT VALUE FOR [Sequences].[InvoiceLineID], InvoiceID, StockItemID, Description, PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen
 from sales.invoicelines
GO 3 --run previous two batches to fill table with lots of rows

--half the table has records for InvoiceID 69776
insert into sales.invoicelines (InvoiceLineID, InvoiceID, StockItemID, Description, PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen)
select InvoiceLineID= NEXT VALUE FOR [Sequences].[InvoiceLineID], 69776, StockItemID, Description, PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen
  from sales.invoicelines
 go 
 
select count(1) from sales.InvoiceLines (NOLOCK) --should be millions (3652240)
select count(1) from sales.InvoiceLines where InvoiceID = 69776 --should be half the table (1826160)
 select count(1) from sales.InvoiceLines where InvoiceID = 1 --should be only a few (8)

 
dbcc dropcleanbuffers
dbcc freeproccache
go
DROP INDEX IF EXISTS [NCCX_Sales_InvoiceLines]  ON [Sales].[InvoiceLines]
GO
DROP INDEX IF EXISTS IDX_NC_InvoiceLines_InvoiceID_StockItemID_Quantity ON [Sales].[InvoiceLines] 
GO
DROP INDEX IF EXISTS IDX_CS_InvoiceLines_InvoiceID_StockItemID_quantity ON [Sales].[InvoiceLines] 
GO

CREATE INDEX IDX_NC_InvoiceLines_InvoiceID_StockItemID_Quantity
ON [Sales].[InvoiceLines] (InvoiceID, StockItemID, Quantity)
GO
set statistics time on 
print '-------seek with nc'
SELECT il.StockItemID, AvgQuantity = avg(il.quantity)
FROM [Sales].[InvoiceLines] as il
WHERE il.InvoiceID = 1 --8 rows
group by il.StockItemID
set statistics time off
/*
-------seek with nc

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
   */
GO
set statistics time on 
print '-------scan with nc'
SELECT il.StockItemID, AvgQuantity = avg(il.quantity)
FROM [Sales].[InvoiceLines] as il
WHERE il.InvoiceID = 69776
group by il.StockItemID
set statistics time off
/*
 SQL Server Execution Times:
   CPU time = 579 ms,  elapsed time = 81 ms.
   */
GO
DROP INDEX IF EXISTS IDX_NC_InvoiceLines_InvoiceID_StockItemID_Quantity ON [Sales].[InvoiceLines] 
GO
dbcc dropcleanbuffers
dbcc freeproccache
go
CREATE COLUMNSTORE INDEX IDX_CS_InvoiceLines_InvoiceID_StockItemID_quantity
ON [Sales].[InvoiceLines] (InvoiceID, StockItemID, Quantity)
GO
set statistics time on 
print '-------seek without NC'
SELECT il.StockItemID, AvgQuantity = avg(il.quantity)
FROM [Sales].[InvoiceLines] as il
WHERE il.InvoiceID = 1 --8 rows
group by il.StockItemID
set statistics time off
/*

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 27 ms.
   */
GO
set statistics time on 
print '-------scan with CS'
SELECT il.StockItemID, AvgQuantity = avg(il.quantity)
FROM [Sales].[InvoiceLines] as il
WHERE il.InvoiceID = 69776
group by il.StockItemID
set statistics time off
/*

 SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 189 ms.
   */
GO

dbcc dropcleanbuffers
dbcc freeproccache
go
CREATE INDEX IDX_NC_InvoiceLines_InvoiceID_StockItemID_Quantity
ON [Sales].[InvoiceLines] (InvoiceID, StockItemID, Quantity)
GO

set statistics time on 
print '-------seek with nc'
SELECT il.StockItemID, AvgQuantity = avg(il.quantity)
FROM [Sales].[InvoiceLines] as il
WHERE il.InvoiceID = 1 --4 rows
group by il.StockItemID
set statistics time off
/* 
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
   */
GO
set statistics time on 
print '-------scan with CS'
SELECT il.StockItemID, AvgQuantity = avg(il.quantity)
FROM [Sales].[InvoiceLines] as il
WHERE il.InvoiceID = 69776
group by il.StockItemID
set statistics time off
/*

 SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 378 ms.
   */
GO
DROP INDEX IF EXISTS IDX_CS_InvoiceLines_InvoiceID_StockItemID_quantity ON [Sales].[InvoiceLines] 
GO
DROP INDEX IF EXISTS IDX_NC_InvoiceLines_InvoiceID_StockItemID_Quantity ON [Sales].[InvoiceLines] 
GO




/* Memory-Optimized table with columnstore */

dbcc dropcleanbuffers
dbcc freeproccache
go
DROP TABLE IF EXISTS [Sales].invoicelines_memopt
GO
CREATE TABLE [Sales].invoicelines_memopt (
	[InvoiceLineID] [int] NOT NULL,
	[InvoiceID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[TaxAmount] [decimal](18, 2) NOT NULL,
	[LineProfit] [decimal](18, 2) NOT NULL,
	[ExtendedPrice] [decimal](18, 2) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
	INDEX IDX_CS_invoicelines_memopt_InvoiceID_StockItemID_quantity CLUSTERED COLUMNSTORE, --SQL2017+ only
	CONSTRAINT [invoicelines_memopt_primaryKey]  PRIMARY KEY NONCLUSTERED HASH ([InvoiceLineID] )	WITH ( BUCKET_COUNT = 3652240),
	INDEX IDX_Hash_invoicelines_memopt NONCLUSTERED HASH (InvoiceID, StockItemID, Quantity) WITH ( BUCKET_COUNT = 3652240)
) WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )
GO
INSERT INTO [Sales].invoicelines_memopt
SELECT * FROM [Sales].invoicelines
GO

set statistics time on 
print '-------seek with Mem Opt CS'
SELECT il.StockItemID, AvgQuantity = avg(il.quantity)
FROM [Sales].invoicelines_memopt as il  
WHERE il.InvoiceID = 1 --4 rows
group by il.StockItemID
set statistics time off
/*
 SQL Server Execution Times:
   CPU time = 234 ms,  elapsed time = 233 ms.
   after caching
   CPU time = 16 ms,  elapsed time = 12 ms.
   */
GO
set statistics time on 
print '-------scan with Mem Opt'
SELECT il.StockItemID, AvgQuantity = avg(il.quantity)
FROM [Sales].invoicelines_memopt as il
WHERE il.InvoiceID = 69776
group by il.StockItemID
set statistics time off
GO
/*
 SQL Server Execution Times:
   CPU time = 328 ms,  elapsed time = 352 ms.
   after caching:
   CPU time = 31 ms,  elapsed time = 22 ms.

   */
DROP TABLE IF EXISTS [Sales].invoicelines_memopt
GO