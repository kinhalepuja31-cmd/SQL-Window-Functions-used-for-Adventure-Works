# SQL-Window-Functions-used-for-Adventure-Works



Advanced Data Analysis Using SQL Window Functions


** About the Project**


This project was completed as part of the VEDA Technology Data Analytics Track – Level 1, Day 12.
The task focuses on executing advanced transactional data exploration and trend tracking using Microsoft SQL Server Management Studio (SSMS) by applying Window Functions across multi-year retail datasets.


**Objective**


The main objectives of this task are:
•	Practice using window functions to solve complex business queries
•	Explore retail sales and customer data across multiple linked tables
•	Apply row numbering, ranking, and trend analysis conditions
•	Answer business-related questions using advanced analytical functions
•	Preserve table schemas while deriving multi-year insights
•	Extract meaningful data trends over consecutive years and months


** Tools Used**


•	Microsoft SQL Server Management Studio (SSMS)
•	T-SQL (Transact-SQL)_


**Dataset**


The project uses a multi-year retail sales and customer database consisting of linked data tables.
Dataset Tables
•	dbo.Customers (Demographics & Income records)
•	dbo.Products (Product lists & Base prices)
•	dbo.Sales_2015 (2015 Transaction entries)
•	dbo.Sales_2016 (2016 Transaction entries)
•	dbo.Sales_2017 (2017 Transaction entries)



** Window Functions Applied**


Individual targeted scripts were compiled and structured across multiple analytical exercises:
1.	ROW_NUMBER: Sequential numbering of products within category boundaries sorted by price.
2.	RANK: Global customer wealth positioning showcasing gap-handling on matching records.
3.	DENSE_RANK: Clean subcategory price groupings ensuring continuous ranking values.
4.	LAG: Month-over-Month and Year-over-Year revenue calculations using combined historical tables.
5.	LEAD: Dynamic forward-looking career trajectory evaluations.

 **Analytical Core Technical Notes**

 
•	ROW_NUMBER(): Imposes a strict unique, sequential integer sequence string. Identical values receive consecutive numbers arbitrarily without duplicate numbering.
•	RANK(): Duplicates ranking positions across matching numerical rows but explicitly skips subsequent positions relative to the tie count (e.g., 1, 2, 2, 4).
•	DENSE_RANK(): Duplicates ranking positions across matching numerical rows but preserves perfectly sequential rank integers without skipping steps (e.g., 1, 2, 2, 3).
•	LAG(): Accesses historical row fields preceding the active position index by an offset step. Crucial for timeline growth calculations without executing self-joins.

**Author**
Puja Kinhale
