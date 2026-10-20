##################################################
# Project: Quota and Commission Model (09_quota_model)
# File name: export_rep_month.py
# Business question: Does the flat-tier commission
#                    structure overpay, and if so,
#                    where and by how much?
# Purpose:   Run the rep-month extract 
#            (sql/03_rep_month_derivation.sql) 
#            against SQL Server and write 
#            data/processed/rep_month.csv
# Author: J.Glenn
# Date: October 2026
###################################################

from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

# 1. connect to SQL Server (Windows authentication)
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
engine = create_engine(url)

# 2. Paths, resolved from this script's location (as in load_data.py)
root = Path(__file__).resolve().parent.parent
sql_file = root / "sql" / "03_rep_month_derivation.sql"
out_file = root / "data" / "processed" / "rep_month.csv"

# 3. Read the extract query from the .sql file, so the SQL stays in one place
query = sql_file.read_text()

# 4. Run it
rep_month = pd.read_sql(query, engine, parse_dates=["month_start"])

# 5. Write the CSV
out_file.parent.mkdir(parents=True, exist_ok=True)
rep_month.to_csv(out_file, index=False, date_format="%Y-%m-%d")

print(len(rep_month), "rows written to", out_file)