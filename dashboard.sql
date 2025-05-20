SELECT
    COUNT(DISTINCT visitor_id) AS visitor_count,
    visit_date::DATE AS visit_date,
    source,
    medium,
    campaign
FROM sessions
GROUP BY visit_date::DATE, source, medium, campaign;
SELECT
    COUNT(DISTINCT visitor_id) AS visitor_count,
    TRIM(TO_CHAR(visit_date, 'Day')) AS weekday,
    source,
    medium,
    campaign
FROM sessions
GROUP BY TRIM(TO_CHAR(visit_date, 'Day')), source, medium, campaign;
SELECT
    COUNT(DISTINCT visitor_id) AS visitor_count,
    visit_date::DATE AS visit_date,
    CASE
        WHEN EXTRACT(ISODOW FROM visit_date) = 1 THEN '1_monday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 2 THEN '2_tuesday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 3 THEN '3_wednesday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 4 THEN '4_thursday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 5 THEN '5_friday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 6 THEN '6_saturday'
        WHEN EXTRACT(ISODOW FROM visit_date) = 7 THEN '7_sunday'
    END AS day_of_week,
    source,
    medium,
    campaign
FROM sessions
GROUP BY visit_date::DATE, day_of_week, source, medium, campaign;
SELECT
    COUNT(DISTINCT s.visitor_id) AS visitors,
    SUM(COALESCE(l.amount, 0)) AS revenue
FROM sessions s
LEFT JOIN leads l 
    ON s.visitor_id = l.visitor_id
WHERE s.source IN ('google', 'organic');
SELECT
    COUNT(DISTINCT s.visitor_id) AS visitors,
    SUM(COALESCE(l.amount, 0)) AS revenue
FROM sessions s
LEFT JOIN leads l 
    ON s.visitor_id = l.visitor_id
WHERE s.source IN ('vk', 'yandex');
WITH combined_ads AS (
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
    campaign_date::DATE AS visit_date,
    utm_source AS source,
    utm_medium AS medium,
    utm_campaign AS campaign,
    SUM(daily_spent) AS total_spent
FROM combined_ads
GROUP BY campaign_date::DATE, utm_source, utm_medium, utm_campaign;
WITH last_sessions AS (
    SELECT
        s.visitor_id,
        l.lead_id,
        CASE 
            WHEN l.closing_reason = 'успешно реализовано' OR l.status_id = 142 
            THEN 1 ELSE 0 
        END AS is_purchase,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id 
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions s
    LEFT JOIN leads l 
        ON s.visitor_id = l.visitor_id
        AND l.created_at >= s.visit_date
    WHERE s.medium IN (
        'cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social'
    )
)
SELECT
    COUNT(visitor_id) AS visitors,
    COUNT(lead_id) AS leads,
    SUM(is_purchase) AS purchases
FROM last_sessions
WHERE rn = 1;
WITH first_visits AS (
    SELECT
        visitor_id,
        MIN(visit_date) AS first_visit
    FROM sessions
    WHERE medium IN (
        'cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social'
    )
    GROUP BY visitor_id
),
lead_times AS (
    SELECT
        (EXTRACT(EPOCH FROM (l.created_at - fv.first_visit)) / 86400) AS days_to_close
    FROM leads l
    JOIN first_visits fv USING(visitor_id)
    WHERE l.closing_reason IS NOT NULL
)
SELECT
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY days_to_close) AS percentile_90_days
FROM lead_times;
WITH ad_costs AS (
    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM (
        SELECT * FROM vk_ads
        UNION ALL
        SELECT * FROM ya_ads
    ) AS combined_ads
    GROUP BY 1, 2, 3
),
conversion_data AS (
    SELECT
        s.source,
        s.medium,
        s.campaign,
        COUNT(DISTINCT s.visitor_id) AS visitors,
        COUNT(DISTINCT l.lead_id) AS leads,
        SUM(CASE 
            WHEN l.closing_reason = 'успешно реализовано' OR l.status_id = 142 
            THEN 1 ELSE 0 
        END) AS purchases,
        SUM(COALESCE(l.amount, 0)) AS revenue
    FROM sessions s
    LEFT JOIN leads l USING(visitor_id)
    WHERE s.source IN ('vk', 'yandex')
    GROUP BY 1, 2, 3
)
SELECT
    cd.source AS utm_source,
    ROUND(COALESCE(ac.total_cost / NULLIF(cd.visitors, 0), 2) AS cpu,
    ROUND(COALESCE(ac.total_cost / NULLIF(cd.leads, 0), 2) AS cpl,
    ROUND(COALESCE(ac.total_cost / NULLIF(cd.purchases, 0), 2) AS cppu,
    ROUND(COALESCE(
        (cd.revenue - ac.total_cost) / NULLIF(ac.total_cost, 0) * 100, 
        0
    ), 2) AS roi
FROM conversion_data cd
LEFT JOIN ad_costs ac 
    ON cd.source = ac.utm_source
    AND cd.medium = ac.utm_medium
    AND cd.campaign = ac.utm_campaign;
