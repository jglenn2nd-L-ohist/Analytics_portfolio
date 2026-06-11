-- ============================================
-- Query 01: YouTube Video Lead Attribution
-- Project: Data In Motion Lead Analysis
-- Analyst: Jonathan Glenn
-- Description: Joins YouTube video data to Hyros
-- lead records using engineered yt_handle key.
-- Returns total leads generated per video.
-- ============================================

SELECT 
    y."Video title",
    y.Views,
    y.yt_handle,
    COUNT(h."Unique ID") AS total_leads
FROM yt_clean y
INNER JOIN hyros h 
    ON y.yt_handle = h."first source"
GROUP BY y."Video title"
ORDER BY total_leads DESC;