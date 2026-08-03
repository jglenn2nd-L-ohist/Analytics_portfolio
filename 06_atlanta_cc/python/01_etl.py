######################################################
# Project: Safe haven or Wild West
# Filename: 01_etl.py
# Business Question: Since the inception of Constitutional Carry,
#                    with the guidance of Mayor Dickens, has Atlanta
#                    seen a drop in firearm related fatalites?
# Purpose: Reveal whether Atlanta is a Safe haven or the Wild west
#          since the start of Constitutional Carry and the Dickens era
# Author: J.Glenn
# Project Date Range: 2026-07-31 - 
######################################################

# - import libraries
import pandas as pd
import sqlite3 as sq

# - import data set
acc = pd.read_csv("../data/OpenDataWebsite_Crime_view_-7629051982797370750.csv", 
                  dtype={'IncidentNumber': str}, 
                  low_memory=False)

# - transform date
acc["ReportDate"] = pd.to_datetime(acc["ReportDate"],format="mixed")


# - Find and count "impossible dates"
imposs = acc.value_counts(acc["ReportDate"]<'1900/01/01')
print(imposs)
imposs = acc.value_counts(acc["ReportDate"]>'2026/08/05')
print(imposs)

# - set date scope
acc = acc[(acc["ReportDate"] >= '2022/04/01') & (acc["ReportDate"] <= '2026/03/31' )]


# - Set columns for analysis
acc = acc[["OBJECTID","FireArmInvolved","ReportDate","NIBRS_Offense","NibrsUcrCode"]]

# - create database for sql
conn = sq.connect("../data/acc.db")
acc.to_sql("acc", conn, if_exists='replace', index=False)

conn.close()