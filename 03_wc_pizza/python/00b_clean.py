# - Import libraries
import sqlite3 as sq
import pandas as pd

# - connect to dataframe
conn = sq.connect("../data/wc_pizza.db")

# - Query orders table for cleaning
query = """
    SELECT
        *
    FROM
        wc_orders
    """

orders = pd.read_sql_query(query, conn)

# - Transform date into consistent format
orders['date'] = pd.to_datetime(orders['date'], format='mixed')
orders['date'] = orders['date'].dt.strftime('%Y-%m-%d')

# - Deduplication
orders = orders[orders['is_duplicate'] == 0]

# - Standardizing shift column
mapping = {
    'morning': 'morning',
    'Morning': 'morning',
    'MORNING': 'morning',
    'AM': 'morning',
    'am shift': 'morning',
    'afternoon': 'afternoon',
    'Afternoon': 'afternoon',
    'AFTERNOON': 'afternoon',
    'PM': 'afternoon',
    'mid': 'afternoon',
    'evening': 'evening',
    'Evening': 'evening',
    'EVENING': 'evening',
    'PM2': 'evening',
    'night': 'evening',
    'closing': 'evening'}

orders['shift'] = orders['shift'].map(mapping)

# - Standardizing order_type column
mapping = {
    'dine-in': 'dine-in',
    'Dine-In': 'dine-in',
    'eat in': 'dine-in',
    'DINE IN': 'dine-in',
    'dine in': 'dine-in',
    'takeout': 'take-out', 
    'Takeout': 'take-out', 
    'take out': 'take-out', 
    'TAKEOUT': 'take-out', 
    'take-out': 'take-out', 
    'TO': 'take-out', 
    'delivery': 'delivery',
    'Delivery': 'delivery',
    'deliv': 'delivery',
    'DELIVERY': 'delivery',
    'DLV': 'delivery'}

orders['order_type'] = orders['order_type'].map(mapping)

# - Standardize store names column
mapping = {
    'Downtown': 'Downtown',
    'downtown': 'Downtown',
    'DT Atlanta': 'Downtown',
    'Downtown ATL': 'Downtown',
    'downtown atl': 'Downtown',
    'Duluth': 'Duluth',
    'duluth': 'Duluth',
    'Duluth-GA': 'Duluth',
    'Duluth GA': 'Duluth',
    'Decatur': 'Decatur',
    'DECATUR': 'Decatur',
    'Decatur GA': 'Decatur',
    'decatur': 'Decatur',
    'Smyrna': 'Smyrna',
    'smyrna': 'Smyrna',
    'Smyrna GA': 'Smyrna',
    'SMYRNA': 'Smyrna',
    'Camp Creek': 'Camp Creek',
    'camp creek': 'Camp Creek',
    'Camp Crk': 'Camp Creek',
    'CampCreek': 'Camp Creek',
    'CAMP CREEK': 'Camp Creek'}

orders['store_name'] = orders['store_name'].map(mapping)

# - Write standardized table back to SQL
orders.to_sql('wc_orders', conn, if_exists='replace', index=False)

# - Query shifts_actual table to be cleaned
query2 = """
    SELECT
        *
    FROM
        wc_shifts_actual
"""

worked = pd.read_sql_query(query2, conn)

# - Standardize date format
worked['date'] = pd.to_datetime(worked['date'], format='mixed')
worked['date'] = worked['date'].dt.strftime('%Y-%m-%d')

# - Add wc_employee to join, so shifts_actual can include employee id
query3 = """
    SELECT
        employee_id
    ,   employee_name
    ,   title
    FROM
        wc_employees
"""

employees = pd.read_sql_query(query3, conn)

# Merge worked and employees to gain employee_id
mer_work_emp = pd.merge(employees, worked, on='employee_name', how='left')

# - Write Standardized table back to SQL
mer_work_emp.to_sql('wc_shifts_actual', conn, if_exists='replace', index=False)

