-- ===============================================================
-- File: Transaction_Optimized_Triggers.sql
-- Student: Yuvraj Singh (N01716961)
-- Course: SQL Server Development
-- Database: AdventureWorks2022
-- Description:
-- Optimized versions of all DML triggers with transaction safety,
-- TRY...CATCH error handling, and recursion prevention.
-- ===============================================================

USE AdventureWorks2022;
GO

/* ================================================================
   TASK 2 – Discount Validation Trigger (Sales Module)
================================================================ */
IF OBJECT_ID('Sales.trg_SalesOrderDetail_DiscountCheck','TR') IS NOT NULL
    DROP TRIGGER Sales.trg_SalesOrderDetail_DiscountCheck;
GO
CREATE TRIGGER Sales.trg_SalesOrderDetail_DiscountCheck
ON Sales.SalesOrderDetail
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    BEGIN TRY
        BEGIN TRAN;

        -- Validate discounts >30% for non–Sales Managers
        DECLARE @ViolationCount INT = 0;
        DECLARE @Temp TABLE(SalesOrderID INT, SalesPersonID INT, AttemptedDiscount DECIMAL(5,2));

        INSERT INTO @Temp
        SELECT i.SalesOrderID, h.SalesPersonID, i.UnitPriceDiscount
        FROM inserted i
        JOIN Sales.SalesOrderHeader h ON i.SalesOrderID = h.SalesOrderID
        JOIN HumanResources.Employee e ON h.SalesPersonID = e.BusinessEntityID
        WHERE i.UnitPriceDiscount > 0.30 AND e.JobTitle <> 'Sales Manager';

        SELECT @ViolationCount = COUNT(*) FROM @Temp;

        IF @ViolationCount > 0
        BEGIN
            INSERT INTO Automation.DiscountViolationLog
            (SalesOrderID, SalesPersonID, ViolationMessage, AttemptedDiscount, CreatedDate)
            SELECT SalesOrderID, SalesPersonID,
                   'Unauthorized discount greater than 30% detected.', AttemptedDiscount, GETDATE()
            FROM @Temp;

            THROW 51000, 'Discount exceeds 30% and salesperson not authorized.', 1;
        END

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END;
GO

/* ================================================================
   TASK 3 – Purchase Order Validation (Purchasing Module)
================================================================ */
IF OBJECT_ID('Purchasing.trg_PurchaseOrderHeader_Validation','TR') IS NOT NULL
    DROP TRIGGER Purchasing.trg_PurchaseOrderHeader_Validation;
GO
CREATE TRIGGER Purchasing.trg_PurchaseOrderHeader_Validation
ON Purchasing.PurchaseOrderHeader
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    BEGIN TRY
        BEGIN TRAN;

        IF EXISTS (
            SELECT 1 FROM inserted
            WHERE OrderDate > GETDATE() OR Freight <= 0 OR TaxAmt <= 0
        )
        BEGIN
            INSERT INTO Automation.OrderErrorLog(PurchaseOrderID, ErrorMessage, LoggedDate)
            SELECT i.PurchaseOrderID,
                   CASE
                       WHEN i.OrderDate > GETDATE() THEN 'OrderDate in future.'
                       WHEN i.Freight <= 0 THEN 'Freight must be >0.'
                       WHEN i.TaxAmt <= 0 THEN 'TaxAmt must be >0.'
                       ELSE 'Validation failed.'
                   END, GETDATE()
            FROM inserted i;
            THROW 52000, 'Purchase order validation failed.', 1;
        END
        ELSE
        BEGIN
            INSERT INTO Purchasing.PurchaseOrderHeader
            (RevisionNumber, Status, EmployeeID, VendorID, ShipMethodID, OrderDate,
             ShipDate, SubTotal, TaxAmt, Freight, ModifiedDate)
            SELECT i.RevisionNumber, i.Status, i.EmployeeID, i.VendorID, i.ShipMethodID,
                   i.OrderDate, i.ShipDate, i.SubTotal, i.TaxAmt, i.Freight, GETDATE()
            FROM inserted i;
        END

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END;
GO

/* ================================================================
   TASK 4 – Product Price Audit and Review (Production Module)
================================================================ */
IF OBJECT_ID('Production.trg_Product_PriceAudit','TR') IS NOT NULL
    DROP TRIGGER Production.trg_Product_PriceAudit;
