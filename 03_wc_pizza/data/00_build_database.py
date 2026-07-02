"""
WC Pizza Co — 00_build_database.py
Generates and loads all nine tables into wc_pizza.db

Realistic data quality issues are scattered randomly throughout —
consistent with what you would find walking into a 5-location local business
whose data has been touched by multiple managers over several years.

Known intentional structural issues:
    - wc_shifts_actual  : uses employee names instead of employee IDs
    - wc_inventory      : uses ingredient names instead of product IDs

Additional realistic messiness (randomly distributed):
    - Inconsistent store name casing and formatting across tables
    - Employee name typos, nicknames, missing fields
    - Mixed date formats
    - Order type inconsistent labeling
    - Duplicate order rows (system re-submission artifacts)
    - Null pay rates for a small number of records
    - Shift labels inconsistently capitalized
    - Inventory last_updated dates inconsistent across stores
    - Null reorder points on ~10% of inventory rows

Data range : January 1 – June 30, 2026 (actuals)
             July 1  – July 31, 2026   (forecast)
"""

import sqlite3
import pandas as pd
import numpy as np
import random
import os
from datetime import date, timedelta, datetime

random.seed(42)
np.random.seed(42)

DB_PATH = os.path.join(os.path.dirname(__file__), "wc_pizza.db")

# ═════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═════════════════════════════════════════════════════════════════════════════

LOCATIONS = {
    1: {"name": "Downtown",   "neighborhood": "Downtown Atlanta",  "personality": "reactive"},
    2: {"name": "Decatur",    "neighborhood": "Decatur",           "personality": "aggressive"},
    3: {"name": "Smyrna",     "neighborhood": "Smyrna",            "personality": "reactive"},
    4: {"name": "Duluth",     "neighborhood": "Duluth",            "personality": "conservative"},
    5: {"name": "Camp Creek", "neighborhood": "Camp Creek",        "personality": "well-calibrated"},
}

# Messy store name variants — simulates different managers typing the name differently
STORE_NAME_VARIANTS = {
    "Downtown":   ["Downtown", "downtown", "DT Atlanta", "Downtown ATL", "downtown atl"],
    "Decatur":    ["Decatur", "DECATUR", "Decatur GA", "decatur"],
    "Smyrna":     ["Smyrna", "smyrna", "Smyrna GA", "SMYRNA"],
    "Duluth":     ["Duluth", "duluth", "Duluth GA", "Duluth-GA"],
    "Camp Creek": ["Camp Creek", "camp creek", "CampCreek", "Camp Crk", "CAMP CREEK"],
}

GAME_DAY_DEMAND_LIFT = {
    "Downtown":   2.4,
    "Decatur":    1.6,
    "Smyrna":     1.3,
    "Duluth":     1.8,
    "Camp Creek": 1.2,
}

PERSONALITY_PROFILES = {
    "conservative": {
        "schedule_bias":              1.25,
        "actual_vs_scheduled":        0.95,
        "game_day_schedule_response": 1.10,
    },
    "aggressive": {
        "schedule_bias":              1.40,
        "actual_vs_scheduled":        1.05,
        "game_day_schedule_response": 1.35,
    },
    "reactive": {
        "schedule_bias":              0.85,
        "actual_vs_scheduled":        1.15,
        "game_day_schedule_response": 0.90,
    },
    "well-calibrated": {
        "schedule_bias":              1.05,
        "actual_vs_scheduled":        1.00,
        "game_day_schedule_response": 1.60,
    },
}

SHIFTS = {
    "morning":   {"start": "08:00", "end": "14:00", "hours": 6},
    "afternoon": {"start": "14:00", "end": "20:00", "hours": 6},
    "evening":   {"start": "20:00", "end": "24:00", "hours": 4},
}

# Messy shift label variants
SHIFT_LABEL_VARIANTS = {
    "morning":   ["morning", "Morning", "MORNING", "AM", "am shift"],
    "afternoon": ["afternoon", "Afternoon", "AFTERNOON", "PM", "mid"],
    "evening":   ["evening", "Evening", "EVENING", "PM2", "night", "closing"],
}

