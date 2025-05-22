SELECT
    visit_date::DATE AS visit_date,
    COUNT(DISTINCT visitor_id) AS visitor_count
FROM sessions
GROUP BY visit_date::DATE;
SELECT
    visit_date::DATE AS visit_date,
    source,
    medium,
    campaign,
    COUNT(DISTINCT visitor_id) AS visitor_count
FROM sessions
GROUP BY visit_date::DATE, source, medium, campaign;
SELECT
    TO_CHAR(visit_date, 'IDDay') AS day_of_week,
    COUNT(DISTINCT visitor_id) AS visitor_count
FROM sessions
GROUP BY
    TO_CHAR(visit_date, 'IDDay');
SELECT
    source,
    medium,
    campaign,
    visit_date::DATE AS visit_date,
    TO_CHAR(visit_date, 'IDDay') AS day_of_week,
    COUNT(DISTINCT visitor_id) AS visitor_count
FROM sessions
GROUP BY
    source,
    medium,
    campaign,
    visit_date::DATE,
    TO_CHAR(visit_date, 'IDDay');
WITH tab1 AS (
    SELECT
        campaign_date,
        daily_spent
    FROM vk_ads
    UNION ALL
    SELECT
        campaign_date,
        daily_spent
    FROM ya_ads
)

SELECT
    TO_CHAR(campaign_date, 'yyyy-mm-dd') AS visit_date,
    SUM(daily_spent) AS total_spent
FROM tab1
GROUP BY
    TO_CHAR(campaign_date, 'yyyy-mm-dd');
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
WITH tab1 AS (
    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
    GROUP BY utm_source, utm_medium, utm_campaign

    UNION ALL

    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    GROUP BY utm_source, utm_medium, utm_campaign
),

tab2 AS (
    SELECT
        s.source,
        s.medium,
        s.campaign,
        COUNT(DISTINCT s.visitor_id) AS visitors,
        SUM(
            CASE
                WHEN
                    l.closing_reason = 'Успешно реализовано'
                    OR l.status_id = 142
                    THEN 1
                ELSE 0
            END
        ) AS purchases_count,
        COUNT(DISTINCT l.lead_id) AS lead_count,
        SUM(l.amount) AS revenue
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id
    WHERE s.source IN ('vk', 'yandex')
    GROUP BY s.source, s.medium, s.campaign
)

SELECT
    t2.source AS utm_source,
    COALESCE(
        ROUND(
            SUM(COALESCE(t1.total_cost, 0))
            / NULLIF(SUM(COALESCE(t2.visitors, 0)), 0),
            2
        ),
        0
    ) AS cpu,
    COALESCE(
        ROUND(
            SUM(COALESCE(t1.total_cost, 0))
            / NULLIF(SUM(COALESCE(t2.lead_count, 0)), 0),
            2
        ),
        0
    ) AS cpl,
    COALESCE(
        ROUND(
            SUM(COALESCE(t1.total_cost, 0))
            / NULLIF(SUM(COALESCE(t2.purchases_count, 0)), 0),
            2
        ),
        0
    ) AS cppu,
    COALESCE(
        ROUND(
            (
                SUM(COALESCE(t2.revenue, 0))
                - SUM(COALESCE(t1.total_cost, 0))
            )
            / NULLIF(SUM(COALESCE(t1.total_cost, 0)), 0)
            * 100,
            2
        ),
        0
    ) AS roi
FROM tab2 AS t2
LEFT JOIN tab1 AS t1
    ON
        t2.medium = t1.utm_medium
        AND t2.source = t1.utm_source
        AND t2.campaign = t1.utm_campaign
GROUP BY t2.source;
WITH tab1 AS (
    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
    GROUP BY utm_source, utm_medium, utm_campaign

    UNION ALL

    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    GROUP BY utm_source, utm_medium, utm_campaign
),

tab2 AS (
    SELECT
        s.source,
        s.medium,
        s.campaign,
        COUNT(DISTINCT s.visitor_id) AS visitors,
        SUM(
            CASE
                WHEN
                    l.closing_reason = 'Успешно реализовано'
                    OR l.status_id = 142
                    THEN 1
                ELSE 0
            END
        ) AS purchases_count,
        COUNT(DISTINCT l.lead_id) AS lead_count,
        SUM(l.amount) AS revenue
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id
    WHERE s.source IN ('vk', 'yandex')
    GROUP BY s.source, s.medium, s.campaign
)

