-- ============================================
-- Query 02: Views vs Leads Ratio
-- Project: Data In Motion Lead Analysis
-- Analyst: J.Glenn
-- Description: Calculates the lead conversion
-- rate per video (leads per 1,000 views).
-- Identifies which videos punch above their
-- weight in turning views into leads.
-- ============================================
SELECT
        yt.field2 AS Video_title,
        yt.field5 AS views,
        COUNT(h."Unique ID") AS total_leads,
        ROUND(CAST(COUNT(h."Unique ID") AS FLOAT) / NULLIF(yt.field5, 0) *100.0, 2) AS conversion_rate_pct
FROM
        YouTube_clean yt
 LEFT JOIN
        hyros h
 ON yt.field11 = h."First source"
 GROUP BY
        yt.field2, yt.field5 
 ORDER BY
        conversion_rate_pct DESC;


