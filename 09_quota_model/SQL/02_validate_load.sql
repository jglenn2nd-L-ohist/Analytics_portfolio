---------------------------------------------------------
-- Project: Quota and Commission Model (09_quota_model)
-- File name: 02_validate_load.sql
-- Table: sales
-- Business question:  Does the flat-tier commission 
--                     structure overpay, and if so, 
--                     where and by how much?
-- Purpose:   Validate loaded sales data before processing
-- Author: J.Glenn
-- Date: October 2026
---------------------------------------------------------
-- Validate net sales by year (completed sales only) to confirm proper load
SELECT SUM(amount)	AS net_sales  
,	YEAR(sale_date) AS years
FROM dbo.sales
WHERE status = 'completed'
GROUP BY YEAR(sale_date)
order by 2
;

-- Validate Null status date and completed sales count are equal
SELECT 
	COUNT(CASE WHEN status_date IS NULL THEN 1 END) AS Stat_null_count
,	COUNT(CASE WHEN status = 'completed' THEN 1 END) AS complete_count
FROM dbo.sales
;