select 
    s.visitor_id,
    s.visit_date,
    s.source as utm_source,
    s.medium as utm_medium,
    s.campaign as utm_campaign,
    l.lead_id,
    l.created_at,
    sum(coalesce(l.amount, 0)) as amount,
    l.closing_reason,
    l.status_id
from 
    sessions s
left join 
    leads l using (visitor_id)
where 
    s.source in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social') or  s.medium  in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
    group by 1,2,3,4,5,6,7,9,10
order by 
    amount desc nulls last,
    s.visit_date,
    utm_source,
    utm_medium,
    utm_campaign
    limit 10;