# - Create wc_recipes table from RECIPES dictionary
recipes_data = [
    # product_id, ingredient_name, quantity_per_order, unit
    (1, 'pizza_dough', 1, 'ball'),
    (1, 'tomato_sauce', 0.25, 'cup'),
    (1, 'mozzarella', 0.5, 'lb'),
    (1, 'pepperoni', 0.25, 'lb'),
    (2, 'pizza_dough', 1, 'ball'),
    (2, 'tomato_sauce', 0.25, 'cup'),
    (2, 'mozzarella', 0.5, 'lb'),
    (2, 'fresh_basil', 0.1, 'oz'),
    (3, 'pizza_dough', 1, 'ball'),
    (3, 'bbq_sauce', 0.25, 'cup'),
    (3, 'mozzarella', 0.5, 'lb'),
    (3, 'chicken_breast', 0.3, 'lb'),
    (4, 'pizza_dough', 1, 'ball'),
    (4, 'tomato_sauce', 0.25, 'cup'),
    (4, 'mozzarella', 0.4, 'lb'),
    (4, 'bell_peppers', 0.2, 'lb'),
    (4, 'mushrooms', 0.15, 'lb'),
    (4, 'onions', 0.1, 'lb'),
    (5, 'pizza_dough', 1, 'ball'),
    (5, 'tomato_sauce', 0.25, 'cup'),
    (5, 'mozzarella', 0.5, 'lb'),
    (5, 'pepperoni', 0.15, 'lb'),
    (5, 'italian_sausage', 0.2, 'lb'),
    (5, 'bacon', 0.1, 'lb'),
    (6, 'pizza_dough', 1, 'ball'),
    (6, 'buffalo_sauce', 0.25, 'cup'),
    (6, 'mozzarella', 0.5, 'lb'),
    (6, 'chicken_breast', 0.3, 'lb'),
    (7, 'pizza_dough', 0.5, 'ball'),
    (7, 'mozzarella', 0.3, 'lb'),
    (7, 'garlic_butter', 0.1, 'cup'),
    (8, 'pizza_dough', 0.5, 'ball'),
    (8, 'garlic_butter', 0.1, 'cup'),
    (8, 'parmesan', 0.1, 'lb'),
    (9, 'romaine_lettuce', 0.3, 'lb'),
    (9, 'parmesan', 0.05, 'lb'),
    (9, 'caesar_dressing', 0.1, 'cup'),
    (9, 'croutons', 0.1, 'cup'),
    (10, 'romaine_lettuce', 0.3, 'lb'),
    (10, 'tomatoes', 0.1, 'lb'),
    (10, 'onions', 0.05, 'lb'),
    (10, 'house_dressing', 0.1, 'cup'),
    (11, 'fountain_syrup', 0.1, 'cup'),
    (12, 'bottled_water', 1, 'unit'),
    (13, 'craft_beer', 1, 'unit'),
    (14, 'chicken_wings', 0.75, 'lb'),
    (14, 'buffalo_sauce', 0.15, 'cup'),
    (15, 'chocolate_mix', 0.25, 'lb'),
    (15, 'eggs', 1, 'unit'),
    (15, 'butter', 0.05, 'lb'),
]

df_recipes = pd.DataFrame(recipes_data, columns=['product_id', 'ingredient_name', 'quantity_per_order', 'unit'])
df_recipes.to_sql('wc_recipes', conn, if_exists='replace', index=False)

# - Query inventory
query4 = """
    SELECT *
    FROM wc_inventory
"""
inventory = pd.read_sql_query(query4, conn)

# - Build ingredients reference table
unique_ingredients = df_recipes[['ingredient_name', 'unit']].drop_duplicates().reset_index(drop=True)
unique_ingredients['ingredient_id'] = unique_ingredients.index + 1
unique_ingredients.to_sql('wc_ingredients', conn, if_exists='replace', index=False)

# - Merge ingredient_id into inventory
inventory = pd.merge(inventory, unique_ingredients[['ingredient_id', 'ingredient_name']], on='ingredient_name', how='left')
inventory.to_sql('wc_inventory', conn, if_exists='replace', index=False)

# - Standardize shift column (actuals)
query5 = """
    SELECT
        *
    FROM
        wc_shifts_actual
    """

actual = pd.read_sql_query(query5, conn)

# - Shift dictionary
mapping = {
    'morning': 'morning',
    'Morning': 'morning',
    'MORNING': 'morning',
    'AM': 'morning',
    'am shift': 'morning',
    'afternoon': 'afternoon',
    'Afternoon': 'afternoon',
    'AFTERNOON': 'afternoon',
    'PM': 'afternoon',
    'mid': 'afternoon',
    'evening': 'evening',
    'Evening': 'evening',
    'EVENING': 'evening',
    'PM2': 'evening',
    'night': 'evening',
    'closing': 'evening'}

actual['shift'] = actual['shift'].map(mapping)

# - Write standardized table to sql file
actual.to_sql('wc_shifts_actual', conn, if_exists='replace', index=False)

# - Standardize shift column (scheduled)
query6 = """
    SELECT
        *
    FROM
        wc_shifts_scheduled
    """

sched = pd.read_sql_query(query6, conn)

# - Shift dictionary
mapping = {
    'morning': 'morning',
    'Morning': 'morning',
    'MORNING': 'morning',
    'AM': 'morning',
    'am shift': 'morning',
    'afternoon': 'afternoon',
    'Afternoon': 'afternoon',
    'AFTERNOON': 'afternoon',
    'PM': 'afternoon',
    'mid': 'afternoon',
    'evening': 'evening',
    'Evening': 'evening',
    'EVENING': 'evening',
    'PM2': 'evening',
    'night': 'evening',
    'closing': 'evening'}

sched['shift'] = sched['shift'].map(mapping)

# - Write standardized table to sql file
sched.to_sql('wc_shifts_scheduled', conn, if_exists='replace', index=False)
# - Terminate connection
conn.close()