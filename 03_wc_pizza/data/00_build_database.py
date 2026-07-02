"""
WC Pizza Co — 00_build_database.py
Generates and loads all seven tables into wc_pizza.db

Tables:
    wc_calendar     — date spine, game day flags, kickoff times
    wc_stores       — five Atlanta locations
    wc_employees    — staff roster per location
    wc_orders       — order-level transactions (location + shift + date grain)
    wc_order_items  — SKU-level line items per order
    wc_products     — ingredient definitions and unit costs
    wc_inventory    — stock on hand (uses ingredient names — intentional DQ issue)
    wc_shifts_scheduled — planned staffing per location per shift
    wc_shifts_actual    — actual hours worked (uses employee names — intentional DQ issue)

Data range: January 1 – June 30, 2026 (actuals) + July 1–31, 2026 (forecast)
Rows: 10,000+
"""

import sqlite3
import pandas as pd
import numpy as np
import random
import os
from datetime import date, timedelta

# ── Reproducibility ──────────────────────────────────────────────────────────
random.seed(42)
np.random.seed(42)

# ── Database path ─────────────────────────────────────────────────────────────
DB_PATH = os.path.join(os.path.dirname(__file__), "wc_pizza.db")

# ═════════════════════════════════════════════════════════════════════════════
# CONFIGURATION — all variance lives here, not embedded in logic
# ═════════════════════════════════════════════════════════════════════════════

LOCATIONS = {
    1: {"name": "Downtown",   "neighborhood": "Downtown Atlanta",  "personality": "reactive"},
    2: {"name": "Decatur",    "neighborhood": "Decatur",           "personality": "aggressive"},
    3: {"name": "Smyrna",     "neighborhood": "Smyrna",            "personality": "reactive"},
    4: {"name": "Duluth",     "neighborhood": "Duluth",            "personality": "conservative"},
    5: {"name": "Camp Creek", "neighborhood": "Camp Creek",        "personality": "well-calibrated"},
}

# Game day demand multiplier by location — how much order volume spikes
GAME_DAY_DEMAND_LIFT = {
    "Downtown":   2.4,   # high — walkable from stadium
    "Decatur":    1.6,   # moderate
    "Smyrna":     1.3,   # moderate
    "Duluth":     1.8,   # high — large soccer-watching community
    "Camp Creek": 1.2,   # low — furthest from stadium
}

# Staffing behavior by personality
# schedule_bias: multiplier applied to scheduled staff relative to expected need
# actual_vs_scheduled: how closely actual hours track scheduled hours
# game_day_schedule_response: how well they scale scheduled staff for game days
PERSONALITY_PROFILES = {
    "conservative": {
        "schedule_bias":              1.25,   # overschedules on normal days
        "actual_vs_scheduled":        0.95,   # staff often leave a bit early
        "game_day_schedule_response": 1.10,   # cautious — doesn't scale enough for peaks
    },
    "aggressive": {
        "schedule_bias":              1.40,   # significantly overschedules
        "actual_vs_scheduled":        1.05,   # staff run over on hours
        "game_day_schedule_response": 1.35,   # throws bodies at game days — still not accurate
    },
    "reactive": {
        "schedule_bias":              0.85,   # understaffs by default
        "actual_vs_scheduled":        1.15,   # always scrambling, hours run over
        "game_day_schedule_response": 0.90,   # reacts too late — worst game day coverage
    },
    "well-calibrated": {
        "schedule_bias":              1.05,   # nearly optimal
        "actual_vs_scheduled":        1.00,   # tracks closely
        "game_day_schedule_response": 1.60,   # correctly anticipates and scales
    },
}

# Shift definitions
SHIFTS = {
    "morning":   {"start": "08:00", "end": "14:00", "hours": 6},
    "afternoon": {"start": "14:00", "end": "20:00", "hours": 6},
    "evening":   {"start": "20:00", "end": "24:00", "hours": 4},
}

