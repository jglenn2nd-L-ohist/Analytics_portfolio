# Content Taxonomy + Captivation Indicator
# Merges two SQL query results and produces a styled table

import sqlite3
import pandas as pd

# --- Connect ---
conn = sqlite3.connect("../data/lead_attribution.db")

# --- Query 1: Content Taxonomy ---
taxonomy_query = """
WITH first_touch AS (
    SELECT
        "First source" AS video_id,
        COUNT(*) AS first_touch_leads
    FROM hyros
    WHERE "First source" LIKE '@yt%'
    GROUP BY "First source"
),
last_touch AS (
    SELECT
        "Last source" AS video_id,
        COUNT(*) AS last_touch_leads
    FROM hyros
    WHERE "Last source" LIKE '@yt%'
    GROUP BY "Last source"
),
combined AS (
    SELECT f.video_id, f.first_touch_leads, COALESCE(l.last_touch_leads, 0) AS last_touch_leads
    FROM first_touch f
    LEFT JOIN last_touch l ON f.video_id = l.video_id
    UNION
    SELECT l.video_id, COALESCE(f.first_touch_leads, 0) AS first_touch_leads, l.last_touch_leads
    FROM last_touch l
    LEFT JOIN first_touch f ON l.video_id = f.video_id
),
ranked AS (
    SELECT
        video_id, first_touch_leads, last_touch_leads,
        NTILE(4) OVER (ORDER BY first_touch_leads DESC) AS first_quartile,
        NTILE(4) OVER (ORDER BY last_touch_leads DESC) AS last_quartile
    FROM combined
)
SELECT
    video_id, first_touch_leads, last_touch_leads,
    CASE
        WHEN first_quartile = 1 AND last_quartile = 1 THEN 'Both'
        WHEN first_quartile = 1 THEN 'Closer'
        WHEN last_quartile = 1 THEN 'Validator'
        ELSE 'Below threshold'
    END AS content_role
FROM ranked
ORDER BY first_touch_leads DESC
"""

# --- Query 2: Captivation Indicator ---
captivation_query = """
WITH calcs AS (
    SELECT
        yt.field11 AS yt_handle,
        (yt.field6 * 3600.0) AS w_seconds,
        yt.field5 AS num_views,
        yt.field4 AS duration,
        yt.field10 AS CTR,
        COUNT(h."Unique ID") AS total_leads
    FROM youtube_clean yt
    LEFT JOIN hyros h ON yt.field11 = h."First source"
    WHERE yt.field11 LIKE '@yt_%'
    GROUP BY yt.field11, yt.field6, yt.field5, yt.field4, yt.field10
),
lead_quartiles AS (
    SELECT yt_handle, w_seconds, num_views, duration, CTR, total_leads,
        NTILE(4) OVER (ORDER BY total_leads) AS lead_bucket
    FROM calcs
),
iqr_filtered AS (
    SELECT
        ROUND((w_seconds / num_views) / duration * 100.0, 2) AS watch_duration_pct,
        CTR / 100.0 AS ctr_decimal
    FROM lead_quartiles
    WHERE lead_bucket IN (2, 3)
),
channel_avgs AS (
    SELECT AVG(watch_duration_pct) AS avg_watch_pct, AVG(ctr_decimal) AS avg_ctr
    FROM iqr_filtered
),
all_videos AS (
    SELECT yt_handle, total_leads,
        ROUND((w_seconds / num_views) / duration * 100.0, 2) AS watch_duration_pct,
        CTR / 100.0 AS ctr_decimal
    FROM calcs
),
final AS (
    SELECT
        v.yt_handle, v.total_leads, v.watch_duration_pct, v.ctr_decimal,
        ROUND(v.watch_duration_pct / a.avg_watch_pct, 4) AS watch_index,
        ROUND(v.ctr_decimal / a.avg_ctr, 4) AS ctr_index,
        ROUND(
            (v.watch_duration_pct / a.avg_watch_pct * 0.70) +
            (v.ctr_decimal / a.avg_ctr * 0.30), 4
        ) AS captivation_index
    FROM all_videos v
    CROSS JOIN channel_avgs a
)
SELECT yt_handle, total_leads, watch_duration_pct, ctr_decimal,
    watch_index, ctr_index, captivation_index
FROM final
WHERE captivation_index >= 1.0
ORDER BY captivation_index DESC
"""
df_taxonomy = pd.read_sql_query(taxonomy_query, conn)
df_captivation = pd.read_sql_query(captivation_query, conn)

print(df_captivation['yt_handle'].head())
print(df_taxonomy['video_id'].head())

conn.close()

# --- Merge ---
df_merged = df_taxonomy.merge(df_captivation, left_on='video_id', right_on='yt_handle', how='left')

# --- Function: assign color based on captivation score ---
def get_color(score):
    if pd.isna(score):
        return '#ffffff'
    elif score >= 1.3:
        return '#1a3a5c'
    elif score >= 1.15:
        return '#2e5f8a'
    elif score >= 1.0:
        return '#5b8db8'
    else:
        return '#ffffff'

# This list comprehension:
colors = [get_color(score) for score in df_merged['captivation_index']]

# --- Build display table ---
df_display = df_merged[['video_id', 'content_role', 'first_touch_leads', 'last_touch_leads', 'captivation_index']].copy()
df_display = df_display.sort_values(['content_role', 'captivation_index'], ascending=[True, False])

# --- Apply styling ---
def style_row(row):
    color = get_color(row['captivation_index'])
    text = '#ffffff' if color != '#ffffff' else '#000000'
    return [f'background-color: {color}; color: {text}'] * len(row)

styled = df_display.style.apply(style_row, axis=1)
styled = styled.format({'captivation_index': '{:.4f}'})

# --- Save to HTML ---
styled.to_html('../data/content_taxonomy_table.html')
print("Table saved.")

print(df_merged.columns.tolist())
print(df_merged.head())