BASE_ORDERS = {
    "Downtown":   {"morning": 28, "afternoon": 45, "evening": 38},
    "Decatur":    {"morning": 18, "afternoon": 30, "evening": 25},
    "Smyrna":     {"morning": 20, "afternoon": 32, "evening": 22},
    "Duluth":     {"morning": 22, "afternoon": 35, "evening": 28},
    "Camp Creek": {"morning": 15, "afternoon": 25, "evening": 18},
}

WEEKEND_LIFT      = 1.20
JULY_FORECAST_LIFT = 1.05

ATLANTA_GAME_DAYS = {
    date(2026, 6, 15): {"kickoff": "12:00", "match": "Spain vs. Cape Verde",     "stage": "Group"},
    date(2026, 6, 18): {"kickoff": "12:00", "match": "Czechia vs. South Africa", "stage": "Group"},
    date(2026, 6, 21): {"kickoff": "12:00", "match": "Spain vs. Saudi Arabia",   "stage": "Group"},
    date(2026, 6, 24): {"kickoff": "18:00", "match": "Morocco vs. Haiti",        "stage": "Group"},
    date(2026, 6, 27): {"kickoff": "19:30", "match": "Congo DR vs. Uzbekistan",  "stage": "Group"},
    date(2026, 7,  1): {"kickoff": "12:00", "match": "England vs. Congo DR",     "stage": "Round of 32"},
    date(2026, 7,  7): {"kickoff": "12:00", "match": "TBD vs. TBD",              "stage": "Round of 16", "confirmed": False},
    date(2026, 7, 15): {"kickoff": "15:00", "match": "TBD vs. TBD",              "stage": "Semifinal",   "confirmed": False},
}

PRODUCTS = [
    (1,  "Classic Pepperoni",   "Pizza",     14.99),
    (2,  "Margherita",          "Pizza",     12.99),
    (3,  "BBQ Chicken",         "Pizza",     15.99),
    (4,  "Veggie Supreme",      "Pizza",     13.99),
    (5,  "Meat Lovers",         "Pizza",     16.99),
    (6,  "Buffalo Chicken",     "Pizza",     15.49),
    (7,  "Cheese Breadsticks",  "Sides",      6.99),
    (8,  "Garlic Knots",        "Sides",      5.99),
    (9,  "Caesar Salad",        "Salads",     8.99),
    (10, "House Salad",         "Salads",     7.99),
    (11, "Soft Drink",          "Beverages",  2.99),
    (12, "Bottled Water",       "Beverages",  1.99),
    (13, "Craft Beer",          "Beverages",  5.99),
    (14, "Chicken Wings",       "Sides",      9.99),
    (15, "Chocolate Lava Cake", "Desserts",   5.99),
]

RECIPES = {
    1:  [("pizza_dough",1,"ball"),("tomato_sauce",0.25,"cup"),("mozzarella",0.5,"lb"),("pepperoni",0.25,"lb")],
    2:  [("pizza_dough",1,"ball"),("tomato_sauce",0.25,"cup"),("mozzarella",0.5,"lb"),("fresh_basil",0.1,"oz")],
    3:  [("pizza_dough",1,"ball"),("bbq_sauce",0.25,"cup"),("mozzarella",0.5,"lb"),("chicken_breast",0.3,"lb")],
    4:  [("pizza_dough",1,"ball"),("tomato_sauce",0.25,"cup"),("mozzarella",0.4,"lb"),("bell_peppers",0.2,"lb"),("mushrooms",0.15,"lb"),("onions",0.1,"lb")],
    5:  [("pizza_dough",1,"ball"),("tomato_sauce",0.25,"cup"),("mozzarella",0.5,"lb"),("pepperoni",0.15,"lb"),("italian_sausage",0.2,"lb"),("bacon",0.1,"lb")],
    6:  [("pizza_dough",1,"ball"),("buffalo_sauce",0.25,"cup"),("mozzarella",0.5,"lb"),("chicken_breast",0.3,"lb")],
    7:  [("pizza_dough",0.5,"ball"),("mozzarella",0.3,"lb"),("garlic_butter",0.1,"cup")],
    8:  [("pizza_dough",0.5,"ball"),("garlic_butter",0.1,"cup"),("parmesan",0.1,"lb")],
    9:  [("romaine_lettuce",0.3,"lb"),("parmesan",0.05,"lb"),("caesar_dressing",0.1,"cup"),("croutons",0.1,"cup")],
    10: [("romaine_lettuce",0.3,"lb"),("tomatoes",0.1,"lb"),("onions",0.05,"lb"),("house_dressing",0.1,"cup")],
    11: [("fountain_syrup",0.1,"cup")],
    12: [("bottled_water",1,"unit")],
    13: [("craft_beer",1,"unit")],
    14: [("chicken_wings",0.75,"lb"),("buffalo_sauce",0.15,"cup")],
    15: [("chocolate_mix",0.25,"lb"),("eggs",1,"unit"),("butter",0.05,"lb")],
}

