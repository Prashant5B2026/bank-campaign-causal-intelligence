-- Mart (table): subscription performance aggregated by customer segment
-- (job x age_bucket x education). Powers quick segmentation views — no
-- contact-level grain here.

select
    job,
    age_bucket,
    education,
    count(*)                                   as n_contacts,
    countif(subscribed)                        as n_subscribed,
    safe_divide(countif(subscribed), count(*)) as subscription_rate

from {{ ref('mart_customers') }}
group by job, age_bucket, education
