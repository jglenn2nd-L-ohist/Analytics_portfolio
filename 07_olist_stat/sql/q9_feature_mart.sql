---------------------------------------------------------
-- Project: Olist E-commerce Fulfillment Analysis
-- File name: q9_feature_mart.sql
-- Table: purch, cust, vend, oitem, prods
-- Business question: Q9 Using only data available at the 
--                       time of purchase, determine which 
--                       orders carry the highest predicted 
--                       risk of late delivery 
-- Purpose:   Determine risk factors for late arrivals
-- Author: J.Glenn
-- Date: August 2026
---------------------------------------------------------
WITH arrival AS (-- CTE to create on_time flag and late_flag 
        SELECT
            order_id
        ,	order_purchase_timestamp AS timestamp
        ,	strftime('%m', order_purchase_timestamp) AS Month_num
        ,	CASE WHEN strftime('%m', order_purchase_timestamp) IN ('11', '12') THEN 1 ELSE 0 END AS peak_season
        ,	strftime('%w', order_purchase_timestamp) AS Day_of_week
        ,	order_delivered_customer_date AS delivered
        ,	order_estimated_delivery_date AS estimated
        ,	CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END AS late_flag
        FROM
            purch 
    )
,	ag_orders AS (-- CTE to aggregate items to order level
        SELECT
            o.order_id
        ,	COUNT(o.order_item_id) AS tot_items
        ,	SUM(p.product_weight_g) AS tot_weight
        ,	SUM(p.product_height_cm * p.product_length_cm * p.product_width_cm) AS tot_volume
        , 	SUM(o.freight_value) AS tot_value
        ,	CASE WHEN COUNT(DISTINCT p.product_category_name) = 1 THEN MAX(p.product_category_name) ELSE "Various" END AS Category
        FROM
            oitem o
        JOIN
            prods p
        ON o.product_id=p.product_id
        GROUP BY
            o.order_id
    )
,	roll_otr AS (-- establish rolling counter for seller on-time rate	
        SELECT
            o.order_id
        ,   o.order_item_id
        ,	o.seller_id
        ,	p.order_purchase_timestamp AS timestamp
        ,	SUM(CASE WHEN p.order_delivered_customer_date < p.order_estimated_delivery_date THEN 1 ELSE 0 END) OVER (PARTITION BY o.seller_id ORDER BY p.order_purchase_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS on_time_deliveries
        ,	COUNT(*)OVER (PARTITION BY o.seller_id ORDER BY p.order_purchase_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS tot_deliveries
        FROM
            purch p
        JOIN
            oitem o
        ON p.order_id = o.order_id
        GROUP BY
            o.order_id, o.order_item_id
    )
,	excl_otr AS (-- filter to exclude the 1st sale from calculating seller on-time rate
        SELECT
            order_id, order_item_id, seller_id, timestamp, on_time_deliveries, tot_deliveries
        ,	(100.0 * on_time_deliveries /tot_deliveries) AS rolling_otr
        FROM roll_otr
        WHERE tot_deliveries > 0
    )
,	states AS (-- determine customer and seller states by order 
        SELECT
            p.order_id
        ,	p.customer_id
        ,	c.customer_state
        ,	o.seller_id
        ,	CASE WHEN COUNT(DISTINCT v.seller_state) = 1 THEN MAX(v.seller_state) ELSE "Various" END AS seller_state
        FROM
            purch p
        JOIN oitem o ON p.order_id = o.order_id
        JOIN cust c ON p.customer_id = c.customer_id 
        JOIN vend v ON o.seller_id = v.seller_id
        GROUP BY p.order_id 
    )
,	roll_vol AS (-- establish rolling counter for seller volume
        SELECT
            o.order_id
        ,	o.order_item_id
        ,	o.seller_id
        ,	p.order_purchase_timestamp AS timestamp
        ,	COUNT(*)OVER (PARTITION BY o.seller_id ORDER BY p.order_purchase_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS tot_sales
        FROM
            purch p
        JOIN oitem o ON p.order_id = o.order_id
        GROUP BY
            o.order_id, o.order_item_id
    )
,	excl_vol AS (-- filter to exclude the 1st sale from calculating seller volume
        SELECT order_id, order_item_id, seller_id, timestamp, tot_sales
        FROM roll_vol
        WHERE tot_sales > 0
    )
SELECT
    ar.order_id
,   ar.timestamp 
,	s.customer_id
,	s.customer_state
,	CASE WHEN COUNT(DISTINCT otr.seller_id) = 1 THEN MIN(otr.seller_id) ELSE "Various" END AS seller_id
,   s.seller_state	
,	MAX(vol.tot_sales) AS Seller_volume
,	ar.late_flag
,	ar.peak_season
, 	ar.Month_num
,	ar.Day_of_week
,	MIN(otr.rolling_otr) AS rolling_otr
,	ao.tot_items
,	ao.tot_weight
,	ao.tot_volume
,	ao.tot_value
,	ao.category
FROM
    arrival ar
JOIN ag_orders ao 
ON ar.order_id = ao.order_id 
JOIN excl_otr otr 
ON ar.order_id = otr.order_id
JOIN excl_vol vol 
ON otr.order_id = vol.order_id AND otr.order_item_id = vol.order_item_id
JOIN states s 
ON ar.order_id = s.order_id 
GROUP BY
    ar.order_id

;	