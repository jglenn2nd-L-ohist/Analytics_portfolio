# - Import libraries
import pandas as pd
import numpy as np
import sqlite3 as sq
import matplotlib.pyplot as plt

# - Import data
conn = sq.connect("../data/wc_pizza.db")

# - Query data
query = """
    WITH act AS ( -- Actual hours worked by store
        SELECT
            a.store_id
        ,	s.store_name
        ,	SUM(a.actual_hours) AS act_hours
        FROM
            wc_shifts_actual a
        JOIN
            wc_stores s
        ON a.store_id = s.store_id
        GROUP BY
            a.store_id
        ,	s.store_name
        )
    ,	Schd AS ( -- Scheduled hours by store
                SELECT
                store_id 
            ,	SUM((shift_end - shift_start) * scheduled_staff) AS Scd_hours
            FROM
            wc_shifts_scheduled
            GROUP BY
                store_id
            )
    SELECT
        a.store_id
    ,	a.store_name
    , 	a.act_hours
    ,	SUM(s.scd_hours) AS Schd_hours
    ,	ROUND((SUM(a.act_hours) - (s.scd_hours)),2) AS Sched_var
    FROM
        act a
    JOIN
        schd s
    ON a.store_id = s.store_id
    GROUP BY
        a.Store_name
    ORDER BY
        a.store_id
        """
var = pd.read_sql_query(query, conn)

# - Plot horizontal bar chart
var = var[::-1]  # reverse the dataframe

fig, ax = plt.subplots(figsize=(12, 8))

ax.barh(var['store_name'], var['Sched_var'], color="red", label="Variance")
ax.set_xticks(np.arange(-3500, 500, 500))
ax.set_xlabel('Variance to Budget')
ax.set_title('Stores Budgeted (scheduled) hour Variance to Worked hours')


plt.tight_layout()
plt.savefig("../outputs/q4b_scheduled_variance.png")
plt.show()