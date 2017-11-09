
USE [WideWorldImporters]
GO

----------------

SELECT 
    c.CustomerName, c.PhoneNumber, cc.CustomerCategoryName
FROM 
[Sales].[Customers] c
inner join sales.CustomerCategories cc
on cc.CustomerCategoryID = c.CustomerCategoryID
where c.CreditLimit > 1000






/*

CREATE NONCLUSTERED INDEX IDX_NC_Customers_CreditLimit ON [WideWorldImporters].[Sales].[Customers] ([CreditLimit]) INCLUDE ([CustomerName], [CustomerCategoryID], [DeliveryCityID], [PhoneNumber])

*/

/*

DROP INDEX IDX_NC_Customers_CreditLimit ON [WideWorldImporters].[Sales].[Customers] 
*/