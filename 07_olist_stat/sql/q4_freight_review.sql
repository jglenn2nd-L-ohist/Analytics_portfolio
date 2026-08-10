---------------------------------------------------------
-- Project: Olist E-commerce Fulfillment Analysis
-- File name: q4_freight_review.sql
-- Table: purch; oitem; revu; prods 
-- Business question:  Q4 Which product categories carry the 
--                     highest freight cost relative to item price, 
--                     and does that ratio correlate with review scores?
-- Purpose:   Correlation between product weight/ship cost & review scores
-- Author: J.Glenn
-- Date: August 2026
---------------------------------------------------------

WITH prct AS ( -- Establish freight costs relative to item price
		SELECT
			pr.product_category_name
		,	o.freight_value
		,	o.price
		,	o.freight_value/o.price as pct_to_ship		
		FROM
			purch p
		JOIN	
			oitem o
		ON
			p.order_id = o.order_id
		JOIN	
			prods pr
		ON
			o.product_id = pr.product_id
		WHERE pr.product_category_name IS NOT NULL -- Filter out 1 row where category name was null
		)
,	cat_avg AS ( -- Determine Averages across 3 measures
		SELECT
			product_category_name
		,	ROUND(avg(freight_value),2) AS Av_freight_cost
		,	ROUND(avg(price),2) AS Av_unit_price
		,	ROUND(100.0 *avg(pct_to_ship),2) AS Av_pct_to_ship
		FROM
			prct
		GROUP BY
			product_category_name
		)
,	cat_revus AS (  -- Determine Average Review score by category
		SELECT
			pr.product_category_name
		,	ROUND(avg(r.review_score),2) AS Av_review	
		FROM
			revu r
		JOIN
			oitem o
		ON
			r.order_id = o.order_id
		JOIN
			prods pr
		ON
			o.product_id = pr.product_id
		GROUP BY
			pr.product_category_name
		)
SELECT
	ca.product_category_name
,	av_freight_cost
,	av_unit_price
,	av_pct_to_ship
,	av_review
FROM
	cat_avg ca
JOIN
	cat_revus cr
ON
	ca.product_category_name = cr.product_category_name
ORDER BY
	Av_pct_to_ship DESC
;