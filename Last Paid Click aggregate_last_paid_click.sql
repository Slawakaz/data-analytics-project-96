WITH last_paid_clicks AS (    select  visitor_id,  visit_date::date AS visit_date, source AS utm_source,
     medium AS utm_medium,  campaign AS utm_campaign,  l.lead_id, l.amount,
        CASE 
            WHEN l.closing_reason = 'Успешно реализовано' OR l.status_id = 142 
            THEN 1 ELSE 0 
        END AS purchases,
        ROW_NUMBER() OVER (
            PARTITION BY visitor_id 
            ORDER BY visit_date DESC
        ) AS rn
    FROM sessions
   LEFT JOIN leads l using(visitor_id) 
    WHERE medium IN ('cpc','cpm','cpa','youtube','cpp','tg','social')
),
combined_ads AS (
  select  utm_source,  utm_medium, utm_campaign, SUM(daily_spent) AS total_spent
    FROM (
        SELECT  utm_source, utm_medium, utm_campaign, daily_spent
        FROM vk_ads
        UNION ALL
        SELECT   utm_source,  utm_medium,  utm_campaign,  daily_spent
        FROM ya_ads
    ) AS ads
    GROUP BY utm_source, utm_medium, utm_campaign
)
SELECT
  lpc.visit_date,
   COUNT(DISTINCT lpc.visitor_id) AS visitors_count,
  lpc.utm_source, lpc.utm_medium,  lpc.utm_campaign,  ca.total_spent as total_cost, 
  COUNT(distinct lpc.lead_id) AS leads_count, SUM(coalesce( purchases,0)) as purchases_count ,
       sum( coalesce (amount, 0)) as  revenue
    FROM last_paid_clicks lpc
    LEFT JOIN combined_ads ca  ON lpc.utm_source = ca.utm_source  AND lpc.utm_medium = ca.utm_medium
    AND lpc.utm_campaign = ca.utm_campaign
    WHERE lpc.rn = 1 
    GROUP BY lpc.visit_date, lpc.utm_source, lpc.utm_medium, lpc.utm_campaign, ca.total_spent
ORDER BY
    revenue DESC NULLS LAST,  visit_date ASC,  visitors_count DESC,  utm_source, utm_medium,  utm_campaign
    limit 15;
