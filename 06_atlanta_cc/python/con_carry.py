######################################################
# Project: Safe haven or Wild West
# Filename: con_carry.py
# Business Question: This script will visualize all three 
#                    proposed business questions, as the
#                    synthesis query (Q3) contains all the
#                    necessary data
# Purpose: Reveal whether Atlanta is a Safe haven or the Wild west
#          since the start of Constitutional Carry and the Dickens era
# Author: J.Glenn
# Date Project Started: 2026-07-31 
######################################################

# import libraries
import pandas as pd
import matplotlib.pyplot as plt
import sqlite3 as sq
from matplotlib.ticker import FuncFormatter

# - import and query data
conn = sq.connect("../data/acc.db")

query = """
        WITH year_labels AS ( -- Break down 48m into years for equal comparisons
            SELECT
                *
            ,   CASE WHEN strftime('%Y/%m', ReportDate) < '2023/04' THEN '2022-2023'
                     WHEN strftime('%Y/%m', ReportDate) < '2024/04' THEN '2023-2024'
                     WHEN strftime('%Y/%m', ReportDate) < '2025/04' THEN '2024-2025'
                     WHEN strftime('%Y/%m', ReportDate) < '2026/04' THEN '2025-2026'
                     ELSE 'Out_of_range'
                END AS policy_year
            FROM acc
        )
        ,
        crimes AS(
                SELECT
                    count(*) incidents
                ,	policy_year
                ,	COUNT(CASE WHEN FireArmInvolved LIKE 'y%' THEN 1 END)  firearms 
                FROM
                    year_labels
                GROUP BY
                    policy_year
                )
        ,
                homicide AS (	-- Determine homicide rate over the years
                    SELECT
                        COUNT(*) homicides
                    , 	policy_year

                    FROM
                        year_labels
                    WHERE
                    FireArmInvolved LIKE 'y%' AND
                    NibrsUcrCode = '09A' -- 09a is the code for Murder in the NIBRS_Offense
                    GROUP BY
                        policy_year
                    )	
        SELECT
            c.firearms
        ,	h.homicides
        ,	c.incidents
        ,	ROUND((c.firearms *1.0 /c.incidents *1.0),4) *100.0 pcnt_firearms
        ,	ROUND((h.homicides *1.0/c.incidents *1.0),4) *100.00 pcnt_crime
        ,	c.policy_year
        FROM
            crimes c
        JOIN
            homicide h
ON	c.policy_year = h.policy_year
"""

table = pd.read_sql_query(query, conn)

conn.close()

# - Prepare data for vis
# - Q1 vis firearm percentages
fig, ax = plt.subplots(figsize=(10,6))
 
bars = ax.bar(table["policy_year"],table["pcnt_firearms"])
for bar in bars:
    height = bar.get_height()
    x_pos = bar.get_x() + bar.get_width()/2
    ax.annotate(f"{height:.2f}%", xy=(x_pos, height), ha='center', va='bottom')
ax.set_xlabel("Policy Years")
ax.set_ylabel("Percent of reported incidents involving a firearm")
ax.set_title("Percentage of Firearm Incidents over the Years")
 
plt.savefig("../outputs/firearm.png")
plt.show()
 
 
# - Q2 vis homicides
fig, ax = plt.subplots(figsize=(10,6))
 
bars = ax.bar(table["policy_year"],table["homicides"])
for bar in bars:
    height = bar.get_height()
    x_pos = bar.get_x() + bar.get_width()/2
    ax.annotate(f"{height}", xy=(x_pos, height), ha='center', va='bottom')
ax.set_xlabel("Policy Years")
ax.set_ylabel("Number of Firearm Homicides")
ax.set_title("Number of Firearm Homicides over the Years")
 
plt.savefig("../outputs/homicides.png")
plt.show()
 
# - Q3 vis incidents/homicides
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
 
# ---- Left panel: total reported incidents ----
bars = ax1.bar(table["policy_year"], table["incidents"])
for bar in bars:
    height = bar.get_height()
    x_pos = bar.get_x() + bar.get_width() / 2
    ax1.annotate(f"{height:,}", xy=(x_pos, height), ha="center", va="bottom")
 
ax1.set_title("Total reported incidents")
ax1.set_xlabel("Policy Years")
ax1.set_ylabel("Reported incidents")
ax1.set_ylim(0, table["incidents"].max() * 1.15)   # headroom above the tallest bar
ax1.yaxis.set_major_formatter(FuncFormatter(lambda x, _: f"{x:,.0f}"))
 
# ---- Right panel: firearm homicides ----
ax2.plot(table["policy_year"], table["homicides"], color="red", marker="o")
for x, y in zip(table["policy_year"], table["homicides"]):
    ax2.annotate(f"{y:,}", xy=(x, y), xytext=(0, 8),
                 textcoords="offset points", ha="center")
 
ax2.set_title("Firearm homicides")
ax2.set_xlabel("Policy Years")
ax2.set_ylabel("Firearm homicides")
ax2.set_ylim(0, 170)
 
# ---- Whole figure ----
fig.suptitle("Total reported incidents and firearm homicides by policy year")
plt.tight_layout()
plt.savefig("../outputs/trend.png", bbox_inches="tight")
plt.show()