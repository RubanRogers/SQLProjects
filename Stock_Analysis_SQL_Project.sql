CREATE database Project;
USE Project;

CREATE table Project.Date_wise_data (Sale_Date date,Qty	Int,Item_Type Varchar (20),Job_Status Varchar (20),Planner Varchar (20),Buyer_Name Varchar (50),Sale_id	Int,
Preferred_Supplier Varchar (100),Safety Varchar (50),Pre_PLT Int, Post_PLT Int, LT Int,Run_Total Int,Late Int,Safety_RT Int,PO_Note	Varchar (50),Net_Neg Varchar (50),Last_Neg Varchar (50),
Item_Category Varchar (100),Created_On_Date date);

CREATE table Project.Order_status (Trans Varchar(50),Negative Varchar(50),Order_Type Varchar(50),Assembly_Supplier Varchar(50),Ref Varchar(50),Order_id	Varchar(50),Sale_id Varchar(50),Description Varchar(50));
ALTER table Project.Order_status modify Assembly_Supplier varchar (225); 

SELECT * FROM Project.Order_status ;
SELECT * FROM Project.Date_wise_data ;

-- 1
SELECT Order_id,
COUNT(CASE WHEN Order_Type = 'Stock' THEN 1 END) AS Stock_Count,
COUNT(CASE WHEN Order_Type = 'Work Order' THEN 1 END) AS Work_Order_Count
FROM Project.Order_status GROUP BY Order_id;

-- 2
SELECT Order_id,
COUNT(CASE WHEN Order_Type = 'Stock' THEN 1 END) AS Stock_Count,
COUNT(CASE WHEN Order_Type = 'Work Order' THEN 1 END) AS Work_Order_Count,
(COUNT(CASE WHEN Order_Type = 'Stock' THEN 1 END) - COUNT(CASE WHEN Order_Type = 'Work Order' THEN 1 END)) AS Work_Order_Pending_Status
FROM Project.Order_status GROUP BY Order_id;

-- 3
ALTER TABLE Project.Order_status ADD COLUMN work_order_closed_or_not VARCHAR(20);

WITH WorkOrderStatus AS (SELECT Order_id,(COUNT(CASE WHEN Order_Type = 'Stock' THEN 1 END) - COUNT(CASE WHEN Order_Type = 'Work Order' THEN 1 END)) AS Work_Order_Pending_Status
FROM Project.Order_status GROUP BY Order_id)
UPDATE Project.Order_status os JOIN WorkOrderStatus ws ON os.Order_id = ws.Order_id SET os.work_order_closed_or_not = CASE WHEN ws.Work_Order_Pending_Status < 0 THEN 'Order_Closed'
ELSE 'Order_Pending' END;

SELECT * FROM Project.Order_status ;

-- 4
CREATE TABLE Project.Order_pending_status (Order_id VARCHAR(50),Stock_Count INT,Work_Order_Count INT,Work_Order_Pending_Status INT,Work_Order_Closed_Or_Not VARCHAR(20));

INSERT INTO Project.Order_pending_status (Order_id, Stock_Count, Work_Order_Count, Work_Order_Pending_Status, Work_Order_Closed_Or_Not)
WITH WorkOrderStatus AS (SELECT Order_id,
COUNT(CASE WHEN Order_Type = 'Stock' THEN 1 END) AS Stock_Count,
COUNT(CASE WHEN Order_Type = 'Work Order' THEN 1 END) AS Work_Order_Count,
(COUNT(CASE WHEN Order_Type = 'Stock' THEN 1 END) - COUNT(CASE WHEN Order_Type = 'Work Order' THEN 1 END)) AS Work_Order_Pending_Status
FROM Project.Order_status
GROUP BY Order_id)
SELECT ws.Order_id,ws.Stock_Count,ws.Work_Order_Count,ws.Work_Order_Pending_Status,
CASE WHEN ws.Work_Order_Pending_Status < 0 THEN 'Order_Closed'
ELSE 'Order_Pending'
END AS Work_Order_Closed_Or_Not 
FROM WorkOrderStatus ws;

SELECT * FROM Project.Order_pending_status ;

