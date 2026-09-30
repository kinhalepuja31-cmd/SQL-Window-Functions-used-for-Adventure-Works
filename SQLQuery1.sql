create database Adventure_Works;


use Adventure_Works;

select * from [dbo].[AdventureWorks_Customers];

SELECT 
    schema_name(schema_id) AS SchemaName,
    name AS TableName
FROM 
    sys.tables
ORDER BY 
    SchemaName, TableName;

EXEC sp_rename 'AdventureWorks_Customers', 'Customers';

select * from Customers;

EXEC sp_rename 'AdventureWorks_Product_Subcategories', 'Product_Subcategories';

EXEC sp_rename 'AdventureWorks_Product_Categories', 'Product_Categories'

EXEC sp_rename 'AdventureWorks_Calendar', 'Calendar';

select * from Product_Subcategories;

select * from Product_Categories;

select * from Calendar;

-- 1. Add a new date column to your Calendar table
ALTER TABLE Calendar
ADD FullDate DATE;

-- 2. Combine your text pieces (Year, Month, Day) into a standard YYYY-MM-DD date format
UPDATE Calendar
SET FullDate = CAST(
    CAST(column3 AS VARCHAR(4)) + '-' + 
    CAST(column1 AS VARCHAR(2)) + '-' + 
    CAST(column2 AS VARCHAR(2)) 
AS DATE);

SELECT column1 AS [Month], column2 AS [Day], column3 AS [Year], FullDate
FROM Calendar;



select * from Calendar;

select * from Products;

--Query 1: Numbering rows for products inside their subcategories

select ProductSubcategoryKey, ProductName,
ProductPrice,
ROW_NUMBER() OVER (PARTITION BY ProductSubcategoryKey ORDER BY ProductPrice DESC) AS PriceRowSeq
from 
Products
where 
ProductSubcategoryKey is not null;

---Query 2: Ranking prices with RANK vs DENSE_RANK

SELECT 
    ProductSubcategoryKey,
    ProductName,
    ProductPrice,
    RANK() OVER (PARTITION BY ProductSubcategoryKey ORDER BY ProductPrice DESC) AS PriceRank,
    DENSE_RANK() OVER (PARTITION BY ProductSubcategoryKey ORDER BY ProductPrice DESC) AS PriceDenseRank
FROM Products
WHERE ProductSubcategoryKey IS NOT NULL;


---Query 3: Isolating the top 3 most expensive items per subcategory

WITH RankedProductsTable AS (
    SELECT 
        ProductSubcategoryKey,
        ProductName,
        ProductPrice,
        ROW_NUMBER() OVER (PARTITION BY ProductSubcategoryKey ORDER BY ProductPrice DESC) AS PriceRowNum
    FROM Products
    WHERE ProductSubcategoryKey IS NOT NULL
)
SELECT * 
FROM RankedProductsTable 
WHERE PriceRowNum <= 3;


--Query 4: Year-over-Year (YoY) Sales Revenue Growth
WITH CombinedSales AS (
    SELECT OrderDate, ProductKey, CustomerKey, TerritoryKey, OrderQuantity FROM dbo.Sales_2015
    UNION ALL
    SELECT OrderDate, ProductKey, CustomerKey, TerritoryKey, OrderQuantity FROM dbo.Sales_2016
    UNION ALL
    SELECT OrderDate, ProductKey, CustomerKey, TerritoryKey, OrderQuantity FROM dbo.Sales_2017
),
AnnualRevenueSummary AS (
    SELECT 
        YEAR(s.OrderDate) AS OrderYear,
        SUM(s.OrderQuantity * p.ProductPrice) AS AnnualSales
    FROM CombinedSales s
    JOIN dbo.Products p ON s.ProductKey = p.ProductKey
    WHERE s.OrderDate IS NOT NULL 
    GROUP BY YEAR(s.OrderDate)
)
SELECT 
    OrderYear,
    AnnualSales,
    LAG(AnnualSales, 1) OVER (ORDER BY OrderYear) AS LastYearSales,
    (AnnualSales - LAG(AnnualSales, 1) OVER (ORDER BY OrderYear)) AS GrowthAmount
