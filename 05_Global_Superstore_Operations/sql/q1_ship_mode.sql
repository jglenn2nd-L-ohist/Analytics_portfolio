-- ============================================================
-- Project:           Global Superstore Operations Analysis
-- Script:            q1_ship_mode.sql
-- Business Question: Q1 | Which shipping modes are being used 
--                    across segments and regions, and what is 
--                    the cost implication of those choices? 
-- Tables Used:       orders
-- Date Window:       2011-01-01 through 2014-12-31
-- Purpose:           To determine cost of shipping modes across
--                    the entire company & its impact
-- Author:            J. Glenn
-- Date:              2026-07-22
-- ============================================================
SELECT
	Region
,	Segment
,	ship_mode
,	count(*) num_shipments
,	ROUND(SUM(shipping_cost),2) tot_ship	
,	ROUND(SUM(Profit),2) tot_profit
FROM
orders 
GROUP BY
	Region
,	Segment
,	ship_mode
;