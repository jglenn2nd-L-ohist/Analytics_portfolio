---------------------------------------------------------
-- Project: Olist E-commerce Fulfillment Analysis
-- File name: q6_peak_otr.sql
-- Table: purch
-- Business question: Q6 Does delivery performance deteriorate 
--					  during peak periods (November/December holiday 
--                    season, identified from the data)
-- Purpose:   Does time of year have any effect on on-time rates
-- Author: J.Glenn
-- Date: August 2026
---------------------------------------------------------

WITH peak AS (
		SELECT
			COUNT(order_id) AS total_shipped
		,	COUNT(CASE WHEN ROUND(julianday(order_delivered_customer_date)-julianday(order_estimated_delivery_date),0) <= 0 THEN '1' END) AS arrival_diff
			
		FROM
			purch
		WHERE	
				strftime('%m', order_purchase_timestamp) IN ('11', '12')
		)
SELECT
	ROUND(100.0 * arrival_diff/total_shipped ,2) AS peak_otr
FROM
	peak
;