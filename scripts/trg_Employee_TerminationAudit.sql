USE AdventureWorks2022;
GO
IF OBJECT_ID('HumanResources.trg_Employee_TerminationAudit','TR') IS NOT NULL
    DROP TRIGGER HumanResources.trg_Employee_TerminationAudit;
GO

CREATE TRIGGER HumanResources.trg_Employee_TerminationAudit
ON HumanResources.Employee
FOR DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Prevent deletion if employee has active department history
    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN HumanResources.EmployeeDepartmentHistory h
             ON d.BusinessEntityID = h.BusinessEntityID
        WHERE h.EndDate IS NULL
    )
    BEGIN
        EXEC('INSERT INTO Automation.TerminationAudit
              (EmployeeID, TerminatedBy, Reason)
              SELECT d.BusinessEntityID, SUSER_SNAME(),
                     N''Deletion prevented: active department assignment.''
              FROM deleted d;');
        THROW 54000, 'Employee has active department assignment. Deletion cancelled.', 1;
    END
    ELSE
    BEGIN
        INSERT INTO Automation.EmployeeArchive
        (EmployeeID, NationalIDNumber, LoginID, JobTitle,
         BirthDate, MaritalStatus, Gender, HireDate)
        SELECT BusinessEntityID, NationalIDNumber, LoginID, JobTitle,
               BirthDate, MaritalStatus, Gender, HireDate
        FROM deleted;

        INSERT INTO Automation.TerminationAudit
        (EmployeeID, TerminationDate, TerminatedBy, Reason)
        SELECT d.BusinessEntityID, GETDATE(), SUSER_SNAME(),
               'Employee record deleted.'
        FROM deleted d;
    END
END;
GO
PRINT 'Trigger [HumanResources.trg_Employee_TerminationAudit] created successfully.';
