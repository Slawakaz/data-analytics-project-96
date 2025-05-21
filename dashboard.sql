SELECT
    visit_date::DATE AS visit_date,
    source,
    medium,
    campaign,
    COUNT(DISTINCT visitor_id) AS visitor_count
FROM sessions
GROUP BY visit_date::DATE, source, medium, campaign;
