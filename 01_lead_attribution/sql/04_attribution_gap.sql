WITH leads AS (
	SELECT	
		COUNT(*) AS t_leads,
		COUNT(CASE WHEN "First source" = '-' THEN 1 END) AS unat_leads
	FROM	
		hyros
)
SELECT
	unat_leads AS unattributed,
	t_leads AS total_leads,
	ROUND(CAST(unat_leads AS FLOAT)/CAST(t_leads AS FLOAT) * 100.0,1) AS percent_leads_unattributed
FROM 
	leads
;