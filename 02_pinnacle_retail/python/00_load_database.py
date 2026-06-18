##  Import libraries
import sqlite3
import pandas as pd

## Connect
pinn = sqlite3.connect("../data/pinnacle.db")

## Load tables
df_transactions = pd.read_csv("../data/Pinnacle_transactions.csv")
df_customers = pd.read_csv("../data/Pinnacle_customers.csv")
df_stores = pd.read_csv("../data/Pinnacle_stores.csv")
df_inventory = pd.read_csv("../data/Pinnacle_inventory.csv")
df_products = pd.read_csv("../data/Pinnacle_products.csv")

## Write to SQL
df_transactions.to_sql("pintransact", pinn, if_exists="replace", index=False)
df_customers.to_sql("pincust", pinn, if_exists="replace", index=False)
df_stores.to_sql("pinstor", pinn, if_exists="replace", index=False)
df_inventory.to_sql("pininv", pinn, if_exists="replace", index=False)
df_products.to_sql("pinprod", pinn, if_exists="replace", index=False)

pinn.close()