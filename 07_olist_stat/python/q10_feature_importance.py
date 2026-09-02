#########################################################
## Project: Olist E-commerce Fulfillment Analysis
## File name: q10_feature_importance.py
## Business question: Q9 What patterns are most associated 
##                      with late delivery risk? 
##                      which features carry the most 
##                      predictive weight? 
## Purpose:   Reveal any patterns hidden in late arrival risk
##            Determine which features are most associated 
##            with late arrival risk   
## Author: J.Glenn
## Date: August 2026
#########################################################

# - import libraries
import pandas as pd
import numpy as np
import sqlite3 as sq

from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import confusion_matrix, classification_report
from statsmodels.stats.outliers_influence import variance_inflation_factor

# - import dataset
conn = sq.connect("../data/olist.db")

query = """
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
                ,   o.order_item_id -- Included to get proper grain level  to  determint the correct OTR
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
                ,	o.order_item_id -- included to get the proper grain for true vol
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
    """

model = pd.read_sql_query(query, conn)
conn.close()

# - drop nulls from weight & volume
model = model.dropna(subset=["tot_weight","tot_volume"])

# - One-hot encoding to get binary 
model = pd.get_dummies(model, columns=["customer_state","seller_state","Category","Day_of_week","Month_num"], drop_first=True)


# - Set variables for model
x = model.drop(columns=["order_id","timestamp","seller_id","customer_id","late_flag"])
y = model["late_flag"]
timestamp = model["timestamp"]

# - standardize columns for uniformity in model weighting
scaler = StandardScaler()
x[["Seller_volume", "rolling_otr","tot_items","tot_weight","tot_volume","tot_value"]] = scaler.fit_transform(
    x[["Seller_volume", "rolling_otr","tot_items","tot_weight","tot_volume","tot_value"]]
)

# - subset just numeric features (no dummies, no targets)
num_cols = ["Seller_volume", "rolling_otr","tot_items","tot_weight","tot_volume","tot_value"]
X_num = x[num_cols]

vif_data = pd.DataFrame()
vif_data["feature"] = X_num.columns
vif_data["VIF"] = [variance_inflation_factor(X_num.values,i) for i in range(X_num.shape[1])]

print(vif_data)

# - reunite the separate dataframes
combined = pd.concat([x,y,timestamp], axis=1)

# - sort combined & ready for training
sort_combined = combined.sort_values("timestamp")

split = int(len(sort_combined) * 0.8)

train = sort_combined.iloc[:split]
test = sort_combined.iloc[split:]

x_train = train.drop(columns=["late_flag","timestamp"])
y_train = train["late_flag"]

x_test = test.drop(columns=["late_flag","timestamp"])
y_test = test["late_flag"]

# - model training
lr_model = LogisticRegression(class_weight="balanced")
lr_model.fit(x_train,y_train)
y_prob = lr_model.predict_proba(x_test)[:,1]
pred_adj = (y_prob >= 0.3).astype(int)

# - standardize every x_train column
feature_std = x_train.std()

coef_df = pd.DataFrame({
    "feature": x_train.columns,
    "raw_coef": lr_model.coef_[0]
})

coef_df["std_coef"] = coef_df["raw_coef"] * feature_std.values 
coef_df["abs_std_coef"] = coef_df["std_coef"].abs()

# - Reveal top 10% of features and their effects on arrival times
top15 = coef_df.sort_values("abs_std_coef", ascending=False).head(15)[["feature","std_coef","abs_std_coef"]]
print(top15)

# - Determine December's effects on arrival risk
print(coef_df[coef_df["feature"] == "Month_num_12"])