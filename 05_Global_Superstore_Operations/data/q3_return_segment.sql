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