-- 5
CREATE TABLE Project.order_supplier_report (Order_id VARCHAR(50),Sale_id INT,Description VARCHAR(255),
Order_Type VARCHAR(50),Assembly_Supplier VARCHAR(100),Sale_Date DATE,Qty INT,Item_Type VARCHAR(50),Planner VARCHAR(50),Buyer_Name VARCHAR(100),Preferred_Supplier VARCHAR(100));

SELECT * FROM Project.order_supplier_report ;

CREATE TABLE Project.Date_wise_supplier (Sale_id INT,Sale_Date DATE,Qty INT,Item_Type VARCHAR(50),Planner VARCHAR(50),Buyer_Name VARCHAR(100),Preferred_Supplier VARCHAR(100),PRIMARY KEY (Sale_id, Sale_Date) );

INSERT INTO Project.Date_wise_supplier (Sale_id, Sale_Date, Qty, Item_Type, Planner, Buyer_Name, Preferred_Supplier)
SELECT os.Sale_id,dw.Sale_Date,dw.Qty,dw.Item_Type,dw.Planner,dw.Buyer_Name,dw.Preferred_Supplier
FROM Project.Order_status os JOIN Project.Date_wise_data dw ON os.Sale_id = dw.Sale_id;  

INSERT INTO Project.order_supplier_report (Order_id, Sale_id, Description, Order_Type, Assembly_Supplier, Sale_Date, Qty, Item_Type, Planner, Buyer_Name, Preferred_Supplier)
SELECT os.Order_id,ds.Sale_id,os.Description,os.Order_Type,os.Assembly_Supplier,ds.Sale_Date,ds.Qty,ds.Item_Type,ds.Planner,ds.Buyer_Name,ds.Preferred_Supplier
FROM Project.Order_status os JOIN Project.Date_wise_supplier ds
ON os.Sale_id = ds.Sale_id;  

SELECT * FROM Project.order_supplier_report ;

-- 6
SELECT Sale_Date,SUM(Qty) AS Total_Quantity,COUNT(DISTINCT Sale_id) AS Order_ID_Count
FROM Project.Date_wise_supplier
GROUP BY Sale_Date ORDER BY Sale_Date;

SELECT Sale_id,Sale_Date,Qty,Item_Type,Planner,Buyer_Name,Preferred_Supplier,
TRIM(SUBSTRING_INDEX(Buyer_Name, ',', -1)) AS Last_Name,
TRIM(SUBSTRING_INDEX(Buyer_Name, ',', 1)) AS First_Name
FROM Project.Date_wise_supplier;

SELECT * FROM Project.Date_wise_supplier ;

-- 7
SHOW PROCEDURE STATUS WHERE Db = 'Project';

DELIMITER //
CREATE PROCEDURE GenerateReports()
BEGIN
DROP TABLE IF EXISTS Project.DateWiseQuantityOrderCount;
DROP TABLE IF EXISTS Project.SupplierNameSplit;

CREATE TABLE Project.DateWiseQuantityOrderCount (
Sale_Date DATE,
Total_Quantity INT,
Order_ID_Count INT);
   
INSERT INTO Project.DateWiseQuantityOrderCount (Sale_Date, Total_Quantity, Order_ID_Count)
SELECT Sale_Date,SUM(Qty) AS Total_Quantity,COUNT(DISTINCT Sale_id) AS Order_ID_Count FROM
Project.Date_wise_supplier GROUP BY Sale_Date
ORDER BY Sale_Date;

CREATE TABLE Project.SupplierNameSplit (Sale_id INT,Sale_Date DATE,Qty INT,Item_Type VARCHAR(50),Planner VARCHAR(50),Buyer_Name VARCHAR(100),Preferred_Supplier VARCHAR(100),
Last_Name VARCHAR(100),First_Name VARCHAR(100));

INSERT INTO Project.SupplierNameSplit (Sale_id, Sale_Date, Qty, Item_Type, Planner, Buyer_Name, Preferred_Supplier, Last_Name, First_Name)
SELECT Sale_id,Sale_Date,Qty,Item_Type,Planner,Buyer_Name,Preferred_Supplier,
TRIM(SUBSTRING_INDEX(Buyer_Name, ',', -1)) AS Last_Name,
TRIM(SUBSTRING_INDEX(Buyer_Name, ',', 1)) AS First_Name 
FROM Project.Date_wise_supplier;
END //
DELIMITER ;