PRODUCT_WEIGHTS = {
    "morning":   [8, 10, 6, 8, 5, 5, 12, 10, 8, 8, 10, 5, 1, 2, 2],
    "afternoon": [12, 10, 10, 8, 8, 8, 8, 6, 5, 5, 8, 4, 2, 4, 2],
    "evening":   [14, 8, 12, 6, 12, 10, 5, 4, 3, 3, 6, 2, 8, 5, 2],
}

PAY_RATES = {
    "General Manager": 28.00,
    "Shift Lead":       18.00,
    "Cook":             16.00,
    "Cashier":          14.00,
    "Delivery Driver":  13.00,
    "Server":           12.00,
}

OVERTIME_MULTIPLIER = 1.5

# ═════════════════════════════════════════════════════════════════════════════
# MESSINESS HELPERS
# ═════════════════════════════════════════════════════════════════════════════

def messy_date(d):
    """Randomly return date in one of several formats — simulates manual entry."""
    fmt = random.choices(
        ["%Y-%m-%d", "%m/%d/%Y", "%m-%d-%Y", "%Y/%m/%d"],
        weights=[0.70, 0.15, 0.10, 0.05]
    )[0]
    return d.strftime(fmt)

def messy_store_name(canonical_name):
    """Return a random variant of the store name."""
    variants = STORE_NAME_VARIANTS.get(canonical_name, [canonical_name])
    return random.choices(variants, weights=[0.60, 0.15, 0.10, 0.10, 0.05][:len(variants)])[0]

def messy_shift_label(shift_name):
    """Return a random variant of the shift label."""
    variants = SHIFT_LABEL_VARIANTS.get(shift_name, [shift_name])
    w = [1.0 / len(variants)] * len(variants)
    return random.choices(variants, weights=w)[0]

def messy_order_type(order_type):
    """Inconsistent order type labels."""
    variants = {
        "dine-in":  ["dine-in", "Dine-In", "DINE IN", "eat in", "dine in"],
        "takeout":  ["takeout", "Takeout", "TAKEOUT", "take out", "take-out", "TO"],
        "delivery": ["delivery", "Delivery", "DELIVERY", "deliv", "DLV"],
    }
    v = variants.get(order_type, [order_type])
    return random.choices(v, weights=[0.60, 0.15, 0.08, 0.10, 0.05, 0.02][:len(v)])[0]

def messy_employee_name(name):
    """Occasionally corrupt a name — typo, nickname, missing last name."""
    roll = random.random()
    if roll < 0.04:
        # Drop last name
        return name.split()[0]
    elif roll < 0.07:
        # Add a typo — swap two chars in last name
        parts = name.split()
        last = list(parts[-1])
        if len(last) > 2:
            i = random.randint(0, len(last) - 2)
            last[i], last[i+1] = last[i+1], last[i]
        return parts[0] + " " + "".join(last)
    elif roll < 0.09:
        # Nickname — shorten first name
        parts = name.split()
        return parts[0][:3] + ". " + parts[-1]
    return name

# ═════════════════════════════════════════════════════════════════════════════
# TABLE BUILDERS
# ═════════════════════════════════════════════════════════════════════════════

