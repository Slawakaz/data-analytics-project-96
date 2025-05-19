select count(distinct visitor_id) as visitor_count,
to_char(visit_date, 'yyyy-mm-dd') as visit_date,
source, medium , campaign
from sessions 
group by 2,3,4,5;
  
select count(distinct visitor_id) as visitor_count,
to_char(visit_date, 'day') as visit_date,
source, medium , campaign
from sessions 
group by 2,3,4,5;
 
select count(distinct visitor_id) as visitor_count,
to_char(visit_date, 'yyyy-mm-dd') as visit_date,
case  
        when extract(isodow from visit_date) = 1 then  '1monday'
        when extract(isodow from visit_date) = 2 then  '2tuesday'
        when extract(isodow from visit_date) = 3 then  '3wednesday'
        when extract(isodow from visit_date) = 4 then  '4thursday'
        when extract(isodow from visit_date) = 5 then  '5friday'
        when extract(isodow from visit_date) = 6 then  '6saturday'
        when extract(isodow from visit_date) = 7 then  '7sunday'
    end as day_of_week, 
source, medium , campaign
from sessions 
group by 2,3,4,5,6;


select  count(distinct visitor_id) as visitors
sum(coalesce(amount, 0)) as revenu
from sessions  
left join leads  using(visitor_id) 
 where source in ('google', 'organic') ;


select  count(distinct visitor_id) as visitors
sum(coalesce(amount, 0)) as revenu
from sessions  
left join leads  using(visitor_id) 
where source in ('vk', 'yandex') ;


with tab1 as (
    select 
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads
    union all
    select 
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads
)
select 
    to_char(campaign_date, 'yyyy-mm-dd') as visit_date,
    utm_source as source,
    utm_medium as medium,
    utm_campaign as campaign,
    sum(daily_spent) as total_spent
from tab1 
group by 1,2,3,4   ;


with tab1 as(select 
    s.visitor_id,
    row_number() over (
            partition by s.visitor_id 
            order by s.visit_date desc
        ) as rn,
    l.lead_id,
    case 
            when l.closing_reason = 'успешно реализовано' or l.status_id = 142 
            then 1 else 0 
        end as purchases
from 
    sessions s
left join leads l on s.visitor_id = l.visitor_id
     and l.created_at >= s.visit_date     
    where medium in ('cpc','cpm','cpa','youtube','cpp','tg','social')  
    )
    select 
    count(distinct(visitor_id)) as visitor_count,
    count(distinct(lead_id)) as lead_count,
    sum(coalesce(purchases)) as purchases_count
from tab1
where rn = 1;



with tab1 as (
    select 
        visitor_id,
        min(visit_date) as first_visit_date 
    from sessions
    WHERE medium IN ('cpc','cpm','cpa','youtube','cpp','tg','social')
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
 round(sum( coalesce(total_cost, 0)) /  sum(coalesce(visitors, 0)), 2) as cpu,  
  round(sum( coalesce(total_cost, 0)) / sum(coalesce(lead_count, 0)), 2) as  cpl,
round(sum( coalesce(total_cost, 0)) / sum(coalesce(purchases_count, 0)), 2) cppu ,
 round((sum(coalesce(revenue, 0)) - sum( coalesce(total_cost, 0))) / sum( coalesce(total_cost, 0)) * 100.00, 2) as roi
from tab2 t2
left join tab1 t1 on t2.medium=t1.utm_medium and t2.source=t1.utm_source and 
t2.campaign=t1.utm_campaign
group by 1;


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
 coalesce( round(sum( coalesce(total_cost, 0)) /  sum(nullif(visitors, 0)), 2),0 ) as cpu,  
 coalesce( round(sum( coalesce(total_cost, 0)) / sum(nullif(lead_count, 0)), 2),0 ) as  cpl,
 coalesce(round(sum( coalesce(total_cost, 0)) / sum(nullif(purchases_count, 0)), 2),0 ) as cppu ,
 coalesce(round((sum(coalesce(revenue, 0)) - sum( nullif(total_cost, 0))) / sum( nullif(total_cost, 0)) * 100.00, 2),0 ) as roi
from tab2 t2
left join tab1 t1 on t2.medium=t1.utm_medium and t2.source=t1.utm_source and 
t2.campaign=t1.utm_campaign
group by 1,2,3 ;



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
s.source , s.medium, s.campaign , to_char(visit_date, 'yyyy-mm-dd') as visit_date,
count(distinct s.visitor_id) as visitors, 
sum(case  when l.closing_reason = 'успешно реализовано' or l.status_id = 142 then 1 
  else 0 
  end ) as purchases_count, 
  count(distinct l.lead_id) as lead_count,
  sum(l.amount) as revenue
from  sessions s
left join leads l on l.visitor_id = s.visitor_id
where s.source in ('vk', 'yandex')
group by 1,2,3,4
order by  1 desc
)
 select t2.visit_date, t2.source  as utm_source, 
 t2.medium as utm_medium, 
 t2.campaign as utm_campaign,
 visitors, lead_count,purchases_count, coalesce(revenue, 0) as revenue, coalesce(total_cost, 0) as total_cost,
coalesce( round(sum( coalesce(total_cost, 0)) /  sum(nullif(visitors, 0)), 2),0 ) as cpu,  
 coalesce( round(sum( coalesce(total_cost, 0)) / sum(nullif(lead_count, 0)), 2),0 ) as  cpl,
 coalesce(round(sum( coalesce(total_cost, 0)) / sum(nullif(purchases_count, 0)), 2),0 ) as cppu ,
 coalesce(round((sum(coalesce(revenue, 0)) - sum( nullif(total_cost, 0))) / sum( nullif(total_cost, 0)) * 100.00, 2),0 ) as roi
from tab2 t2
left join tab1 t1 on t2.medium=t1.utm_medium and t2.source=t1.utm_source and 
t2.campaign=t1.utm_campaign
group by 1,2,3,4,5,6,7,8,9 ;
