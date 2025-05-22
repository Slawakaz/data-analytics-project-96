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
    CASE
        WHEN EXTRACT(ISODOW FROM visit_date) = 1 THEN '1monday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 2 THEN '2tuesday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 3 THEN '3wednesday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 4 THEN '4thursday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 5 THEN '5friday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 6 THEN '6saturday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 7 THEN '7sunday'
    END AS day_of_week,
    COUNT(DISTINCT visitor_id) AS visitor_count
FROM sessions
GROUP BY
    source,
    medium,
    campaign,
    visit_date::DATE,
    CASE
        WHEN EXTRACT(ISODOW FROM visit_date) = 1 THEN '1monday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 2 THEN '2tuesday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 3 THEN '3wednesday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 4 THEN '4thursday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 5 THEN '5friday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 6 THEN '6saturday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 7 THEN '7sunday'
    END;
WITH tab1 AS (
    SELECT
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    FROM vk_ads
    UNION ALL
    SELECT
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    FROM ya_ads
)

SELECT
    utm_source AS source,
    utm_medium AS medium,
    utm_campaign AS campaign,
    TO_CHAR(campaign_date, 'yyyy-mm-dd') AS visit_date,
    SUM(daily_spent) AS total_spent
FROM tab1
GROUP BY
    utm_source,
    utm_medium,
    utm_campaign,
    TO_CHAR(campaign_date, 'yyyy-mm-dd');
