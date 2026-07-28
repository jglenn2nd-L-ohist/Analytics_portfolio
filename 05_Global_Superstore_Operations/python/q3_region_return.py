###############################################################
## Project:           Global_Superstore_Operations_Analysis
## Script:            q3_region_return.py
## Business Question: Q3 | Which regions have the highest return 
##                    rates, and is there a pattern by product 
##                    category or customer segment?
## Purpose:           To determine which regions have highest 
##                    return rates & the pattern in category and or
##                    customer segment
## Author:            J. Glenn
## Date:              2026-07-26
################################################################

# - import libraries
import pandas as pd
import numpy as np
import sqlite3 as sql
import matplotlib.pyplot as plt
import seaborn as sns

# - import data set
conn = sql.connect("../data/global_ss.db")

# - query based on category
q_cate =  """ 
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
    """
cate = pd.read_sql_query(q_cate, conn)

q_seg = """
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
    """
seg = pd.read_sql_query(q_seg, conn)

conn.close()

# - pivot dataframes for visualizing
cate = cate.pivot(index="Region", columns="Category", values="return_pct")
seg = seg.pivot(index="Region", columns="Segment", values="return_pct")

# - plot cate bar chart
cate.plot(kind="bar", stacked=False, figsize=(14,9))

plt.hlines(y= 5.96, xmax= 10, xmin= -1)
plt.annotate(text="Company Average: 5.96%",xy= [-.35,6.3])
plt.ylabel("Return Percent")
plt.title("Return rate by region/category")
plt.tight_layout()

plt.savefig("../outputs/q3_region_category.png")

# - plot seg bar chart
seg.plot(kind="bar", stacked=False, figsize=(14,9))


plt.hlines(y= 5.96, xmax= 10, xmin= -1)
plt.annotate(text="Company Average: 5.96%",xy= [-.35,6.3])
plt.ylabel("Return Percent")
plt.title("Return rate by region/segment")
plt.tight_layout()

plt.savefig("../outputs/q3_returns_segment.png")
plt.show()