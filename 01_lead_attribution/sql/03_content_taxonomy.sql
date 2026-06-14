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
    SELECT f.video_id,
           f.first_touch_leads,
           COALESCE(l.last_touch_leads, 0) AS last_touch_leads
    FROM first_touch f
    LEFT JOIN last_touch l ON f.video_id = l.video_id

    UNION

    SELECT l.video_id,
           COALESCE(f.first_touch_leads, 0) AS first_touch_leads,
           l.last_touch_leads
    FROM last_touch l
    LEFT JOIN first_touch f ON l.video_id = f.video_id
),

ranked AS (
    SELECT
        video_id,
        first_touch_leads,
        last_touch_leads,
        NTILE(4) OVER (ORDER BY first_touch_leads DESC) AS first_quartile,
        NTILE(4) OVER (ORDER BY last_touch_leads DESC) AS last_quartile
    FROM combined
)

SELECT
    video_id,
    first_touch_leads,
    last_touch_leads,
    CASE
        WHEN first_quartile = 1 AND last_quartile = 1 THEN 'Both'
        WHEN first_quartile = 1 THEN 'Closer'
        WHEN last_quartile = 1 THEN 'Validator'
        ELSE 'Below threshold'
    END AS content_role
FROM ranked
ORDER BY first_touch_leads DESC;
