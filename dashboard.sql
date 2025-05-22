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
WITH
tab1 AS (
    SELECT
        visitor_id,
        MIN(visit_date) AS first_visit_date
    FROM sessions
    WHERE source IN ('vk', 'yandex')
    GROUP BY visitor_id
),

tab2 AS (
    SELECT
        l.visitor_id,
        l.created_at AS lead_closed_date,
        t1.first_visit_date,
        (l.created_at - t1.first_visit_date) AS days_to_close
    FROM leads AS l
    INNER JOIN tab1 AS t1
        ON l.visitor_id = t1.visitor_id
    WHERE
        l.closing_reason IS NOT NULL
        AND l.created_at >= t1.first_visit_date
    ORDER BY days_to_close
)

SELECT
    EXTRACT(
        DAY FROM PERCENTILE_CONT(0.9) WITHIN GROUP (
            ORDER BY days_to_close
        )
    ) AS percentile_90_days
FROM tab2;
with tab1 as (
select  utm_source,  utm_medium, utm_campaign, sum(daily_spent) as total_cost
from ya_ads
group by 1,2,3
union all
 select  utm_source,  utm_medium, utm_campaign, sum(daily_spent) as total_cost
from vk_ads
group by 1,2,3
order by 1 
),
tab2 as(
select 
s.source , s.medium, s.campaign  ,
count(distinct s.visitor_id) as visitors, 
sum(case  when l.closing_reason = 'успешно реализовано' or l.status_id = 142 then 1 
  else 0 
  end ) as purchases_count, 
  count(distinct l.lead_id) as lead_count,
  sum(l.amount) as revenue
from  sessions s
left join leads l on l.visitor_id = s.visitor_id
where s.source in ('vk', 'yandex')
group by 1,2,3
order by  1 desc
)
 select t2.source  as utm_source, 
 t2.medium as utm_medium, 
 t2.campaign as utm_campaign,
 round(sum( coalesce(total_cost, 0)) /  sum(coalesce(visitors, 0)), 2) as cpu,  
  round(sum( coalesce(total_cost, 0)) / sum(coalesce(lead_count, 0)), 2) as  cpl,
round(sum( coalesce(total_cost, 0)) / sum(coalesce(purchases_count, 0)), 2) cppu ,
 round((sum(coalesce(revenue, 0)) - sum( coalesce(total_cost, 0))) / sum( coalesce(total_cost, 0)) * 100.00, 2) as roi
from tab2 t2
left join tab1 t1 on t2.medium=t1.utm_medium and t2.source=t1.utm_source and 
t2.campaign=t1.utm_campaign
group by 1;
