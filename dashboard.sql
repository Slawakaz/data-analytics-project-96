SELECT
    visit_date::DATE AS visit_date,
    source,
    medium,
    campaign,
    COUNT(DISTINCT visitor_id) AS visitor_count
FROM sessions
GROUP BY visit_date::DATE, source, medium, campaign;
SELECT
    source,
    medium,
    campaign,
    visit_date::DATE AS visit_date,
    TO_CHAR(visit_date, 'IDay') AS day_of_week,
    COUNT(DISTINCT visitor_id) AS visitor_count
FROM sessions
GROUP BY     
    source,
    medium,
    campaign,
    visit_date::DATE AS visit_date,
    TO_CHAR(visit_date, 'IDay') AS day_of_week;
