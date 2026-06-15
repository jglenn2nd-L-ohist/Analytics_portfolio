-- ============================================
-- Query 01: YouTube Video Lead Attribution
-- Project: Data In Motion Lead Analysis
-- Analyst: J.Glenn
-- Description: Joins YouTube video data to Hyros
-- lead records using engineered yt_handle key.
-- Returns total leads generated per video.
-- ============================================

SELECT 
    y.field2 AS video_title,
    y.field5 AS views,
    y.field11 AS yt_handle,
    COUNT(h."Unique ID") AS total_leads
FROM YouTube_clean y
INNER JOIN hyros h 
    ON y.field11 = h."first source"
GROUP BY y.field2
ORDER BY total_leads DESC;