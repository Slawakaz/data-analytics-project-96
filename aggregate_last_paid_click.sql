with last_paid_clicks as (
    select
        s.visitor_id,
        date(s.visit_date) as visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        l.lead_id,
        l.amount,
        case
            when l.closing_reason = 'успешно реализовано' 
                or l.status_id = 142 
            then 1 
            else 0 
        end as purchases,
        row_number() over (
            partition by s.visitor_id 
            order by s.visit_date desc
        ) as rn
    from sessions as s
    left join leads as l
        on s.visitor_id = l.visitor_id
        and l.created_at >= s.visit_date
    where s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

combined_ads as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        date(campaign_date) as campaign_date,
        sum(daily_spent) as total_spent
    from (
        select
            utm_source,
            utm_medium,
            utm_campaign,
            daily_spent,
            campaign_date
        from vk_ads
        union all
        select
            utm_source,
            utm_medium,
            utm_campaign,
            daily_spent,
            campaign_date
        from ya_ads
    ) as ads
    group by utm_source, utm_medium, utm_campaign, campaign_date
)

select
    lpc.visit_date,
    count(distinct lpc.visitor_id) as visitors_count,
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign,
    ca.total_spent as total_cost,
    count(distinct lpc.lead_id) as leads_count,
    sum(coalesce(lpc.purchases, 0)) as purchases_count,
    sum(coalesce(lpc.amount, 0)) as revenue
from last_paid_clicks as lpc
left join combined_ads as ca
    on lpc.utm_source = ca.utm_source
    and lpc.utm_medium = ca.utm_medium
    and lpc.utm_campaign = ca.utm_campaign
    and lpc.visit_date = ca.campaign_date
where lpc.rn = 1
group by
    lpc.visit_date,
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign,
    ca.total_spent
order by
    revenue desc nulls last,
    visit_date asc,
    visitors_count desc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc
limit 15;
