######################################################
# Project: Global Superstore Operations Analysis
# Filename: 00_profile.py
# Business Question: What is the root cause of operational issues (shipping, performance & returns)?
# Purpose: Determine data irregularities, prepare for data cleaning
# Author: J.Glenn
# Date: 2026-07-21
######################################################

# - Import libraries
import pandas as pd
import numpy as np

# - Import dataset into different data frames
orders = pd.read_excel("../data/GlobalSuperstore.xls", sheet_name="Orders", engine="xlrd")
returns = pd.read_excel("../data/GlobalSuperstore.xls", sheet_name="Returns", engine="xlrd")
people = pd.read_excel("../data/GlobalSuperstore.xls", sheet_name="People", engine="xlrd")

# - Preview data sets
print("=" * 50)
print("Orders")
print("=" * 50)
print("Orders", orders.shape)
print("Orders", orders.describe())
print("Orders", orders.info())
print("null orders:", orders.isnull().sum())
print("duplicate orders:", orders.duplicated().sum())


print("=" * 50)
print("Returns")
print("=" * 50)
print("returns", returns.shape)
print("returns", returns.describe())
print("returns", returns.info())
print("duplicate returns:", returns.duplicated().sum())

print("=" * 50)
print("People")
print("=" * 50)
print("people", people.shape)
print("people", people.describe())
print("people", people.info())
print("duplicate people:", people.duplicated().sum())
