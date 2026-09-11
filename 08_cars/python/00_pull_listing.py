import requests
import csv
import time

API_KEY = "sk_ad_tYh_cJneP8ytU6Y64HyciMGB"  # Replace with your actual key
BASE_URL = "https://api.auto.dev/listings"
HEADERS = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}

CALLS_PER_ZIP = 25  # 990 total calls across 15 ZIPs, leaving buffer under 1,000

def get_listings(url, headers):
    MAX_RETRIES = 5
    for attempt in range(MAX_RETRIES):
        response = requests.get(url, headers=headers, timeout=30)

        if response.status_code == 503:
            wait_seconds = 2 ** attempt
            print(f"  → 503 error. Retrying in {wait_seconds}s ({attempt + 1}/{MAX_RETRIES})...")
            time.sleep(wait_seconds)
            continue

        if response.status_code != 200:
            print(f"  → HTTP {response.status_code}: {response.text}")
            response.raise_for_status()

        return response.json()

    raise RuntimeError(f"Auto.dev unavailable after {MAX_RETRIES} attempts. URL: {url}")

def flatten_listing(item):
    vehicle = item.get("vehicle") or {}
    retail = item.get("retailListing") or {}
    history = item.get("history") or {}
    return {
        "vin": item.get("vin"),
        "createdAt": item.get("createdAt"),
        "year": vehicle.get("year"),
        "make": vehicle.get("make"),
        "model": vehicle.get("model"),
        "trim": vehicle.get("trim"),
        "bodyStyle": vehicle.get("bodyStyle"),
        "drivetrain": vehicle.get("drivetrain"),
        "dealer": retail.get("dealer"),
        "dealerId": retail.get("dealerId"),
        "price": retail.get("price"),
        "miles": retail.get("miles"),
        "cpo": retail.get("cpo"),
        "city": retail.get("city"),
        "state": retail.get("state"),
        "zip": retail.get("zip"),
        "searchZip": None,  # Will fill in below
        "accidentCount": history.get("accidentCount"),
        "ownerCount": history.get("ownerCount"),
        "oneOwner": history.get("oneOwner"),
    }

zip_codes = [
    '30096', '30291', '30519', '30518', '30144', 
    '30060', '30067', '30062', '30009', '30013',
    '30012', '30094', '30260', '30341', '30339'
]

all_rows = []
total_calls = 0

for zip_code in zip_codes:
    print(f"\n[ZIP {zip_code}] Starting pull...")
    calls_this_zip = 0
    # UPDATED: Added used-only filter
    url = f"{BASE_URL}?zip={zip_code}&distance=2&limit=20&retailListing.used=true"
    
    while url and calls_this_zip < CALLS_PER_ZIP:
        payload = get_listings(url, HEADERS)
        total_calls += 1
        calls_this_zip += 1
        
        for item in payload["data"]:
            row = flatten_listing(item)
            row["searchZip"] = zip_code  # Tag which ZIP this came from
            all_rows.append(row)
        
        print(f"  Call {calls_this_zip}/{CALLS_PER_ZIP}: +{len(payload['data'])} listings (total: {len(all_rows)})")
        
        next_link = payload.get("links", {}).get("next")
        url = next_link if next_link else None
        
        time.sleep(0.5)
    
    print(f"[ZIP {zip_code}] Done. {calls_this_zip} calls made.")

# Save results
output_file = "atlanta_listings_2026-09-10.csv"
with open(output_file, "w", newline="", encoding="utf-8") as f:
    if all_rows:
        writer = csv.DictWriter(f, fieldnames=all_rows[0].keys())
        writer.writeheader()
        writer.writerows(all_rows)

print(f"\n✓ Complete: {len(all_rows)} listings from {total_calls} API calls")
print(f"✓ Saved to: {output_file}")