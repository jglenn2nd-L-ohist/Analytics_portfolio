---------------------------------------------------------
-- Project: Olist E-commerce Fulfillment Analysis
-- File name: q2_state_otr.sql
-- Table: purch; oitem; vend
-- Business question:  Q2) Which seller states have the 
--                     worst on-time delivery rates, and 
--                     does seller-customer geographic 
--                     distance correlate with delay? 
-- Purpose:   Determine worst on-time rates by state
--            and see is there a distance correlation
-- Author: J.Glenn
-- Date: August 2026
---------------------------------------------------------

-- Determine Seller state and on-time rate
WITH seller_otr AS (
	SELECT
		v.seller_state
	,   COUNT(p.order_id) AS total_shipped
	,	COUNT(CASE WHEN ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) < 1 THEN '1' END) AS arrival_diff
		
	FROM
		purch p
	JOIN
		oitem o
	ON p.order_id = o.order_id
	JOIN
		vend v
	ON o.seller_id = v.seller_id
	JOIN
		cust c
	ON
		p.customer_id = c.customer_id

	GROUP BY
		v.seller_state
	HAVING
		total_shipped >= 50
	)
SELECT
	seller_state
,	total_shipped
,	100.0*(ROUND((1.0 * arrival_diff)/(1.0 * total_shipped) ,2)) AS on_time_pct	
FROM
	seller_otr
