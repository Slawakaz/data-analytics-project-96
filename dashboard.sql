SELECT
    visit_date::DATE AS visit_date,
    source,
    medium,
    campaign,
    COUNT(DISTINCT visitor_id) AS visitor_count
FROM sessions
GROUP BY visit_date::DATE, source, medium, campaign;

select
    source, 
    medium,
    campaign,
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
    count(distinct visitor_id) as visitor_count
from sessions
group by 1,2,3,4,5;
