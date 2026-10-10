CREATE DATABASE manufacturing_db;
USE manufacturing_db;

SELECT DATABASE();

-- To change data type of doc num 
ALTER TABLE fact_Production
CHANGE COLUMN `ï»¿Doc_Num` `Doc_Num` VARCHAR(30);
DESCRIBE fact_Production;

-- Count rows in table
SELECT COUNT(*) AS total_rows
FROM fact_Production;


USE manufacturing_db;
-- to change column name
ALTER TABLE dim_buyer
RENAME COLUMN `ï»¿Buyer_ID` TO Buyer_ID;

ALTER TABLE dim_customer
RENAME COLUMN `ï»¿Customer_Code` TO Customer_Code;

ALTER TABLE dim_date
RENAME COLUMN `ï»¿Date` TO Date;

ALTER TABLE dim_department
RENAME COLUMN `ï»¿Dept_ID` TO Dept_ID;

ALTER TABLE dim_employee
RENAME COLUMN `ï»¿Employee_Code` TO Employee_Code;

ALTER TABLE dim_item
RENAME COLUMN `ï»¿Item_Code` TO Item_Code;

ALTER TABLE dim_machine
RENAME COLUMN `ï»¿Operation_Code` TO Operation_Code;

ALTER TABLE dim_operation
RENAME COLUMN `ï»¿Operation_Code` TO Operation_Code;


--  Production & Efficiency Dashboard 
-- 6 KPIs

CREATE OR REPLACE VIEW vw_production_kpi AS
SELECT
    SUM(Today_Manufactured_Qty) AS Total_Manufactured_Qty,

    ROUND(
        SUM(Produced_Qty) / NULLIF(SUM(Processed_Qty), 0) * 100,
        2
    ) AS Efficiency_Rate_Pct,

    ROUND(
        SUM(Processed_Qty) / NULLIF(SUM(WO_Qty), 0) * 100,
        2
    ) AS Machine_Utilization_Pct,

    ROUND(
        SUM(Total_Value) / NULLIF(SUM(Produced_Qty), 0),
        2
    ) AS Cost_Per_Unit,

    ROUND(
        SUM(CASE
            WHEN Delivery_Status = 'On Time' THEN 1
            ELSE 0
        END) / COUNT(*) * 100,
        2
    ) AS On_Time_Delivery_Pct,

    ROUND(
        SUM(CASE
            WHEN Is_Repeat_Order = 'Yes' THEN 1
            ELSE 0
        END) / COUNT(*) * 100,
        2
    ) AS Repeat_Order_Pct

FROM fact_production;

SELECT * FROM vw_production_kpi;

-- Produced vs Ordered by Quarter
CREATE OR REPLACE VIEW vw_quarterly_production AS
SELECT
    d.Year,
    d.Quarter,
    SUM(f.WO_Qty) AS Ordered_Qty,
    SUM(f.Produced_Qty) AS Produced_Qty
FROM fact_production f
JOIN dim_date d
    ON f.Date_FK = d.Date
GROUP BY
    d.Year,
    d.Quarter;

-- to show output table    
SELECT *
FROM vw_quarterly_production
ORDER BY Year, Quarter;

-- Delivery Status
CREATE OR REPLACE VIEW vw_delivery_status AS
SELECT
    Delivery_Status,
    COUNT(*) AS Order_Count
FROM fact_production
GROUP BY Delivery_Status;

-- Check the result
SELECT *
FROM vw_delivery_status;

-- Buyer-wise Production
CREATE OR REPLACE VIEW vw_buyer_production AS
SELECT
    b.Buyer_Name,
    SUM(f.Produced_Qty) AS Produced_Qty
FROM fact_production f
JOIN dim_buyer b
    ON f.Buyer_ID = b.Buyer_ID
GROUP BY b.Buyer_Name;

-- Check the result
SELECT *
FROM vw_buyer_production
ORDER BY Produced_Qty DESC;

