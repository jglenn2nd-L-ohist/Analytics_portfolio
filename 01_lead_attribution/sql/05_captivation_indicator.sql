-- ============================================
-- Query 05: Captivation Indicator
-- Project: Data In Motion Lead Analysis
-- Analyst: J.Glenn
-- Description: Builds a weighted engagement
-- index using IQR-filtered channel averages.
-- Formula: (Watch% Index x 0.70) + (CTR Index
-- x 0.30). Score >= 1.0 = above average.
-- ============================================

WITH calcs AS (
    SELECT	
        yt.field11 AS yt_handle,
        (yt.field6 * 3600.0) AS w_seconds,
        yt.field5 AS num_views,
        yt.field4 AS duration,
        yt.field10 AS CTR,
        COUNT(h."Unique ID") AS total_leads
    FROM youtube_clean yt
    LEFT JOIN hyros h
        ON yt.field11 = h."First source"
    WHERE yt.field11 LIKE '@yt_%'
    GROUP BY
        yt.field11, yt.field6, yt.field5, yt.field4, yt.field10
),

lead_quartiles AS (
    SELECT
        yt_handle,
        w_seconds,
        num_views,
        duration,
        CTR,
        total_leads,
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
    SELECT
        AVG(watch_duration_pct) AS avg_watch_pct,
        AVG(ctr_decimal) AS avg_ctr
    FROM iqr_filtered
),

all_videos AS (
    SELECT
        yt_handle,
        total_leads,
        ROUND((w_seconds / num_views) / duration * 100.0, 2) AS watch_duration_pct,
        CTR / 100.0 AS ctr_decimal
    FROM calcs
),

final AS (
    SELECT
        v.yt_handle,
        v.total_leads,
        v.watch_duration_pct,
        v.ctr_decimal,
        ROUND(v.watch_duration_pct / a.avg_watch_pct, 4) AS watch_index,
        ROUND(v.ctr_decimal / a.avg_ctr, 4) AS ctr_index,
        ROUND(
            (v.watch_duration_pct / a.avg_watch_pct * 0.70) +
            (v.ctr_decimal / a.avg_ctr * 0.30), 4
        ) AS captivation_index
    FROM all_videos v
    CROSS JOIN channel_avgs a
)

SELECT
    yt_handle,
    total_leads,
    watch_duration_pct,
    ctr_decimal,
    watch_index,
    ctr_index,
    captivation_index
FROM final
WHERE captivation_index >= 1.0
ORDER BY captivation_index DESC