SELECT
    t2.source AS utm_source,
    t2.medium AS utm_medium,
    t2.campaign AS utm_campaign,
    COALESCE(
        ROUND(
            SUM(COALESCE(t1.total_cost, 0))
            / NULLIF(SUM(COALESCE(t2.visitors, 0)), 0),
            2
        ),
        0
    ) AS cpu,
    COALESCE(
        ROUND(
            SUM(COALESCE(t1.total_cost, 0))
            / NULLIF(SUM(COALESCE(t2.lead_count, 0)), 0),
            2
        ),
        0
    ) AS cpl,
    COALESCE(
        ROUND(
            SUM(COALESCE(t1.total_cost, 0))
            / NULLIF(SUM(COALESCE(t2.purchases_count, 0)), 0),
            2
        ),
        0
    ) AS cppu,
    COALESCE(
        ROUND(
            (
                SUM(COALESCE(t2.revenue, 0))
                - SUM(COALESCE(t1.total_cost, 0))
            )
            / NULLIF(SUM(COALESCE(t1.total_cost, 0)), 0)
            * 100,
            2
        ),
        0
    ) AS roi
FROM tab2 AS t2
LEFT JOIN tab1 AS t1
    ON
        t2.medium = t1.utm_medium
        AND t2.source = t1.utm_source
        AND t2.campaign = t1.utm_campaign
GROUP BY t2.source, t2.medium, t2.campaign;
WITH tab1 AS (
    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
    GROUP BY utm_source, utm_medium, utm_campaign

    UNION ALL

    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    GROUP BY utm_source, utm_medium, utm_campaign
),

tab2 AS (
    SELECT
        s.source,
        s.medium,
        s.campaign,
        TO_CHAR(s.visit_date, 'YYYY-MM-DD') AS visit_date,
        COUNT(DISTINCT s.visitor_id) AS visitors,
        SUM(
            CASE
                WHEN
                    l.closing_reason = 'Успешно реализовано'
                    OR l.status_id = 142
                    THEN 1
                ELSE 0
            END
        ) AS purchases_count,
        COUNT(DISTINCT l.lead_id) AS lead_count,
        SUM(l.amount) AS revenue
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id
    WHERE s.source IN ('vk', 'yandex')
    GROUP BY s.source, s.medium, s.campaign, s.visit_date
)

SELECT
    t2.visit_date,
    t2.source AS utm_source,
    t2.medium AS utm_medium,
    t2.campaign AS utm_campaign,
    t2.visitors,
    t2.lead_count,
    t2.purchases_count,
    COALESCE(t2.revenue, 0) AS revenue,
    COALESCE(t1.total_cost, 0) AS total_cost,
    COALESCE(
        ROUND(SUM(COALESCE(t1.total_cost, 0)) / NULLIF(SUM(t2.visitors), 0), 2),
        0
    ) AS cpu,
    COALESCE(
        ROUND(
            SUM(COALESCE(t1.total_cost, 0)) / NULLIF(SUM(t2.lead_count), 0), 2
        ),
        0
    ) AS cpl,
    COALESCE(
        ROUND(
            SUM(COALESCE(t1.total_cost, 0))
            / NULLIF(SUM(t2.purchases_count), 0),
            2
        ),
        0
    ) AS cppu,
    COALESCE(
        ROUND(
            (SUM(COALESCE(t2.revenue, 0)) - SUM(COALESCE(t1.total_cost, 0)))
            / NULLIF(SUM(COALESCE(t1.total_cost, 0)), 0)
            * 100.00,
            2
        ),
        0
    ) AS roi
FROM tab2 AS t2
LEFT JOIN tab1 AS t1
    ON
        t2.medium = t1.utm_medium
        AND t2.source = t1.utm_source
        AND t2.campaign = t1.utm_campaign
GROUP BY
    t2.visit_date,
    t2.source,
    t2.medium,
    t2.campaign,
    t2.visitors,
    t2.lead_count,
    t2.purchases_count,
    t2.revenue,
    t1.total_cost
ORDER BY t2.source DESC;
