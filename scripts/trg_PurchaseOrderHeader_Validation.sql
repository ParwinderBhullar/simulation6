USE AdventureWorks2022;
GO
IF OBJECT_ID('Purchasing.trg_PurchaseOrderHeader_Validation','TR') IS NOT NULL
    DROP TRIGGER Purchasing.trg_PurchaseOrderHeader_Validation;
GO

CREATE TRIGGER Purchasing.trg_PurchaseOrderHeader_Validation
ON Purchasing.PurchaseOrderHeader
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- copy inserted rows to a temp table visible to dynamic SQL
    DECLARE @tmp TABLE
    (
        PurchaseOrderID INT,
        OrderDate DATE,
        Freight MONEY,
        TaxAmt MONEY
    );

    INSERT INTO @tmp (PurchaseOrderID, OrderDate, Freight, TaxAmt)
    SELECT PurchaseOrderID, OrderDate, Freight, TaxAmt FROM inserted;

    IF EXISTS (
        SELECT 1 FROM @tmp
        WHERE (OrderDate > GETDATE())
           OR (Freight <= 0)
           OR (TaxAmt <= 0)
    )
    BEGIN
        -- write the bad rows to the log table (autocommit)
        INSERT INTO Automation.OrderErrorLog (PurchaseOrderID, ErrorMessage, LoggedDate)
        SELECT 
            t.PurchaseOrderID,
            CASE 
                WHEN t.OrderDate > GETDATE() THEN N'Invalid OrderDate (future date).'
                WHEN t.Freight <= 0 THEN N'Freight must be greater than zero.'
                WHEN t.TaxAmt <= 0 THEN N'TaxAmt must be greater than zero.'
                ELSE N'Unknown validation error.'
            END,
            GETDATE()
        FROM @tmp AS t
        WHERE (t.OrderDate > GETDATE())
           OR (t.Freight <= 0)
           OR (t.TaxAmt <= 0);

        -- cancel the invalid insert
        THROW 52000, 'Purchase order validation failed. Insert cancelled and error logged.', 1;
    END
    ELSE
    BEGIN
        -- valid data → perform real insert
        INSERT INTO Purchasing.PurchaseOrderHeader
        (RevisionNumber, Status, EmployeeID, VendorID, ShipMethodID, OrderDate,
         ShipDate, SubTotal, TaxAmt, Freight, ModifiedDate)
        SELECT 
            i.RevisionNumber, i.Status, i.EmployeeID, i.VendorID, i.ShipMethodID,
            i.OrderDate, i.ShipDate, i.SubTotal, i.TaxAmt, i.Freight, GETDATE()
        FROM inserted AS i;
    END
END;
GO
PRINT 'Trigger [Purchasing.trg_PurchaseOrderHeader_Validation] created successfully.';
