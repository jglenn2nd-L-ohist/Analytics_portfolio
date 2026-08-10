---------------------------------------------------------
-- Project: Olist E-commerce Fulfillment Analysis
-- File name: q3_late_reviews.sql
-- Table: purch; revu 
-- Business question:  Q3 How do review scores distribute 
--                     across delivery outcome buckets: 
--                     early, on-time, 1 to 3 days late, 
--                     4 or more days late?
-- Purpose:   Correlation between arrival time and review scores
-- Author: J.Glenn
-- Date: August 2026
---------------------------------------------------------

-- Establish any correlation between arrival times and reivew cores
SELECT
	 CASE WHEN ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) < 0 THEN '01 - early'  
		  WHEN ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) = 0 THEN '02 - on-time' 
		  WHEN ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) in (1,2,3) THEN '03 - 1-3 days late' 
		  ELSE '04 - 4 or more days late'  END AS arrival_v_expect
,	ROUND(Avg(r.review_score),2) AS avg_review_score
,	COUNT(*) AS num_reviews
FROM
	purch p
JOIN	
	revu r
ON
	p.order_id = r.order_id
GROUP BY
	1
;