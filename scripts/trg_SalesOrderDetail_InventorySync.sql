USE AdventureWorks2022;
GO
IF OBJECT_ID('Sales.trg_SalesOrderDetail_InventorySync','TR') IS NOT NULL
    DROP TRIGGER Sales.trg_SalesOrderDetail_InventorySync;
GO

CREATE TRIGGER Sales.trg_SalesOrderDetail_InventorySync
ON Sales.SalesOrderDetail
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Error BIT = 0;

    -- Check stock levels
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Production.ProductInventory pi ON i.ProductID = pi.ProductID
        WHERE i.OrderQty > pi.Quantity
    )
    BEGIN
        -- Log violation in autocommit context
        EXEC('INSERT INTO Automation.InventoryAlertLog
              (ProductID, AlertMessage, LoggedDate)
              SELECT ProductID,
                     N''Order quantity exceeds available inventory.'',
                     GETDATE()
              FROM inserted;');
        SET @Error = 1;
    END
    ELSE
    BEGIN
        -- Deduct sold qty
        UPDATE pi
        SET pi.Quantity = pi.Quantity - i.OrderQty
        FROM Production.ProductInventory pi
        JOIN inserted i ON pi.ProductID = i.ProductID;

        -- Log low-stock alerts
        INSERT INTO Automation.InventoryAlertLog
        (ProductID, LocationID, CurrentQuantity, ReorderPoint, AlertMessage, LoggedDate)
        SELECT
            pi.ProductID, pi.LocationID, pi.Quantity, p.ReorderPoint,
            'Stock below reorder point.', GETDATE()
        FROM Production.ProductInventory pi
        JOIN Production.Product p ON pi.ProductID = p.ProductID
        WHERE pi.Quantity < p.ReorderPoint;
    END

    IF @Error = 1
        THROW 53000, 'Inventory transaction failed: insufficient stock.', 1;
END;
GO
PRINT 'Trigger [Sales.trg_SalesOrderDetail_InventorySync] created successfully.';