FROM AnnualRevenueSummary;


  --query5:top 10 customers

   select * from Customers;

   WITH CombinedSales AS (
    SELECT CustomerKey, ProductKey, OrderQuantity FROM dbo.Sales_2015
    UNION ALL
    SELECT CustomerKey, ProductKey, OrderQuantity FROM dbo.Sales_2016
    UNION ALL
    SELECT CustomerKey, ProductKey, OrderQuantity FROM dbo.Sales_2017
),
CustomerSalesSummary AS (
    SELECT 
        s.CustomerKey,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        c.Occupation,
        SUM(s.OrderQuantity * p.ProductPrice) AS TotalSpend
    FROM CombinedSales s
    JOIN dbo.Products p ON s.ProductKey = p.ProductKey
    JOIN dbo.Customers c ON s.CustomerKey = c.CustomerKey
    GROUP BY s.CustomerKey, c.FirstName, c.LastName, c.Occupation
),
RankedCustomers AS (
    SELECT 
        CustomerKey,
        CustomerName,
        Occupation,
        TotalSpend,
        DENSE_RANK() OVER (ORDER BY TotalSpend DESC) AS SalesRank
    FROM CustomerSalesSummary
)
SELECT SalesRank, CustomerKey, CustomerName, Occupation, TotalSpend
FROM RankedCustomers
WHERE SalesRank <= 10;


---Query 6: top selling product
WITH CombinedSales AS (
    SELECT ProductKey, OrderQuantity FROM dbo.Sales_2015
    UNION ALL
    SELECT ProductKey, OrderQuantity FROM dbo.Sales_2016
    UNION ALL
    SELECT ProductKey, OrderQuantity FROM dbo.Sales_2017
),
ProductSalesSummary AS (
    SELECT 
        s.ProductKey,
        p.ProductName,
        p.ProductSubcategoryKey,
        SUM(s.OrderQuantity) AS TotalUnitsSold,
        cast(SUM(s.OrderQuantity * p.ProductPrice) AS decimal(18,2)) as TotalRevenueGenerated
    FROM CombinedSales s
    JOIN dbo.Products p ON s.ProductKey = p.ProductKey
    GROUP BY s.ProductKey, p.ProductName, p.ProductSubcategoryKey
),
RankedProducts AS (
    SELECT 
        ProductKey,
        ProductName,
        ProductSubcategoryKey,
        TotalUnitsSold,
        TotalRevenueGenerated,
        DENSE_RANK() OVER (ORDER BY TotalRevenueGenerated DESC) AS SalesRank
    FROM ProductSalesSummary
)
SELECT SalesRank, ProductKey, ProductName, ProductSubcategoryKey, TotalUnitsSold, TotalRevenueGenerated
FROM RankedProducts
WHERE SalesRank <= 10;

 ---Query7:  Month-over-Month (MoM) Company Revenue Trends

WITH CombinedSales AS (
    SELECT OrderDate, ProductKey, OrderQuantity FROM dbo.Sales_2015
    UNION ALL
    SELECT OrderDate, ProductKey, OrderQuantity FROM dbo.Sales_2016
    UNION ALL
    SELECT OrderDate, ProductKey, OrderQuantity FROM dbo.Sales_2017
),
MonthlySalesSummary AS (
    SELECT 
        YEAR(s.OrderDate) AS SalesYear,
        MONTH(s.OrderDate) AS SalesMonth,
        CAST(SUM(s.OrderQuantity * p.ProductPrice) AS DECIMAL(18,2)) AS CurrentMonthRevenue
    FROM CombinedSales s
    JOIN dbo.Products p ON s.ProductKey = p.ProductKey
    WHERE s.OrderDate IS NOT NULL
    GROUP BY YEAR(s.OrderDate), MONTH(s.OrderDate)
)
SELECT 
    SalesYear,
    SalesMonth,
    CurrentMonthRevenue,
    -- Looks at the previous row's revenue
    ISNULL(LAG(CurrentMonthRevenue, 1) OVER (ORDER BY SalesYear, SalesMonth), 0.00) AS PreviousMonthRevenue,
    -- Calculates the dollar difference
    CAST(CurrentMonthRevenue - ISNULL(LAG(CurrentMonthRevenue, 1) OVER (ORDER BY SalesYear, SalesMonth), 0.00) AS DECIMAL(18,2)) AS RevenueChange
FROM MonthlySalesSummary;


---Query 8:  Top 10 return quantity

select * from Returns_Data;

