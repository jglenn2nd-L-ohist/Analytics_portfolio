import pandas as pd

# Load the YouTube data
yt = pd.read_csv('01_lead_attribution/data/YouTube_data.csv')

# Month abbreviation to number mapping
month_map = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
    'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
    'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
}

def build_handle(date_str):
    # Skip empty values
    if pd.isna(date_str) or date_str == '':
        return None
    
    # Split "2-Jan-26" into parts
    parts = date_str.split('-')
    day   = int(parts[0])
    month = month_map[parts[1]]
    year  = 2000 + int(parts[2])
    
    return f'@yt_{month}_{day}_{year}'

# Build the handle column
yt['yt_handle'] = yt['Video publish time'].apply(build_handle)

# Save the clean version
yt.to_csv('01_lead_attribution/data/YouTube_clean.csv', index=False)

print("Done. Sample output:")
print(yt[['Video title', 'Video publish time', 'yt_handle']].dropna().head(10))