def build_calendar():
    rows = []
    current = date(2026, 1, 1)
    while current <= date(2026, 7, 31):
        is_game_day = current in ATLANTA_GAME_DAYS
        gd          = ATLANTA_GAME_DAYS.get(current, {})
        rows.append({
            "date":            current.isoformat(),
            "day_of_week":     current.strftime("%A"),
            "is_weekend":      int(current.weekday() >= 5),
            "is_game_day":     int(is_game_day),
            "kickoff_time":    gd.get("kickoff"),
            "match":           gd.get("match"),
            "stage":           gd.get("stage"),
            "match_confirmed": gd.get("confirmed", True) if is_game_day else None,
            "is_forecast":     int(current >= date(2026, 7, 1)),
        })
        current += timedelta(days=1)
    return pd.DataFrame(rows)


def build_stores():
    managers = {1:"Marcus Webb", 2:"Tanya Osei", 3:"Carlos Rivera", 4:"Jin Park", 5:"Alicia Fontaine"}
    rows = []
    for sid, info in LOCATIONS.items():
        rows.append({
            "store_id":     sid,
            "store_name":   info["name"],
            "neighborhood": info["neighborhood"],
            "personality":  info["personality"],
            "manager":      managers[sid],
            "phone":        f"404-55{sid}-{1000 + sid * 111:04d}",
            "seating":      random.choice([30, 40, 50]),
            "delivery":     1,
            "takeout":      1,
        })
    return pd.DataFrame(rows)


def build_employees():
    first_names = ["James","Maria","Devon","Priya","Chloe","Andre","Sofia","Marcus",
                   "Jasmine","Tyler","Kezia","Rami","Natalie","Jordan","Luis","Amara",
                   "Chris","Fatima","Derek","Yuki","Brianna","Omar","Tasha","Kevin",
                   "Lena","Darius","Mei","Patrick","Simone","Aaron","Renee","Kwame",
                   "Destiny","Hector","Ingrid","Theo","Zoe","Miles","Layla","Finn"]
    last_names  = ["Johnson","Williams","Brown","Davis","Martinez","Garcia","Wilson",
                   "Moore","Taylor","Anderson","Thomas","Jackson","White","Harris",
                   "Martin","Thompson","Young","Lewis","Walker","Hall","Allen","Scott",
                   "Green","Baker","Adams","Nelson","Carter","Mitchell","Perez","Roberts"]

    staffing = {"General Manager":1,"Shift Lead":2,"Cook":4,"Cashier":3,"Delivery Driver":3,"Server":3}
    rows = []
    emp_id = 1
    used_names = set()

    for store_id in LOCATIONS:
        for title, count in staffing.items():
            for _ in range(count):
                while True:
                    name = f"{random.choice(first_names)} {random.choice(last_names)}"
                    if name not in used_names:
                        used_names.add(name)
                        break
                # ~5% chance pay rate is null (data was never entered)
                pay = PAY_RATES[title] if random.random() > 0.05 else None
                rows.append({
                    "employee_id":   emp_id,
                    "employee_name": name,
                    "store_id":      store_id,
                    "title":         title,
                    "pay_rate":      pay,
                    "tenure_months": random.randint(1, 48),
                    "availability":  random.choice(["Full-Time","Part-Time","full-time","part-time"]),
                    "active":        1 if random.random() > 0.05 else 0,
                })
                emp_id += 1

    return pd.DataFrame(rows)


def build_products():
    rows = []
    for pid, name, category, price in PRODUCTS:
        cost = round(price * random.uniform(0.28, 0.38), 2)
        rows.append({
            "product_id":   pid,
            "product_name": name,
            "category":     category,
            "price":        price,
            "cogs":         cost,
        })
    return pd.DataFrame(rows)


