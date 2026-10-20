---------------------------------------------------------
-- Project: Quota and Commission Model (09_quota_model)
-- File name: 03_rep_month_derivation.sql
-- Table: sales
-- Business question:  Does the flat-tier commission 
--                     structure overpay, and if so, 
--                     where and by how much?
-- Purpose:   Distill Rep sales by month/year
-- Author: J.Glenn
-- Date: October 2026
---------------------------------------------------------
-- Aggregate completed sales by rep by month each year
SELECT
	rep_id
,	region_id
,	SUM(amount) AS net_sales
,	DATEFROMPARTS(year(sale_date),month(sale_date),1) AS month_start
FROM dbo.sales
WHERE status = 'completed'
GROUP BY rep_id
,	region_id
,	DATEFROMPARTS(year(sale_date),month(sale_date),1)  
ORDER BY month_start ASC
,	rep_id
;


-- Confirm yearly total matches total from 02_validate_load.sql
WITH confirm AS (
SELECT
	rep_id
,	region_id
,	SUM(amount) AS net_sales
,	DATEFROMPARTS(year(sale_date),month(sale_date),1) AS month_start
FROM dbo.sales
WHERE status = 'completed'
GROUP BY rep_id
,	region_id
,	DATEFROMPARTS(year(sale_date),month(sale_date),1)  
)
SELECT
	SUM(net_sales) AS yr_total
,	YEAR(month_start) AS yr
FROM
	confirm
GROUP BY
	YEAR(month_start)
ORDER BY
	yr ASC
;
