######################################################
# Project: Safe haven or Wild West
# Filename: 00_profile.py
# Business Question: Since the inception of Constitutional Carry,
#                    with the guidance of Mayor Dickens, has Atlanta
#                    seen a drop in firearm related fatalites?
# Purpose: Reveal whether Atlanta is a Safe haven or the Wild west
#          since the start of Constitutional Carry and the Dickens era
# Author: J.Glenn
# Date: 2026-07-31
######################################################

# - Import libraries
import pandas as pd
import numpy as np

# - import CSV file
acc = pd.read_csv("../data/OpenDataWebsite_Crime_view_-7629051982797370750.csv", 
                  dtype={'IncidentNumber': str}, 
                  low_memory=False)
# - Explore data
print(acc.shape)
print(acc.dtypes)
print(acc.info())
print(acc.duplicated().sum())

# - Transform ReportDate to get date range
acc["ReportDate"] = pd.to_datetime(acc["ReportDate"], format='mixed')

print(acc["ReportDate"].min())
print(acc["ReportDate"].max())