# Base orders per shift on a normal weekday — by location
BASE_ORDERS = {
    "Downtown":   {"morning": 28, "afternoon": 45, "evening": 38},
    "Decatur":    {"morning": 18, "afternoon": 30, "evening": 25},
    "Smyrna":     {"morning": 20, "afternoon": 32, "evening": 22},
    "Duluth":     {"morning": 22, "afternoon": 35, "evening": 28},
    "Camp Creek": {"morning": 15, "afternoon": 25, "evening": 18},
}

# Weekend lift (non-game)
WEEKEND_LIFT = 1.20

# July is forecast — apply slight upward trend
JULY_FORECAST_LIFT = 1.05

# Atlanta World Cup match calendar
ATLANTA_GAME_DAYS = {
    date(2026, 6, 15): {"kickoff": "12:00", "match": "Spain vs. Cape Verde",         "stage": "Group"},
    date(2026, 6, 18): {"kickoff": "12:00", "match": "Czechia vs. South Africa",     "stage": "Group"},
    date(2026, 6, 21): {"kickoff": "12:00", "match": "Spain vs. Saudi Arabia",       "stage": "Group"},
    date(2026, 6, 24): {"kickoff": "18:00", "match": "Morocco vs. Haiti",            "stage": "Group"},
    date(2026, 6, 27): {"kickoff": "19:30", "match": "Congo DR vs. Uzbekistan",      "stage": "Group"},
    date(2026, 7,  1): {"kickoff": "12:00", "match": "England vs. Congo DR",         "stage": "Round of 32"},
    date(2026, 7,  7): {"kickoff": "12:00", "match": "TBD vs. TBD",                  "stage": "Round of 16", "confirmed": False},
    date(2026, 7, 15): {"kickoff": "15:00", "match": "TBD vs. TBD",                  "stage": "Semifinal",   "confirmed": False},
}

# Products and recipes
PRODUCTS = [
    # (product_id, name, category, price)
    (1,  "Classic Pepperoni",     "Pizza",    14.99),
    (2,  "Margherita",            "Pizza",    12.99),
    (3,  "BBQ Chicken",           "Pizza",    15.99),
    (4,  "Veggie Supreme",        "Pizza",    13.99),
    (5,  "Meat Lovers",           "Pizza",    16.99),
    (6,  "Buffalo Chicken",       "Pizza",    15.49),
    (7,  "Cheese Breadsticks",    "Sides",     6.99),
    (8,  "Garlic Knots",          "Sides",     5.99),
    (9,  "Caesar Salad",          "Salads",    8.99),
    (10, "House Salad",           "Salads",    7.99),
    (11, "Soft Drink",            "Beverages", 2.99),
    (12, "Bottled Water",         "Beverages", 1.99),
    (13, "Craft Beer",            "Beverages", 5.99),
    (14, "Chicken Wings",         "Sides",     9.99),
    (15, "Chocolate Lava Cake",   "Desserts",  5.99),
]

