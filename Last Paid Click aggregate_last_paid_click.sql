with tab1 as (
select utm_source,  utm_medium, utm_campaign, sum(daily_spent) as total_cost
from ya_ads
group by 1,2,3
union all
 select utm_source,  utm_medium, utm_campaign, sum(daily_spent) as total_cost
from vk_ads
group by 1,2,3
)
select to_char(max(visit_date), 'yyyy-mm-dd') as visit_date ,
s.source as utm_source, s.medium as utm_medium, s.campaign as utm_campaign ,
count(s.visitor_id) as visitors_count, 
t1.total_cost, 
count (l.lead_id ) as leads_count,
sum(case  when l.closing_reason = 'Успешно реализовано' or l.status_id = 142 then 1 
  else 0 
  end )as is_purchase,
sum (l.amount) as revenue 
from  sessions s
left join leads l on l.visitor_id = s.visitor_id
join tab1 t1 on s.medium=t1.utm_medium and s.source=t1.utm_source and 
s.campaign=t1.utm_campaign
group by 2,3,4,6
order by
    revenue desc nulls last, visit_date, visitors_count  desc, 
    utm_source, utm_medium, utm_campaign
 limit 15;
