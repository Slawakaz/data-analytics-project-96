with tab1 as(select 
    s.visitor_id,
    s.visit_date,
    row_number() over (
            partition by s.visitor_id 
            order by s.visit_date desc
        ) as rn,
    s.source as utm_source,
    s.medium as utm_medium,
    s.campaign as utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from 
    sessions s
left join 
    leads l using (visitor_id)
where   s.medium  in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social') and l.created_at  >= s.visit_date 
    )
    select 
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
from tab1
where rn = 1
order by 
    amount desc nulls last,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign
    limit 10;

