# SQL Server Development Lab  
### Advanced Database Programming: Triggers, Events, and Business Rule Enforcement  

**Student:** Parwinder Singh  
**Student ID:** N01730928  
**Database:** AdventureWorks2022  
**Course:** SQL Server Development  

---

## 📂 Repository Structure
/scripts/ → All SQL trigger scripts (Tasks 1–8)
/screenshots/ → Screenshots of trigger execution and results
/report/ → Final TriggerLab_Report.pdf
---

## Lab Overview
This lab demonstrates the use of SQL Server **DML and DDL triggers** to automate data validation, enforce business rules, and maintain audit trails.  
It includes transaction handling, rollback logic, and logging mechanisms across Sales, Purchasing, Production, and HR modules.

---

##  How to Run
1. Restore or attach **AdventureWorks2022** in SQL Server Management Studio.  
2. Run `LabSetup_AutomationSchema.sql` to create the **Automation** schema and log tables.  
3. Execute each trigger creation script inside `/scripts/`.  
4. Use the provided test queries to verify automation, logging, and rollback behaviour.  

---

##  Deliverables
- `scripts/` folder with all `.sql` trigger scripts  
- `report/TriggerLab_Report.pdf`  
- `screenshots/` folder with proof of execution  

---

## Learning Highlights
- Implemented `TRY...CATCH`, transactions, and rollback handling.  
- Used `IF UPDATE()` and recursion prevention for optimization.  
- Logged all validation errors and audit events in the Automation schema.