WITH ProductReturnsSummary AS (
    SELECT 
        r.ProductKey,
        p.ProductName,
        COUNT(r.ProductKey) AS TotalReturnCount,
        CAST(SUM(r.ReturnQuantity * p.ProductPrice) AS DECIMAL(18,2)) AS EstimatedLostRevenue
    FROM Returns_Data r
    JOIN dbo.Products p ON r.ProductKey = p.ProductKey
    GROUP BY r.ProductKey, p.ProductName
),
RankedReturns AS (
    SELECT 
        ProductKey,
        ProductName,
        TotalReturnCount,
        EstimatedLostRevenue,
        DENSE_RANK() OVER (ORDER BY TotalReturnCount DESC) AS ReturnRank
    FROM ProductReturnsSummary
)
SELECT ReturnRank, ProductKey, ProductName, TotalReturnCount, EstimatedLostRevenue
FROM RankedReturns
WHERE ReturnRank <= 10;

--Query 9: Territory monthly volume tracking (using OrderQuantity)


WITH CombinedSales AS (
    SELECT OrderDate, TerritoryKey, OrderQuantity FROM dbo.Sales_2015
    UNION ALL
    SELECT OrderDate, TerritoryKey, OrderQuantity FROM dbo.Sales_2016
    UNION ALL
    SELECT OrderDate, TerritoryKey, OrderQuantity FROM dbo.Sales_2017
),
TerritoryMonthlySales AS (
    SELECT 
        TerritoryKey,
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        SUM(OrderQuantity) AS TotalQty
    FROM CombinedSales
    GROUP BY TerritoryKey, YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
    TerritoryKey, OrderYear, OrderMonth, TotalQty,
    LAG(TotalQty, 1) OVER (PARTITION BY TerritoryKey ORDER BY OrderYear, OrderMonth) AS PriorMonthQty
FROM TerritoryMonthlySales;


select * from Territories;


---Query 10: Days elapsed between consecutive customer orders
---• Find out how many days pass before a customer places their next order.

WITH CombinedSales AS (
    SELECT CustomerID = CustomerKey, OrderDate, OrderNumber FROM dbo.Sales_2015
    UNION ALL
    SELECT CustomerID = CustomerKey, OrderDate, OrderNumber FROM dbo.Sales_2016
    UNION ALL
    SELECT CustomerID = CustomerKey, OrderDate, OrderNumber FROM dbo.Sales_2017
),
DistinctCustomerOrders AS (
    SELECT DISTINCT CustomerID, OrderNumber, OrderDate
    FROM CombinedSales
),
CustomerTimelines AS (
    SELECT 
        CustomerID, OrderNumber, OrderDate,
        LAG(OrderDate, 1) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS PriorOrderDate
    FROM DistinctCustomerOrders
)
SELECT 
    CustomerID, OrderNumber, OrderDate, PriorOrderDate,
    DATEDIFF(day, PriorOrderDate, OrderDate) AS DaysBetweenPurchases
FROM CustomerTimelines
WHERE PriorOrderDate IS NOT NULL;


---Query 11: Ranking customer wealth globally to see tie-handling (RANK vs DENSE_RANK)

SELECT 
    CustomerKey,
    FirstName + ' ' + LastName AS CustomerName,
    AnnualIncome,
    RANK() OVER (ORDER BY AnnualIncome DESC) AS GlobalIncomeRank,
    DENSE_RANK() OVER (ORDER BY AnnualIncome DESC) AS GlobalIncomeDenseRank
FROM dbo.Customers;



---Query 7: Tracking Income Gaps Between Successive Education Levels (LAG)

WITH AvgIncomeByEducation AS (
    SELECT 
        EducationLevel,
        CAST(AVG(AnnualIncome) AS DECIMAL(18,2)) AS AverageIncome
    FROM dbo.Customers
    WHERE EducationLevel IS NOT NULL
    GROUP BY EducationLevel
)
SELECT 
    EducationLevel,
    AverageIncome,
    -- Pulls the average income from the previous education tier row
    ISNULL(LAG(AverageIncome, 1) OVER (ORDER BY AverageIncome ASC), 0.00) AS LowerTierIncome,
    -- Calculates the absolute income step-up amount
    CAST(AverageIncome - ISNULL(LAG(AverageIncome, 1) OVER (ORDER BY AverageIncome ASC), 0.00) AS DECIMAL(18,2)) AS IncomeStepUp
FROM AvgIncomeByEducation;

