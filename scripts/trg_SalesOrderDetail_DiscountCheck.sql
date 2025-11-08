-- =====================================================================
-- File: trg_SalesOrderDetail_DiscountCheck.sql
-- =====================================================================

USE AdventureWorks2022;
GO

IF OBJECT_ID('Sales.trg_SalesOrderDetail_DiscountCheck', 'TR') IS NOT NULL
    DROP TRIGGER Sales.trg_SalesOrderDetail_DiscountCheck;
GO

CREATE TRIGGER Sales.trg_SalesOrderDetail_DiscountCheck
ON Sales.SalesOrderDetail
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Count INT = 0;

    -- Capture unauthorized discount rows into a temp table
    DECLARE @Violations TABLE
    (
        SalesOrderID INT,
        SalesPersonID INT,
        AttemptedDiscount DECIMAL(5,2)
    );

    INSERT INTO @Violations (SalesOrderID, SalesPersonID, AttemptedDiscount)
    SELECT
        i.SalesOrderID,
        h.SalesPersonID,
        i.UnitPriceDiscount
    FROM inserted AS i
    INNER JOIN Sales.SalesOrderHeader AS h ON i.SalesOrderID = h.SalesOrderID
    INNER JOIN HumanResources.Employee AS e ON h.SalesPersonID = e.BusinessEntityID
    WHERE i.UnitPriceDiscount > 0.30
      AND e.JobTitle <> 'Sales Manager';

    SELECT @Count = COUNT(*) FROM @Violations;

    IF @Count > 0
    BEGIN
        -- Insert violations separately (outside the main transaction)
        INSERT INTO Automation.DiscountViolationLog
        (SalesOrderID, SalesPersonID, ViolationMessage, AttemptedDiscount, CreatedDate)
        SELECT
            v.SalesOrderID,
            v.SalesPersonID,
            'Unauthorized discount greater than 30% detected.',
            v.AttemptedDiscount,
            GETDATE()
        FROM @Violations v;

        -- Throw error to rollback only the sales insert/update
        THROW 51000, 
            'Discount exceeds 30% and salesperson is not authorized. Transaction rolled back.', 
            1;
    END
END;
GO

PRINT 'Trigger [Sales.trg_SalesOrderDetail_DiscountCheck] successfully.';