GO
CREATE TRIGGER Production.trg_Product_PriceAudit
ON Production.Product
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    BEGIN TRY
        BEGIN TRAN;

        IF UPDATE(ListPrice)
        BEGIN
            INSERT INTO Automation.ProductPriceAudit
            (ProductID, OldPrice, NewPrice, ModifiedBy, ModifiedDate)
            SELECT d.ProductID, d.ListPrice, i.ListPrice, SUSER_SNAME(), GETDATE()
            FROM deleted d JOIN inserted i ON d.ProductID = i.ProductID
            WHERE d.ListPrice <> i.ListPrice;

            INSERT INTO Automation.PriceReviewQueue
            (ProductID, OldPrice, NewPrice, ChangedBy, ChangeDate)
            SELECT d.ProductID, d.ListPrice, i.ListPrice, SUSER_SNAME(), GETDATE()
            FROM deleted d JOIN inserted i ON d.ProductID = i.ProductID
            WHERE i.ListPrice < d.ListPrice * 0.8;
        END

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        RAISERROR(ERROR_MESSAGE(),16,1);
    END CATCH
END;
GO

/* ================================================================
   TASK 5 – Inventory Synchronization (Sales & Production Modules)
================================================================ */
IF OBJECT_ID('Sales.trg_SalesOrderDetail_InventorySync','TR') IS NOT NULL
    DROP TRIGGER Sales.trg_SalesOrderDetail_InventorySync;
GO
CREATE TRIGGER Sales.trg_SalesOrderDetail_InventorySync
ON Sales.SalesOrderDetail
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    BEGIN TRY
        BEGIN TRAN;

        -- Check stock
        IF EXISTS (
            SELECT 1 FROM inserted i
            JOIN Production.ProductInventory pi ON i.ProductID = pi.ProductID
            WHERE i.OrderQty > pi.Quantity
        )
        BEGIN
            INSERT INTO Automation.InventoryAlertLog(ProductID, AlertMessage, LoggedDate)
            SELECT ProductID, 'Order quantity exceeds available stock.', GETDATE() FROM inserted;
            THROW 53000, 'Inventory transaction failed: insufficient stock.', 1;
        END

        -- Deduct quantity
        UPDATE pi
        SET pi.Quantity = pi.Quantity - i.OrderQty
        FROM Production.ProductInventory pi
        JOIN inserted i ON pi.ProductID = i.ProductID;

        -- Log low stock
        INSERT INTO Automation.InventoryAlertLog
        (ProductID, LocationID, CurrentQuantity, ReorderPoint, AlertMessage, LoggedDate)
        SELECT pi.ProductID, pi.LocationID, pi.Quantity, p.ReorderPoint,
               'Stock below reorder point.', GETDATE()
        FROM Production.ProductInventory pi
        JOIN Production.Product p ON pi.ProductID = p.ProductID
        WHERE pi.Quantity < p.ReorderPoint;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        RAISERROR(ERROR_MESSAGE(),16,1);
    END CATCH
END;
GO

/* ================================================================
   TASK 6 – Employee Archive and Termination Audit (HR Module)
================================================================ */
IF OBJECT_ID('HumanResources.trg_Employee_TerminationAudit','TR') IS NOT NULL
    DROP TRIGGER HumanResources.trg_Employee_TerminationAudit;
GO
CREATE TRIGGER HumanResources.trg_Employee_TerminationAudit
ON HumanResources.Employee
FOR DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    BEGIN TRY
        BEGIN TRAN;

        IF EXISTS (
            SELECT 1 FROM deleted d
            JOIN HumanResources.EmployeeDepartmentHistory h
                ON d.BusinessEntityID = h.BusinessEntityID
            WHERE h.EndDate IS NULL
        )
        BEGIN
            INSERT INTO Automation.TerminationAudit
            (EmployeeID, TerminatedBy, Reason)
            SELECT d.BusinessEntityID, SUSER_SNAME(),
                   'Deletion prevented: active department assignment.'
            FROM deleted d;
            THROW 54000, 'Employee has active assignment. Deletion cancelled.', 1;
        END
        ELSE
        BEGIN
            INSERT INTO Automation.EmployeeArchive
            (EmployeeID, NationalIDNumber, LoginID, JobTitle, BirthDate,
             MaritalStatus, Gender, HireDate, ModifiedDate)
            SELECT BusinessEntityID, NationalIDNumber, LoginID, JobTitle, BirthDate,
                   MaritalStatus, Gender, HireDate, GETDATE()
            FROM deleted;

            INSERT INTO Automation.TerminationAudit
            (EmployeeID, TerminationDate, TerminatedBy, Reason)
            SELECT BusinessEntityID, GETDATE(), SUSER_SNAME(), 'Employee record deleted.'
            FROM deleted;
        END

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        RAISERROR(ERROR_MESSAGE(),16,1);
    END CATCH
END;
GO

PRINT 'All DML triggers optimized with transaction handling and error control.';
