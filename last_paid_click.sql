with tab1 as(SELECT 
    s.visitor_id,
    s.visit_date,
    ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id 
            ORDER BY s.visit_date DESC
        ) AS rn,
    s.source AS utm_source,
    s.medium AS utm_medium,
    s.campaign AS utm_campaign,
    l.lead_id,
    l.created_at,
    sum(COALESCE(l.amount, 0)) AS amount,
    l.closing_reason,
    l.status_id
FROM 
    sessions s
LEFT JOIN 
    leads l USING (visitor_id)
WHERE   s.medium  IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social') 
    group by 1,2,4,5,6,7,8,10,11
    )
    SELECT 
    visitor_id,
    visit_date,
   utm_source,
   utm_medium,
    utm_campaign,
    lead_id,
    created_at,
     amount,
    closing_reason,
    status_id
FROM tab1
where rn = 1
ORDER BY 
    amount DESC NULLS LAST,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign
    limit 10;
