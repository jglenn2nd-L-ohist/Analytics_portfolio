-------------------------------------------------------------------
-- Project:           Global_Superstore_Operations_Analysis
-- Script:            q4_return_factors.sql
-- Business Question: Q4 | What factors appear to drive high shipping 
--                    costs and high return rates? 
--                    Is there a correlation with discount level, 
--                    shipping time, order size, or order priority?
-- Tables:            orders; returns 
-- Purpose:           To determine return correlations across ship_time,
--					  Discount, order size, order_priority and 
--                    similarly shipping_cost
-- Author:            J. Glenn
-- Date:              2026-07-28
-------------------------------------------------------------------
-- Returns by order_priority
SELECT
	COUNT(o.order_id) num_returns
,	o.order_priority
FROM
	orders o
LEFT JOIN
	returns r
ON	o.order_id = r.order_id
WHERE r.order_id IS NOT NULL AND o.shipping_cost > (SELECT round(avg(shipping_cost),2) av_ship_cost FROM orders) -- Average shipping cost subquery
GROUP BY
	o.order_priority

-- Returns by Discount
SELECT
	COUNT(o.order_id) num_returns	
,	CASE WHEN o.Discount = 0.0 THEN 'No Discount' 
		 WHEN o.Discount > 0.0 AND o.Discount <= 0.3 THEN 'Min Discount' 
		 WHEN o.Discount > 0.3 AND o.Discount <= 0.6 THEN 'Mid Discount'
		 WHEN o.Discount > 0.6 THEN 'Max Discount' END AS discount_level
		 
FROM
	orders o
LEFT JOIN
	returns r
ON	o.order_id = r.order_id
WHERE r.order_id IS NOT NULL AND o.shipping_cost > (SELECT round(avg(shipping_cost),2) av_ship_cost FROM orders) -- Average shipping cost subquery
GROUP BY
		discount_level
	
-- Returns by Sales
SELECT
	COUNT(o.order_id) num_returns	
,	CASE WHEN o.Sales <= 721 THEN '721(av return sales amt) and below'
		 WHEN o.sales > 721 AND o.Sales <= 2000 THEN '722 - 2000'
	     WHEN o.sales > 2000 AND o.Sales <= 5000 THEN '2001 - 5000'
		 ELSE '5001 and up' End sales_volume
FROM
	orders o
LEFT JOIN
	returns r
ON	o.order_id = r.order_id
WHERE r.order_id IS NOT NULL AND o.shipping_cost > (SELECT round(avg(shipping_cost),2) av_ship_cost FROM orders) -- Average shipping cost subquery
GROUP BY
	sales_volume
ORDER BY
	num_returns DESC
	
-- Returns by ship_time
SELECT
	COUNT(o.order_id) num_returns	
,	o.ship_time
FROM
	orders o
LEFT JOIN
	returns r
ON	o.order_id = r.order_id
WHERE r.order_id IS NOT NULL AND o.shipping_cost > (SELECT round(avg(shipping_cost),2) av_ship_cost FROM orders) -- Average shipping cost subquery
GROUP BY
	o.ship_time