def build_orders_and_items(df_calendar, df_employees):
    order_rows = []
    item_rows  = []
    order_id   = 1
    product_ids = [p[0] for p in PRODUCTS]

    for _, cal_row in df_calendar.iterrows():
        d           = date.fromisoformat(cal_row["date"])
        is_game_day = bool(cal_row["is_game_day"])
        is_weekend  = bool(cal_row["is_weekend"])
        is_forecast = bool(cal_row["is_forecast"])
        kickoff     = cal_row["kickoff_time"]

        for store_id, loc_info in LOCATIONS.items():
            loc_name  = loc_info["name"]
            game_lift = GAME_DAY_DEMAND_LIFT[loc_name] if is_game_day else 1.0
            wknd_lift = WEEKEND_LIFT if is_weekend else 1.0
            fcst_lift = JULY_FORECAST_LIFT if is_forecast else 1.0

            for shift_name, shift_info in SHIFTS.items():
                kickoff_lift = 1.0
                if is_game_day and kickoff:
                    kh = int(kickoff.split(":")[0])
                    if kh <= 13 and shift_name == "afternoon": kickoff_lift = 1.4
                    elif kh <= 13 and shift_name == "morning":  kickoff_lift = 1.2
                    elif kh >= 17 and shift_name == "evening":  kickoff_lift = 1.5
                    elif kh >= 17 and shift_name == "afternoon":kickoff_lift = 1.3

                base     = BASE_ORDERS[loc_name][shift_name]
                n_orders = int(round(base * game_lift * wknd_lift * fcst_lift * kickoff_lift * random.uniform(0.88, 1.12)))
                n_orders = max(n_orders, 1)

                weights     = PRODUCT_WEIGHTS[shift_name]
                norm_w      = [w / sum(weights) for w in weights]
                order_types = ["dine-in","takeout","delivery"]
                ot_weights  = [0.40, 0.40, 0.20]

                for _ in range(n_orders):
                    raw_type   = random.choices(order_types, weights=ot_weights)[0]
                    order_type = messy_order_type(raw_type)

                    # ~1.5% chance of duplicate (re-submitted order artifact)
                    is_duplicate = random.random() < 0.015

                    # Messy date format on ~20% of orders
                    order_date = messy_date(d) if random.random() < 0.20 else d.isoformat()

                    # Messy store name on ~30% of orders
                    store_label = messy_store_name(loc_name) if random.random() < 0.30 else loc_name

                    # Messy shift label on ~25% of orders
                    shift_label = messy_shift_label(shift_name) if random.random() < 0.25 else shift_name

                    order_rows.append({
                        "order_id":    order_id,
                        "store_id":    store_id,
                        "store_name":  store_label,
                        "date":        order_date,
                        "shift":       shift_label,
                        "order_type":  order_type,
                        "is_game_day": int(is_game_day),
                        "is_forecast": int(is_forecast),
                        "is_duplicate":int(is_duplicate),
                    })

                    n_items = random.choices([1, 2, 3], weights=[0.45, 0.40, 0.15])[0]
                    chosen  = np.random.choice(product_ids, size=n_items, replace=False, p=norm_w)

                    for prod_id in chosen:
                        prod = next(p for p in PRODUCTS if p[0] == prod_id)
                        qty  = random.randint(1, 2)
                        item_rows.append({
                            "order_item_id": len(item_rows) + 1,
                            "order_id":      order_id,
                            "product_id":    prod_id,
                            "quantity":      qty,
                            "unit_price":    prod[3],
                            "line_total":    round(prod[3] * qty, 2),
                        })

                    order_id += 1

    return pd.DataFrame(order_rows), pd.DataFrame(item_rows)


