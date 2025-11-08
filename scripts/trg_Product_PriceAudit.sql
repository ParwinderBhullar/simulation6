USE AdventureWorks2022;
GO
IF OBJECT_ID('Production.trg_Product_PriceAudit','TR') IS NOT NULL
    DROP TRIGGER Production.trg_Product_PriceAudit;
GO

CREATE TRIGGER Production.trg_Product_PriceAudit
ON Production.Product
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(ListPrice)
    BEGIN
        INSERT INTO Automation.ProductPriceAudit
        (ProductID, OldPrice, NewPrice, ModifiedBy, ModifiedDate)
        SELECT
            d.ProductID,
            d.ListPrice AS OldPrice,
            i.ListPrice AS NewPrice,
            SUSER_SNAME(),
            GETDATE()
        FROM deleted d
        JOIN inserted i ON d.ProductID = i.ProductID
        WHERE d.ListPrice <> i.ListPrice;

        -- If price decrease > 20 % → add to review queue
        INSERT INTO Automation.PriceReviewQueue
        (ProductID, OldPrice, NewPrice, ChangedBy, ChangeDate)
        SELECT
            d.ProductID,
            d.ListPrice,
            i.ListPrice,
            SUSER_SNAME(),
            GETDATE()
        FROM deleted d
        JOIN inserted i ON d.ProductID = i.ProductID
        WHERE i.ListPrice < d.ListPrice * 0.8;
    END
END;
GO
PRINT 'Trigger [Production.trg_Product_PriceAudit] created successfully.';
