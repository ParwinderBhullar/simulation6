
INSERT INTO Purchasing.PurchaseOrderHeader
(RevisionNumber,Status,EmployeeID,VendorID,ShipMethodID,OrderDate,ShipDate,SubTotal,TaxAmt,Freight,ModifiedDate)
VALUES (1,1,258,1492,5,DATEADD(DAY,5,GETDATE()),NULL,1000,50,100,GETDATE());

SELECT * FROM Automation.OrderErrorLog ORDER BY LoggedDate DESC;














SELECT * 
FROM Automation.OrderErrorLog
ORDER BY LoggedDate DESC;

SELECT * 
FROM Purchasing.PurchaseOrderHeader
WHERE OrderDate > GETDATE();  -- should return 0 rows
