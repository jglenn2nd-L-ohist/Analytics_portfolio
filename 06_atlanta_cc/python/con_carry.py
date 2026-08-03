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

# - import and query data
conn = sq.connect("../data/acc.db")

query = """
        WITH crimes AS(
                SELECT
                    count(*) incidents
                ,	strftime('%Y', ReportDate) inc_year
                ,	COUNT(CASE WHEN FireArmInvolved LIKE 'y%' THEN 1 END)  firearms 
                FROM
                    acc
                GROUP BY
                    inc_year
                )
        ,
                homicide AS (	-- Determine homicide rate over the years
                    SELECT
                        COUNT(*) homicides
                    , 	strftime('%Y', ReportDate) inc_year

                    FROM
                        acc
                    WHERE
                    NibrsUcrCode = '09A' -- 09a is the code for Murder in the NIBRS_Offense
                    GROUP BY
                        inc_year
                    )	
        SELECT
            c.firearms
        ,	h.homicides
        ,	c.incidents
        ,	ROUND((c.firearms *1.0 /c.incidents *1.0),4) *100.0 pcnt_firearms
        ,	ROUND((h.homicides *1.0/c.incidents *1.0),4) *100.00 pcnt_crime
        ,	c.inc_year
        FROM
            crimes c
        JOIN
            homicide h
ON	c.inc_year = h.inc_year
"""

table = pd.read_sql_query(query, conn)

conn.close()

# - Prepare data for vis
# - Q1 vis firearm percentages
fig, ax = plt.subplots(figsize=(10,6))

bars = ax.bar(table["inc_year"],table["pcnt_firearms"])
for bar in bars:
    height = bar.get_height()
    x_pos = bar.get_x() + bar.get_width()/2
    ax.annotate(f"{height:.2f}%", xy=(x_pos, height), ha='center', va='bottom')
ax.set_xlabel("Years")
ax.set_ylabel("Percent of Crime")
ax.set_title("Percentage of Firearm Incidents over the Years {2026 represents partial year data}")

plt.savefig("../outputs/firearm.png")
plt.show()


# - Q2 vis homicides
fig, ax = plt.subplots(figsize=(10,6))

bars = ax.bar(table["inc_year"],table["homicides"])
for bar in bars:
    height = bar.get_height()
    x_pos = bar.get_x() + bar.get_width()/2
    ax.annotate(f"{height}", xy=(x_pos, height), ha='center', va='bottom')
ax.set_xlabel("Years")
ax.set_ylabel("Number of Homicides")
ax.set_title("Number of Homicide Incidents over the Years {2026 represents partial year data}")

plt.savefig("../outputs/homicides.png")
plt.show()

# - Q3 vis incidents/homicides
fig, ax = plt.subplots(figsize=(10,6))
ax2= ax.twinx()


bars = ax.bar(table["inc_year"],table["incidents"], label="Total Crimes")
for bar in bars:
    height = bar.get_height()
    x_pos = bar.get_x() + bar.get_width()/2
    ax.annotate(f"{height}", xy=(x_pos, height), ha='center', va='bottom')
ax.set_xlabel("Years")
ax.set_title("Crime incidents with homicide numbers over the Years {2026 represents partial year data}")
ax.legend(loc="upper left")
ax2.plot(table["inc_year"], table["homicides"], color='red', marker='o', label="Homicides")
ax2.legend(loc="upper right")
ax2.set_ylim(bottom=5, top=170)

plt.savefig("../outputs/trend.png")
plt.show()