# Ingredient definitions (product_id -> list of (ingredient_name, qty_per_order, unit))
RECIPES = {
    1:  [("pizza_dough", 1, "ball"), ("tomato_sauce", 0.25, "cup"), ("mozzarella", 0.5, "lb"), ("pepperoni", 0.25, "lb")],
    2:  [("pizza_dough", 1, "ball"), ("tomato_sauce", 0.25, "cup"), ("mozzarella", 0.5, "lb"), ("fresh_basil", 0.1, "oz")],
    3:  [("pizza_dough", 1, "ball"), ("bbq_sauce", 0.25, "cup"), ("mozzarella", 0.5, "lb"), ("chicken_breast", 0.3, "lb")],
    4:  [("pizza_dough", 1, "ball"), ("tomato_sauce", 0.25, "cup"), ("mozzarella", 0.4, "lb"), ("bell_peppers", 0.2, "lb"), ("mushrooms", 0.15, "lb"), ("onions", 0.1, "lb")],
    5:  [("pizza_dough", 1, "ball"), ("tomato_sauce", 0.25, "cup"), ("mozzarella", 0.5, "lb"), ("pepperoni", 0.15, "lb"), ("italian_sausage", 0.2, "lb"), ("bacon", 0.1, "lb")],
    6:  [("pizza_dough", 1, "ball"), ("buffalo_sauce", 0.25, "cup"), ("mozzarella", 0.5, "lb"), ("chicken_breast", 0.3, "lb")],
    7:  [("pizza_dough", 0.5, "ball"), ("mozzarella", 0.3, "lb"), ("garlic_butter", 0.1, "cup")],
    8:  [("pizza_dough", 0.5, "ball"), ("garlic_butter", 0.1, "cup"), ("parmesan", 0.1, "lb")],
    9:  [("romaine_lettuce", 0.3, "lb"), ("parmesan", 0.05, "lb"), ("caesar_dressing", 0.1, "cup"), ("croutons", 0.1, "cup")],
    10: [("romaine_lettuce", 0.3, "lb"), ("tomatoes", 0.1, "lb"), ("onions", 0.05, "lb"), ("house_dressing", 0.1, "cup")],
    11: [("fountain_syrup", 0.1, "cup")],
    12: [("bottled_water", 1, "unit")],
    13: [("craft_beer", 1, "unit")],
    14: [("chicken_wings", 0.75, "lb"), ("buffalo_sauce", 0.15, "cup")],
    15: [("chocolate_mix", 0.25, "lb"), ("eggs", 1, "unit"), ("butter", 0.05, "lb")],
}

# Product mix weights by shift (morning light, evening heavy on beer/wings)
PRODUCT_WEIGHTS = {
    "morning":   [8, 10, 6, 8, 5, 5, 12, 10, 8, 8, 10, 5, 1, 2, 2],
    "afternoon": [12, 10, 10, 8, 8, 8, 8, 6, 5, 5, 8, 4, 2, 4, 2],
    "evening":   [14, 8, 12, 6, 12, 10, 5, 4, 3, 3, 6, 2, 8, 5, 2],
}

# Pay rates by title
PAY_RATES = {
    "General Manager": 28.00,
    "Shift Lead":       18.00,
    "Cook":             16.00,
    "Cashier":          14.00,
    "Delivery Driver":  13.00,
    "Server":           12.00,
}

OVERTIME_THRESHOLD = 40  # hours per week
OVERTIME_MULTIPLIER = 1.5

# ═════════════════════════════════════════════════════════════════════════════
# TABLE BUILDERS
# ═════════════════════════════════════════════════════════════════════════════

def build_calendar():
    rows = []
    start = date(2026, 1, 1)
    end   = date(2026, 7, 31)
    current = start
    while current <= end:
        is_game_day = current in ATLANTA_GAME_DAYS
        kickoff     = ATLANTA_GAME_DAYS[current]["kickoff"]  if is_game_day else None
        match_name  = ATLANTA_GAME_DAYS[current]["match"]    if is_game_day else None
        stage       = ATLANTA_GAME_DAYS[current]["stage"]    if is_game_day else None
        confirmed   = ATLANTA_GAME_DAYS[current].get("confirmed", True) if is_game_day else None
        is_forecast = current >= date(2026, 7, 1)
        rows.append({
            "date":             current.isoformat(),
            "day_of_week":      current.strftime("%A"),
            "is_weekend":       int(current.weekday() >= 5),
            "is_game_day":      int(is_game_day),
            "kickoff_time":     kickoff,
            "match":            match_name,
            "stage":            stage,
            "match_confirmed":  confirmed,
            "is_forecast":      int(is_forecast),
        })
        current += timedelta(days=1)
    return pd.DataFrame(rows)


def build_stores():
    rows = []
    managers = {
        1: "Marcus Webb",
        2: "Tanya Osei",
        3: "Carlos Rivera",
        4: "Jin Park",
        5: "Alicia Fontaine",
    }
    for store_id, info in LOCATIONS.items():
        rows.append({
            "store_id":       store_id,
            "store_name":     info["name"],
            "neighborhood":   info["neighborhood"],
            "personality":    info["personality"],
            "manager":        managers[store_id],
            "phone":          f"404-55{store_id}-{1000 + store_id * 111:04d}",
            "seating":        random.choice([30, 40, 50]),
            "delivery":       1,
            "takeout":        1,
        })
    return pd.DataFrame(rows)


