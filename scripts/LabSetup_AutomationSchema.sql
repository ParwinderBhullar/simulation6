-- ================================================================
-- File: LabSetup_AutomationSchema.sql
-- Database: AdventureWorks2022
-- Description: Creates Automation schema and logging/audit tables
-- ================================================================

USE AdventureWorks2022;
GO

-- 1. Create Schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Automation')
BEGIN
    EXEC('CREATE SCHEMA Automation AUTHORIZATION dbo;');
    PRINT 'Schema "Automation" created successfully.';
END
ELSE
    PRINT 'Schema "Automation" already exists.';
GO

-- 2. Create Product Price Audit table
IF OBJECT_ID('Automation.ProductPriceAudit', 'U') IS NULL
BEGIN
    CREATE TABLE Automation.ProductPriceAudit (
        AuditID INT IDENTITY(1,1) PRIMARY KEY,
        ProductID INT NOT NULL,
        OldPrice MONEY,
        NewPrice MONEY,
        ModifiedBy NVARCHAR(100),
        ModifiedDate DATETIME DEFAULT GETDATE()
    );
    PRINT 'Automation.ProductPriceAudit created.';
END
GO

-- 3. Create Discount Violation Log
IF OBJECT_ID('Automation.DiscountViolationLog', 'U') IS NULL
BEGIN
    CREATE TABLE Automation.DiscountViolationLog (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        SalesOrderID INT NULL,
        SalesPersonID INT NULL,
        ViolationMessage NVARCHAR(255),
        AttemptedDiscount DECIMAL(5,2),
        CreatedDate DATETIME DEFAULT GETDATE()
    );
    PRINT 'Automation.DiscountViolationLog created.';
END
GO

-- 4. Create Inventory Alert Log
IF OBJECT_ID('Automation.InventoryAlertLog', 'U') IS NULL
BEGIN
    CREATE TABLE Automation.InventoryAlertLog (
        AlertID INT IDENTITY(1,1) PRIMARY KEY,
        ProductID INT NOT NULL,
        LocationID INT NULL,
        CurrentQuantity INT,
        ReorderPoint INT,
        AlertMessage NVARCHAR(255),
        LoggedDate DATETIME DEFAULT GETDATE()
    );
    PRINT 'Automation.InventoryAlertLog created.';
END
GO

-- 5. Create Termination Audit
IF OBJECT_ID('Automation.TerminationAudit', 'U') IS NULL
BEGIN
    CREATE TABLE Automation.TerminationAudit (
        AuditID INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeID INT NOT NULL,
        TerminationDate DATETIME DEFAULT GETDATE(),
        TerminatedBy NVARCHAR(100),
        Reason NVARCHAR(255)
    );
    PRINT 'Automation.TerminationAudit created.';
END
GO

-- 6. Create Database Event Log
IF OBJECT_ID('Automation.DatabaseEventLog', 'U') IS NULL
BEGIN
    CREATE TABLE Automation.DatabaseEventLog (
        EventLogID INT IDENTITY(1,1) PRIMARY KEY,
        EventType NVARCHAR(100),
        ObjectName NVARCHAR(255),
        CommandText NVARCHAR(MAX),
        PerformedBy NVARCHAR(100),
        LoggedDate DATETIME DEFAULT GETDATE()
    );
    PRINT 'Automation.DatabaseEventLog created.';
END
GO

-- 7.Create Order Error Log (used in Task 3)
IF OBJECT_ID('Automation.OrderErrorLog', 'U') IS NULL
BEGIN
    CREATE TABLE Automation.OrderErrorLog (
        ErrorID INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderID INT NULL,
        ErrorMessage NVARCHAR(255),
        LoggedDate DATETIME DEFAULT GETDATE()
    );
    PRINT 'Automation.OrderErrorLog created.';
END
GO

-- 8.Create Price Review Queue (used in Task 4)
IF OBJECT_ID('Automation.PriceReviewQueue', 'U') IS NULL
BEGIN
    CREATE TABLE Automation.PriceReviewQueue (
        QueueID INT IDENTITY(1,1) PRIMARY KEY,
        ProductID INT,
        OldPrice MONEY,
        NewPrice MONEY,
        ChangedBy NVARCHAR(100),
        ChangeDate DATETIME DEFAULT GETDATE(),
        ReviewStatus NVARCHAR(50) DEFAULT 'Pending'
    );
    PRINT 'Automation.PriceReviewQueue created.';
END
GO

-- 9.Employee Archive (used in Task 6)
IF OBJECT_ID('Automation.EmployeeArchive', 'U') IS NULL
BEGIN
    CREATE TABLE Automation.EmployeeArchive (
        EmployeeID INT,
        NationalIDNumber NVARCHAR(15),
        LoginID NVARCHAR(256),
        JobTitle NVARCHAR(50),
        BirthDate DATE,
        MaritalStatus NCHAR(1),
        Gender NCHAR(1),
        HireDate DATE,
        ModifiedDate DATETIME DEFAULT GETDATE()
    );
    PRINT 'Automation.EmployeeArchive created.';
END
GO



