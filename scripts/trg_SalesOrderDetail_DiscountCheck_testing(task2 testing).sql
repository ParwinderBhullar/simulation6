
INSERT INTO Sales.SalesOrderDetail
(SalesOrderID, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
VALUES (43659,1,707,1,1000,0.50,NEWID(),GETDATE());


SELECT * FROM Automation.DiscountViolationLog ORDER BY CreatedDate DESC;














SELECT SalesOrderID, SalesPersonID
FROM Sales.SalesOrderHeader
WHERE SalesPersonID IS NOT NULL;

SELECT e.BusinessEntityID, e.JobTitle
FROM HumanResources.Employee e
WHERE e.BusinessEntityID = 46977;


SELECT i.SalesOrderID, h.SalesPersonID, e.JobTitle, i.UnitPriceDiscount
FROM Sales.SalesOrderDetail AS i
INNER JOIN Sales.SalesOrderHeader AS h ON i.SalesOrderID = h.SalesOrderID
INNER JOIN HumanResources.Employee AS e ON h.SalesPersonID = e.BusinessEntityID
WHERE i.UnitPriceDiscount > 0.30;

