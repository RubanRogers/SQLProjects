-- Stored Procedure or creating a file

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

-- Show SP
SHOW PROCEDURE STATUS WHERE Db = 'Project';






