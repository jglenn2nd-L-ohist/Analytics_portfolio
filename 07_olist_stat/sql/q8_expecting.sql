---------------------------------------------------------
-- Project: Olist E-commerce Fulfillment Analysis
-- File name: q8_expecting.sql
-- Table: purch, revu
-- Business question: Q8 Do orders where the actual delivery 
--                    arrives earlier than estimated produce 
--                    significantly higher review scores than 
--                    orders where delivery arrives on or after 
--                    the estimated date? 
-- Purpose:   Determine if early arrival leads to significantly
--            higher review scores
-- Author: J.Glenn
-- Date: August 2026
---------------------------------------------------------

-- Bucket arrival to early or not 
SELECT
	 CASE WHEN ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) < 0 THEN 'early' ELSE 'not early' END AS arrival_v_expect
,	r.review_score
FROM
	purch p
JOIN	
	revu r
ON
	p.order_id = r.order_id
;