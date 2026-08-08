---------------------------------------------------------
-- Project: Olist E-commerce Fulfillment Analysis
-- File name: q1_delivery_rate.sql
-- Table: purch
-- Business question: Q1) What does overall delivery 
--                    performance look like -- on-time 
--                    rate, average days late, 
--                    average days early?
-- Purpose:   Determine a baseline of delivery performance
--            to serve as a barometer for further analysis
-- Author: J.Glenn
-- Date: August 2026
---------------------------------------------------------

-- Determine delivery performance (on-time rate)
WITH on_time AS (
			SELECT
				customer_id
			,	order_estimated_delivery_date ETA
			,	order_delivered_customer_date delivered
			,	ROUND(julianday(order_delivered_customer_date)-julianday(order_estimated_delivery_date),0) arrival_diff
			FROM
				purch
			WHERE
				ROUND(julianday(order_delivered_customer_date)-julianday(order_estimated_delivery_date),0) <= 0
			)
SELECT 
	count(o.customer_id) AS on_time
,	count(p.customer_id) AS all_deliv
,	ROUND(100.0 *CAST(count(o.customer_id) AS float)/CAST(count(p.customer_id) AS float),2) AS on_time_pct
	
FROM
	purch p
LEFT JOIN
	on_time o
ON 
	p.customer_id=o.customer_id
;
-- Average num days late
WITH late AS (
			SELECT
				customer_id
			,	order_estimated_delivery_date ETA
			,	order_delivered_customer_date delivered
			,	ROUND(julianday(order_delivered_customer_date)-julianday(order_estimated_delivery_date),0) arrival_diff
			FROM
				purch
			WHERE
				ROUND(julianday(order_delivered_customer_date)-julianday(order_estimated_delivery_date),0) > 0
			)
SELECT
	ROUND(AVG(arrival_diff),0) as avg_days_late
FROM
	late
;	
-- Average num days early
WITH early AS (
			SELECT
				customer_id
			,	order_estimated_delivery_date ETA
			,	order_delivered_customer_date delivered
			,	ROUND(julianday(order_delivered_customer_date)-julianday(order_estimated_delivery_date),0) arrival_diff
			FROM
				purch
			WHERE
				ROUND(julianday(order_delivered_customer_date)-julianday(order_estimated_delivery_date),0) < 0
			)
SELECT
	ROUND(-AVG(arrival_diff),0) as avg_days_early
FROM
	early
;