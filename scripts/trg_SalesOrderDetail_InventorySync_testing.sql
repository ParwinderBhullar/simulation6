INSERT INTO Sales.SalesOrderDetail
(SalesOrderID, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
VALUES (43659, 9999, 707, 1, 1000, 0, NEWID(), GETDATE());


SELECT * FROM Automation.InventoryAlertLog ORDER BY LoggedDate DESC;
