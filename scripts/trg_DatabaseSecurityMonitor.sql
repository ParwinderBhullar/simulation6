USE AdventureWorks2022;
GO
IF OBJECT_ID('trg_DatabaseSecurityMonitor','TR') IS NOT NULL
    DROP TRIGGER trg_DatabaseSecurityMonitor ON DATABASE;
GO

CREATE TRIGGER trg_DatabaseSecurityMonitor
ON DATABASE
FOR ALTER_TABLE, DROP_TABLE, ALTER_PROCEDURE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Event XML = EVENTDATA();

    INSERT INTO Automation.DatabaseEventLog
    (EventType, ObjectName, CommandText, PerformedBy, LoggedDate)
    VALUES (
        @Event.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @Event.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(255)'),
        @Event.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)'),
        SUSER_SNAME(),
        GETDATE()
    );
END;
GO
PRINT 'DDL Trigger [trg_DatabaseSecurityMonitor] created successfully.';
