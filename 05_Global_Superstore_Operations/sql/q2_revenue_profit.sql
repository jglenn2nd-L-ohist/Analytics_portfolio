-- ============================================================
-- Project:           Global_Superstore_Operations_Analysis
-- Script:            q2_revenue_profit.sql
-- Business Question: Q2 | Which regions and customer segments
--                    generate the most revenue and profit, and 
--                    what product categories are driving that 
--                    performance?
-- Tables Used:       orders
-- Date Window:       2011-01-01 through 2014-12-31
-- Purpose:           To determine which regions/categories/segments
--                    drive revenue and profits
-- Author:            J. Glenn
-- Date:              2026-07-23
-- ============================================================

SELECT
	Region
,	Segment
, 	Category
,	ROUND(SUM(Sales *(1 - Discount)),2) Revenue
,	ROUND(SUM(Profit),2) Profits
FROM
	orders 
GROUP BY
	Region
,	Segment
,	Category
ORDER BY
	Region
,	Segment
,	Revenue DESC