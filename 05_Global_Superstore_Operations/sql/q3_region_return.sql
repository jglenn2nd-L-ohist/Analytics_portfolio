-------------------------------------------------------------------
-- Project:           Global_Superstore_Operations_Analysis
-- Script:            q3_region_return.sql
-- Business Question: Q3 | Which regions have the highest return 
--                    rates, and is there a pattern by product 
--                    category or customer segment?
-- Tables:            orders; returns 
-- Purpose:           To determine which regions have highest 
--                    return rates & the pattern in category and or
--                    customer segment
-- Author:            J. Glenn
-- Date:              2026-07-27
-------------------------------------------------------------------
-- Query to answer Return % by region and by category 
WITH t_sales AS ( -- determine total number of sales 
	SELECT	
		CAST(Count(order_id) as float) num_sales
	,	Region
	,	Category
	FROM
		orders
	GROUP BY
		Region
	,	Category
)
, 	t_returns as ( -- determine total number of returns 
			SELECT 
				CAST(COUNT(r.order_id) as float) num_returns
			,	o.Region
			,	o.Category
			FROM 
				orders o
			JOIN 
				returns r
			ON 
				o.order_id = r.order_id
			GROUP BY 
				o.Region
			,	o.Category
)
SELECT	
	s.Region
,	s.Category
,	s.num_sales 
,	r.num_returns
, 	ROUND(100.0 * CAST(r.num_returns/s.num_sales AS float),2)  AS return_pct
	
FROM
	t_sales s
JOIN
	t_returns r
on
	s.Region = r.Region AND s.Category = r.Category
GROUP BY 
	S.Region
,	s.Category
;

-- Query to determine returns by region by segment 
WITH t_sales AS ( -- determine total number of sales 
	SELECT	
		CAST(Count(order_id) as float) num_sales
	,	Region
	,	Segment
	FROM
		orders
	GROUP BY
		Region
	, 	Segment
)
, 	t_returns as ( -- determine total number of returns 
			SELECT 
				CAST(COUNT(r.order_id) as float) num_returns
			,	o.Region
			,	o.Segment
			FROM 
				orders o
			JOIN 
				returns r
			ON 
				o.order_id = r.order_id
			GROUP BY 
				o.Region
			,	o.Segment
)
SELECT	
	s.Region
,	s.Segment
,	s.num_sales 
,	r.num_returns
, 	ROUND(100.0 * CAST(r.num_returns/s.num_sales AS float),2)  AS return_pct
	
FROM
	t_sales s
JOIN
	t_returns r
on
	s.Region = r.Region AND s.segment = r.segment 
GROUP BY 
	S.Region
,	s.Segment
;

-- Determine company return average
SELECT
	CAST(COUNT(o.order_id) AS float) tot_sales
,	CAST(COUNT(r.order_id) AS float) tot_return
,	ROUND(100 * CAST(COUNT(r.order_id) AS float) /CAST(COUNT(o.order_id) AS float),2) av_return_pct

FROM
	orders o
LEFT JOIN
	returns r
ON
	o.order_id = r.order_id