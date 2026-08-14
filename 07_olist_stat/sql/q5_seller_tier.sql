----------------------------------------------------------
-- Project: Olist E-commerce Fulfillment Analysis
-- File name: q5_seller_tier.sql
-- Table: oitem, purch, revu
-- Business question: Q5  Build a seller performance tiering 
--                      function. Input: seller_id. 
--                      Output: tier assignment (high, mid, low) 
--                      based on on-time rate, average review score, 
--                      and order volume.
-- Purpose:   Classify sellers based on volume, otr & review 
-- Author: J.Glenn
-- Date: August 2026
---------------------------------------------------------
WITH on_time AS ( -- Establish Seller volume, OTR & Avg review scores
		SELECT
			o.seller_id
		,	COUNT(o.order_item_id) AS volume
		, 	COUNT( CASE WHEN julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date) <= 0 THEN 1 END) AS On_time
		,	ROUND(avg(r.review_score),2) AS av_review
		FROM
			oitem o
		JOIN
			purch p
		ON
			o.order_id = p.order_id
		JOIN
			revu r
		ON
			p.order_id = r.order_id
		GROUP BY
			o.seller_id
		)
SELECT
	seller_id
,	volume
,	on_time
, 	ROUND(100.0 * on_time/volume ,2) AS OTR -- On time Percentage
,	av_review

FROM
	on_time 
;