-- To create the Production Summary Table
CREATE OR REPLACE VIEW vw_production_summary AS
SELECT
    b.Buyer_Name,
    SUM(f.WO_Qty) AS Ordered_Qty,
    SUM(f.Produced_Qty) AS Produced_Qty,
    SUM(f.Rejected_Qty) AS Rejected_Qty,
    ROUND(
        SUM(f.Produced_Qty) / NULLIF(SUM(f.WO_Qty), 0) * 100,
        2
    ) AS Production_Fulfillment_Pct,
    ROUND(
        SUM(f.Rejected_Qty) / NULLIF(SUM(f.Produced_Qty), 0) * 100,
        2
    ) AS Rejection_Rate_Pct
FROM fact_production f
JOIN dim_buyer b
    ON f.Buyer_ID = b.Buyer_ID
GROUP BY b.Buyer_Name;

-- To check result
SELECT *
FROM vw_production_summary
ORDER BY Produced_Qty DESC;



-- Quality & Rejection Dashboard
--  4 KPIs

CREATE OR REPLACE VIEW vw_quality_kpi AS
SELECT
    SUM(Rejected_Qty) AS Total_Rejected_Qty,

    ROUND(
        SUM(Rejected_Qty)
        / NULLIF(SUM(Produced_Qty), 0) * 100,
        2
    ) AS Rejection_Rate_Pct,

    ROUND(
        SUM(Rejected_Qty)
        / NULLIF(SUM(Processed_Qty), 0) * 100,
        2
    ) AS Wastage_Pct,

    ROUND(
        SUM(Rejected_Qty)
        / NULLIF(
            SUM(Produced_Qty) - SUM(Rejected_Qty),
            0
        ) * 100,
        2
    ) AS Total_Wastage_Pct

FROM fact_production;

-- To check result
SELECT *
FROM vw_quality_kpi;

-- Top 5 Machines by Rejected Quantity
CREATE OR REPLACE VIEW vw_top5_machine_rejection AS
SELECT
    f.Machine_Code,
    SUM(f.Rejected_Qty) AS Rejected_Qty
FROM fact_production f
GROUP BY f.Machine_Code
ORDER BY Rejected_Qty DESC
LIMIT 5;

-- check result
SELECT *
FROM vw_top5_machine_rejection;

-- Rejection by Department
CREATE OR REPLACE VIEW vw_department_rejection AS
SELECT
    d.Dept_Name,
    SUM(f.Rejected_Qty) AS Rejected_Qty
FROM fact_production f
JOIN dim_department d
    ON f.Dept_ID = d.Dept_ID
GROUP BY d.Dept_Name
ORDER BY Rejected_Qty DESC;

-- check result
SELECT *
FROM vw_department_rejection;

-- Operation-wise Rejection
CREATE OR REPLACE VIEW vw_operation_rejection AS
SELECT
    o.Operation_Name,
    SUM(f.Rejected_Qty) AS Rejected_Qty
FROM fact_production f
JOIN dim_operation o
    ON f.Operation_Code = o.Operation_Code
GROUP BY o.Operation_Name
ORDER BY Rejected_Qty DESC;

-- check result
SELECT *
FROM vw_operation_rejection;

-- Top 10 Employees by Rejection
CREATE OR REPLACE VIEW vw_top10_employee_rejection AS
SELECT
    e.Employee_Code,
    e.Employee_Name,
    e.Department,
    SUM(f.Rejected_Qty) AS Rejected_Qty
FROM fact_production f
JOIN dim_employee e
    ON f.Employee_Code = e.Employee_Code
GROUP BY
    e.Employee_Code,
    e.Employee_Name,
    e.Department
ORDER BY Rejected_Qty DESC
LIMIT 10;

-- check result
SELECT *
FROM vw_top10_employee_rejection;

-- to see the main KPI cards together
SELECT *
FROM vw_production_kpi;

SELECT *
FROM vw_quality_kpi;