def build_shifts_scheduled(df_calendar, df_employees):
    rows = []
    shift_id = 1

    for _, cal_row in df_calendar.iterrows():
        d           = date.fromisoformat(cal_row["date"])
        is_game_day = bool(cal_row["is_game_day"])
        is_weekend  = bool(cal_row["is_weekend"])
        is_forecast = bool(cal_row["is_forecast"])

        for store_id, loc_info in LOCATIONS.items():
            loc_name    = loc_info["name"]
            personality = loc_info["personality"]
            profile     = PERSONALITY_PROFILES[personality]

            for shift_name, shift_info in SHIFTS.items():
                base_need = max(2, round(BASE_ORDERS[loc_name][shift_name] / 8))

                if is_game_day:
                    lift      = GAME_DAY_DEMAND_LIFT[loc_name]
                    response  = profile["game_day_schedule_response"]
                    scheduled = max(2, round(base_need * lift * response * profile["schedule_bias"]))
                elif is_weekend:
                    scheduled = max(2, round(base_need * WEEKEND_LIFT * profile["schedule_bias"]))
                else:
                    scheduled = max(2, round(base_need * profile["schedule_bias"]))

                store_leads = df_employees[
                    (df_employees["store_id"] == store_id) &
                    (df_employees["title"] == "Shift Lead")
                ]
                lead = store_leads.sample(1)["employee_name"].values[0] if len(store_leads) > 0 else "TBD"

                # Messy shift label on ~20% of scheduled rows
                shift_label = messy_shift_label(shift_name) if random.random() < 0.20 else shift_name

                rows.append({
                    "schedule_id":     shift_id,
                    "store_id":        store_id,
                    "date":            cal_row["date"],
                    "shift":           shift_label,
                    "shift_start":     shift_info["start"],
                    "shift_end":       shift_info["end"],
                    "scheduled_staff": scheduled,
                    "shift_lead":      lead,
                    "is_game_day":     int(is_game_day),
                    "is_forecast":     int(is_forecast),
                })
                shift_id += 1

    return pd.DataFrame(rows)


def build_shifts_actual(df_shifts_scheduled, df_employees):
    """
    Intentional DQ issue: employee_name used instead of employee_id.
    Names also subject to messy_employee_name corruption.
    """
    rows     = []
    actual_id = 1
    actuals  = df_shifts_scheduled[df_shifts_scheduled["is_forecast"] == 0].copy()

    for _, sched_row in actuals.iterrows():
        store_id    = sched_row["store_id"]
        personality = LOCATIONS[store_id]["personality"]
        profile     = PERSONALITY_PROFILES[personality]
        scheduled   = int(sched_row["scheduled_staff"])
        shift_name  = sched_row["shift"]

        # Normalize shift name back to key for hours lookup
        shift_key = "morning"
        for k in SHIFTS:
            if shift_name.lower().startswith(k[:3]) or shift_name.lower() in SHIFT_LABEL_VARIANTS[k]:
                shift_key = k
                break
        shift_hours = SHIFTS[shift_key]["hours"]

        store_emps = df_employees[
            (df_employees["store_id"] == store_id) &
            (df_employees["title"].isin(["Cook","Cashier","Server","Delivery Driver","Shift Lead"]))
        ]
        if len(store_emps) == 0:
            continue

        n_actual = max(1, int(round(scheduled * random.uniform(0.90, 1.10))))
        sampled  = store_emps.sample(min(n_actual, len(store_emps)), replace=False)

        for _, emp in sampled.iterrows():
            ratio         = profile["actual_vs_scheduled"]
            actual_hours  = round(shift_hours * ratio * random.uniform(0.92, 1.08), 2)
            actual_hours  = min(actual_hours, shift_hours + 2)
            overtime_hrs  = max(0, round(actual_hours - shift_hours, 2))
            pay           = emp["pay_rate"] if pd.notna(emp["pay_rate"]) else None
            labor_cost    = round(
                (min(actual_hours, shift_hours) * pay) +
                (overtime_hrs * pay * OVERTIME_MULTIPLIER), 2
            ) if pay else None

            # Messy date format on ~15% of actual rows
            row_date = messy_date(date.fromisoformat(sched_row["date"])) if random.random() < 0.15 else sched_row["date"]

            rows.append({
                "actual_id":       actual_id,
                "store_id":        store_id,
                "date":            row_date,
                "shift":           shift_name,
                # INTENTIONAL DQ: name not ID, with occasional corruption
                "employee_name":   messy_employee_name(emp["employee_name"]),
                "pay_rate":        pay,
                "scheduled_hours": shift_hours,
                "actual_hours":    actual_hours,
                "overtime_hours":  overtime_hrs,
                "labor_cost":      labor_cost,
                "is_game_day":     sched_row["is_game_day"],
            })
            actual_id += 1

    return pd.DataFrame(rows)