def build_employees():
    first_names = ["James","Maria","Devon","Priya","Chloe","Andre","Sofia","Marcus",
                   "Jasmine","Tyler","Kezia","Rami","Natalie","Jordan","Luis","Amara",
                   "Chris","Fatima","Derek","Yuki","Brianna","Omar","Tasha","Kevin",
                   "Lena","Darius","Mei","Patrick","Simone","Aaron"]
    last_names  = ["Johnson","Williams","Brown","Davis","Martinez","Garcia","Wilson",
                   "Moore","Taylor","Anderson","Thomas","Jackson","White","Harris",
                   "Martin","Thompson","Young","Lewis","Walker","Hall"]

    titles = ["General Manager","Shift Lead","Cook","Cashier","Delivery Driver","Server"]
    # counts per store per title
    staffing = {
        "General Manager": 1,
        "Shift Lead":       2,
        "Cook":             4,
        "Cashier":          3,
        "Delivery Driver":  3,
        "Server":           3,
    }

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
                tenure_months = random.randint(1, 36)
                rows.append({
                    "employee_id":    emp_id,
                    "employee_name":  name,
                    "store_id":       store_id,
                    "title":          title,
                    "pay_rate":       PAY_RATES[title],
                    "tenure_months":  tenure_months,
                    "availability":   random.choice(["Full-Time","Part-Time"]),
                    "active":         1,
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
    """
    Generates wc_orders and wc_order_items together.
    One row per order in wc_orders.
    One or more rows per order in wc_order_items.
    """
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
            loc_name    = loc_info["name"]
            game_lift   = GAME_DAY_DEMAND_LIFT[loc_name] if is_game_day else 1.0
            weekend_lift = WEEKEND_LIFT if is_weekend else 1.0
            forecast_lift = JULY_FORECAST_LIFT if is_forecast else 1.0

            for shift_name, shift_info in SHIFTS.items():

                # Kickoff-aware demand: noon kickoff hammers afternoon, evening kickoff hammers evening
                kickoff_shift_lift = 1.0
                if is_game_day and kickoff:
                    kickoff_hour = int(kickoff.split(":")[0])
                    if kickoff_hour <= 13 and shift_name == "afternoon":
                        kickoff_shift_lift = 1.4
                    elif kickoff_hour <= 13 and shift_name == "morning":
                        kickoff_shift_lift = 1.2
                    elif kickoff_hour >= 17 and shift_name == "evening":
                        kickoff_shift_lift = 1.5
                    elif kickoff_hour >= 17 and shift_name == "afternoon":
                        kickoff_shift_lift = 1.3

                base = BASE_ORDERS[loc_name][shift_name]
                n_orders = int(round(
                    base
                    * game_lift
                    * weekend_lift
                    * forecast_lift
                    * kickoff_shift_lift
                    * random.uniform(0.88, 1.12)
                ))
                n_orders = max(n_orders, 1)

                order_type_weights = {"dine-in": 0.4, "takeout": 0.4, "delivery": 0.2}

                weights = list(PRODUCT_WEIGHTS[shift_name])
                weight_sum = sum(weights)
                norm_weights = [w / weight_sum for w in weights]

                for _ in range(n_orders):
                    order_type = random.choices(
                        list(order_type_weights.keys()),
                        weights=list(order_type_weights.values())
                    )[0]

                    order_rows.append({
                        "order_id":   order_id,
                        "store_id":   store_id,
                        "date":       cal_row["date"],
                        "shift":      shift_name,
                        "order_type": order_type,
                        "is_game_day": int(is_game_day),
                        "is_forecast": int(is_forecast),
                    })

                    # 1-3 items per order
                    n_items = random.choices([1, 2, 3], weights=[0.45, 0.40, 0.15])[0]
                    chosen_products = np.random.choice(product_ids, size=n_items, replace=False, p=norm_weights)

                    for prod_id in chosen_products:
                        prod = next(p for p in PRODUCTS if p[0] == prod_id)
                        qty = random.randint(1, 2)
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
    """
    One row per store per shift per date.
    Scheduled staff count driven by personality profile.
    Base staff need estimated from BASE_ORDERS volume.
    """
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
                base_orders = BASE_ORDERS[loc_name][shift_name]
                # Rough staff need: 1 staff per 8 orders
                base_staff_need = max(2, round(base_orders / 8))

                if is_game_day:
                    demand_lift = GAME_DAY_DEMAND_LIFT[loc_name]
                    schedule_response = profile["game_day_schedule_response"]
                    scheduled = max(2, round(base_staff_need * demand_lift * schedule_response * profile["schedule_bias"]))
                elif is_weekend:
                    scheduled = max(2, round(base_staff_need * WEEKEND_LIFT * profile["schedule_bias"]))
                else:
                    scheduled = max(2, round(base_staff_need * profile["schedule_bias"]))

                # Get store employees for shift lead assignment
                store_emps = df_employees[
                    (df_employees["store_id"] == store_id) &
                    (df_employees["title"] == "Shift Lead")
                ]
                lead_name = store_emps.sample(1)["employee_name"].values[0] if len(store_emps) > 0 else "TBD"

                rows.append({
                    "schedule_id":       shift_id,
                    "store_id":          store_id,
                    "date":              cal_row["date"],
                    "shift":             shift_name,
                    "shift_start":       shift_info["start"],
                    "shift_end":         shift_info["end"],
                    "scheduled_staff":   scheduled,
                    "shift_lead":        lead_name,
                    "is_game_day":       int(is_game_day),
                    "is_forecast":       int(is_forecast),
                })
                shift_id += 1

    return pd.DataFrame(rows)


def build_shifts_actual(df_shifts_scheduled, df_employees):
    """
    Intentional DQ issue: uses employee_name instead of employee_id.
    actual_hours_worked driven by personality actual_vs_scheduled ratio.
    Overtime flagged where applicable.
    Only for actuals (is_forecast == 0).
    """
    rows = []
    actual_id = 1

    actuals_only = df_shifts_scheduled[df_shifts_scheduled["is_forecast"] == 0].copy()

    for _, sched_row in actuals_only.iterrows():
        store_id    = sched_row["store_id"]
        personality = LOCATIONS[store_id]["personality"]
        profile     = PERSONALITY_PROFILES[personality]
        scheduled   = int(sched_row["scheduled_staff"])
        shift_hours = SHIFTS[sched_row["shift"]]["hours"]

        store_emps = df_employees[
            (df_employees["store_id"] == store_id) &
            (df_employees["title"].isin(["Cook","Cashier","Server","Delivery Driver","Shift Lead"]))
        ]

        if len(store_emps) == 0:
            continue

        n_actual = max(1, int(round(scheduled * random.uniform(0.90, 1.10))))
        sampled  = store_emps.sample(min(n_actual, len(store_emps)), replace=False)

        for _, emp in sampled.iterrows():
            ratio = profile["actual_vs_scheduled"]
            actual_hours = round(shift_hours * ratio * random.uniform(0.92, 1.08), 2)
            actual_hours = min(actual_hours, shift_hours + 2)  # cap bleed
            overtime_hours = max(0, round(actual_hours - shift_hours, 2))

            rows.append({
                "actual_id":       actual_id,
                "store_id":        store_id,
                "date":            sched_row["date"],
                "shift":           sched_row["shift"],
                # ── INTENTIONAL DQ ISSUE: name not ID ──
                "employee_name":   emp["employee_name"],
                "pay_rate":        emp["pay_rate"],
                "scheduled_hours": shift_hours,
                "actual_hours":    actual_hours,
                "overtime_hours":  overtime_hours,
                "labor_cost":      round(
                    (min(actual_hours, shift_hours) * emp["pay_rate"]) +
                    (overtime_hours * emp["pay_rate"] * OVERTIME_MULTIPLIER), 2
                ),
                "is_game_day":     sched_row["is_game_day"],
            })
            actual_id += 1

    return pd.DataFrame(rows)


def build_inventory(df_products):
    """
    Intentional DQ issue: uses ingredient_name instead of product_id.
    Stock levels reflect rough 7-day supply with some locations over/under stocked.
    """
    # Gather all unique ingredients
    all_ingredients = {}
    for prod_id, recipe in RECIPES.items():
        for ingredient, qty, unit in recipe:
            if ingredient not in all_ingredients:
                all_ingredients[ingredient] = unit

    rows = []
    inv_id = 1

    stock_bias = {
        "Downtown":   0.85,   # reactive — tends to run low
        "Decatur":    1.40,   # aggressive — over-orders
        "Smyrna":     0.80,   # reactive — leanest stock
        "Duluth":     1.20,   # conservative — carries extra
        "Camp Creek": 1.00,   # well-calibrated — right-sized
    }

    for store_id, loc_info in LOCATIONS.items():
        loc_name = loc_info["name"]
        bias     = stock_bias[loc_name]

        for ingredient, unit in all_ingredients.items():
            # Base 7-day estimated quantity on hand
            base_qty = round(random.uniform(8.0, 25.0) * bias, 2)

            # Introduce some stockout risk on high-use items at reactive locations
            if loc_info["personality"] == "reactive" and random.random() < 0.15:
                base_qty = round(random.uniform(0.5, 3.0), 2)

            rows.append({
                "inventory_id":    inv_id,
                "store_id":        store_id,
                # ── INTENTIONAL DQ ISSUE: ingredient name not product ID ──
                "ingredient_name": ingredient,
                "unit":            unit,
                "quantity_on_hand": base_qty,
                "last_updated":    "2026-06-30",
                "reorder_point":   round(random.uniform(2.0, 6.0), 2) if random.random() > 0.10 else None,
            })
            inv_id += 1

    return pd.DataFrame(rows)


# ═════════════════════════════════════════════════════════════════════════════
# LOAD TO SQLITE
# ═════════════════════════════════════════════════════════════════════════════

def load_to_db(conn, table_name, df):
    df.to_sql(table_name, conn, if_exists="replace", index=False)
    print(f"  ✓  {table_name:<25} {len(df):>7,} rows")


def main():
    print("\n── WC Pizza Co · Database Build ─────────────────────────────")
    print(f"   Output: {DB_PATH}\n")

    print("Building tables...")
    df_calendar   = build_calendar()
    df_stores     = build_stores()
    df_employees  = build_employees()
    df_products   = build_products()

    print("  ✓  calendar, stores, employees, products ready")

    df_orders, df_order_items = build_orders_and_items(df_calendar, df_employees)
    print("  ✓  orders and order_items ready")

    df_scheduled  = build_shifts_scheduled(df_calendar, df_employees)
    print("  ✓  shifts_scheduled ready")

    df_actual     = build_shifts_actual(df_scheduled, df_employees)
    print("  ✓  shifts_actual ready")

    df_inventory  = build_inventory(df_products)
    print("  ✓  inventory ready")

    print("\nLoading to SQLite...")
    conn = sqlite3.connect(DB_PATH)

    load_to_db(conn, "wc_calendar",          df_calendar)
    load_to_db(conn, "wc_stores",            df_stores)
    load_to_db(conn, "wc_employees",         df_employees)
    load_to_db(conn, "wc_products",          df_products)
    load_to_db(conn, "wc_orders",            df_orders)
    load_to_db(conn, "wc_order_items",       df_order_items)
    load_to_db(conn, "wc_shifts_scheduled",  df_scheduled)
    load_to_db(conn, "wc_shifts_actual",     df_actual)
    load_to_db(conn, "wc_inventory",         df_inventory)

    conn.close()

    total_rows = (
        len(df_calendar) + len(df_stores) + len(df_employees) +
        len(df_products) + len(df_orders) + len(df_order_items) +
        len(df_scheduled) + len(df_actual) + len(df_inventory)
    )

    print(f"\n── Build complete ────────────────────────────────────────────")
    print(f"   Total rows across all tables: {total_rows:,}")
    print(f"   Database: {DB_PATH}\n")


if __name__ == "__main__":
    main()
    