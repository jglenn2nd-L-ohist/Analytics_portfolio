##################################################
# Project: Quota and Commission Model (09_quota_model)
# File name: load_data.py
# Business question: Does the flat-tier commission
#                    structure overpay, and if so,
#                    where and by how much?
# Purpose:   Load the generated CSVs into the tables
#            created by 01_create_tables.sql
# Author: J.Glenn
# Date: October 2026
###################################################

# - import libraries
import pandas as pd
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

# - connect to SQL Server (Windows authentication)
url = URL.create(
    "mssql+pyodbc",
    host=r".\sqlexpress",
    database="quota_model",
    query={
        "driver": "ODBC Driver 18 for SQL Server",
        "trusted_connection": "yes",
        "TrustServerCertificate": "yes",
    },
)
engine = create_engine(url, fast_executemany=True)

# - read the csv files
data_dir = Path(__file__).resolve().parent.parent / "data" / "raw"
regions = pd.read_csv(data_dir / "regions.csv")
reps = pd.read_csv(data_dir / "reps.csv", parse_dates=["hire_date","term_date"]).drop(columns=["skill_factor"])
calendar = pd.read_csv(data_dir / "calendar.csv", parse_dates=["month_start","month_end","payout_date"])
sales = pd.read_csv(data_dir / "sales.csv", parse_dates=["sale_date","status_date"])

# - load into the existing tables
regions.to_sql("regions", engine, schema="dbo", if_exists="append", index=False)
reps.to_sql("reps", engine, schema="dbo", if_exists="append", index=False)
calendar.to_sql("calendar", engine, schema="dbo", if_exists="append", index=False)
sales.to_sql("sales", engine, schema="dbo", if_exists="append", index=False)