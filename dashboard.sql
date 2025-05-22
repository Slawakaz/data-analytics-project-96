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
with tab1 as (
    select 
        visitor_id,
        min(visit_date) as first_visit_date 
    from sessions
    where source in ('vk', 'yandex')
    group by visitor_id
),
tab2 as (
    select 
        l.visitor_id,
        l.created_at as lead_closed_date,
        t1.first_visit_date,
        (l.created_at- t1.first_visit_date) as days_to_close
    from leads l
    join tab1 t1 using(visitor_id)
    where l.closing_reason is not null  and l.created_at >= t1.first_visit_date
    order by 4
)
select 
    extract(day from percentile_cont(0.9) within group (order by days_to_close)) as percentile_90_days
from tab2;

