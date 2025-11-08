USE AdventureWorks2022;
GO

--Check for an employee who still has an active department assignment
SELECT 
    e.BusinessEntityID, e.JobTitle, h.DepartmentID, h.EndDate
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory h
    ON e.BusinessEntityID = h.BusinessEntityID
WHERE h.EndDate IS NULL;
GO

DELETE FROM HumanResources.Employee
WHERE BusinessEntityID = 290;
GO

SELECT TOP 5 *
FROM Automation.TerminationAudit
ORDER BY TerminationDate DESC;
GO
