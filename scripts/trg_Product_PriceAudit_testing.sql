UPDATE Production.Product
SET ListPrice = ListPrice * 0.7   -- 30 % drop
WHERE ProductID = 707;

SELECT * FROM Automation.ProductPriceAudit ORDER BY ModifiedDate DESC;



SELECT * FROM Automation.PriceReviewQueue ORDER BY ChangeDate DESC;