def build_inventory(df_products):
    """
    Intentional DQ issue: ingredient_name used instead of product_id.
    last_updated dates vary by store and are not always current.
    """
    all_ingredients = {}
    for prod_id, recipe in RECIPES.items():
        for ingredient, qty, unit in recipe:
            if ingredient not in all_ingredients:
                all_ingredients[ingredient] = unit

    stock_bias = {
        "Downtown":   0.85,
        "Decatur":    1.40,
        "Smyrna":     0.80,
        "Duluth":     1.20,
        "Camp Creek": 1.00,
    }

    # Each store has a different "last updated" — some are stale
    last_updated_by_store = {
        1: "2026-06-30",
        2: "2026-06-28",
        3: "2026-06-15",   # Smyrna — stale by two weeks
        4: "2026-06-30",
        5: "2026-06-29",
    }

    rows   = []
    inv_id = 1

    for store_id, loc_info in LOCATIONS.items():
        loc_name = loc_info["name"]
        bias     = stock_bias[loc_name]

        for ingredient, unit in all_ingredients.items():
            base_qty = round(random.uniform(8.0, 25.0) * bias, 2)

            if loc_info["personality"] == "reactive" and random.random() < 0.15:
                base_qty = round(random.uniform(0.5, 3.0), 2)

            rows.append({
                "inventory_id":     inv_id,
                "store_id":         store_id,
                # INTENTIONAL DQ: ingredient name not product ID
                "ingredient_name":  ingredient,
                "unit":             unit,
                "quantity_on_hand": base_qty,
                "last_updated":     last_updated_by_store[store_id],
                "reorder_point":    round(random.uniform(2.0, 6.0), 2) if random.random() > 0.10 else None,
            })
            inv_id += 1

    return pd.DataFrame(rows)


# ═════════════════════════════════════════════════════════════════════════════
# LOAD
# ═════════════════════════════════════════════════════════════════════════════

def load_to_db(conn, table_name, df):
    df.to_sql(table_name, conn, if_exists="replace", index=False)
    print(f"  ✓  {table_name:<25} {len(df):>7,} rows")


def main():
    print("\n── WC Pizza Co · Database Build ─────────────────────────────")
    print(f"   Output: {DB_PATH}\n")

    print("Building tables...")
    df_calendar  = build_calendar()
    df_stores    = build_stores()
    df_employees = build_employees()
    df_products  = build_products()
    print("  ✓  calendar, stores, employees, products ready")

    df_orders, df_order_items = build_orders_and_items(df_calendar, df_employees)
    print("  ✓  orders and order_items ready")

    df_scheduled = build_shifts_scheduled(df_calendar, df_employees)
    print("  ✓  shifts_scheduled ready")

    df_actual    = build_shifts_actual(df_scheduled, df_employees)
    print("  ✓  shifts_actual ready")

    df_inventory = build_inventory(df_products)
    print("  ✓  inventory ready")

    print("\nLoading to SQLite...")
    conn = sqlite3.connect(DB_PATH)
    load_to_db(conn, "wc_calendar",         df_calendar)
    load_to_db(conn, "wc_stores",           df_stores)
    load_to_db(conn, "wc_employees",        df_employees)
    load_to_db(conn, "wc_products",         df_products)
    load_to_db(conn, "wc_orders",           df_orders)
    load_to_db(conn, "wc_order_items",      df_order_items)
    load_to_db(conn, "wc_shifts_scheduled", df_scheduled)
    load_to_db(conn, "wc_shifts_actual",    df_actual)
    load_to_db(conn, "wc_inventory",        df_inventory)
    conn.close()

    total = sum([len(df_calendar), len(df_stores), len(df_employees), len(df_products),
                 len(df_orders), len(df_order_items), len(df_scheduled), len(df_actual), len(df_inventory)])

    print(f"\n── Build complete ────────────────────────────────────────────")
    print(f"   Total rows: {total:,}")
    print(f"   Database  : {DB_PATH}\n")


if __name__ == "__main__":
    main()