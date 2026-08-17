---------------------------------------------------------
-- Project: Olist E-commerce Fulfillment Analysis
-- File name: q7_accuracy.sql
-- Table: purch, revu
-- Business question: Q7 Is there a statistically meaningful 
--                    relationship between how accurately Olist 
--                    estimates the delivery date and the review 
--                    score a customer leaves?
-- Purpose:   Determine if there is a statistically significant 
--            relationship between expeced arrival & review scores
-- Author: J.Glenn
-- Date: August 2026
---------------------------------------------------------

-- Bucket arrival times and connect reviews 
SELECT
	 CASE WHEN ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) < 0 THEN '01 - early'  
		  WHEN ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) = 0 THEN '02 - on-time' 
		  WHEN ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) in (1,2,3) THEN '03 - 1-3 days late' 
		  ELSE '04 - 4 or more days late'  END AS arrival_v_expect
,	r.review_score
FROM
	purch p
JOIN	
	revu r
ON
	p.order_id = r.order_id
;    