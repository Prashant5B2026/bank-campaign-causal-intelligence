-- Singular test: the overall term-deposit subscription rate in
-- mart_campaign_outcomes must sit between 5% and 20%. The real rate is ~11%;
-- a value outside this band means the load or a join went wrong (e.g. fanned-
-- out rows, a botched outcome cast, or a partial load).
--
-- A test passes when it returns zero rows, so this selects the rate only when
-- it is implausible.

select
    avg(case when subscribed then 1.0 else 0.0 end) as subscription_rate
from {{ ref('mart_campaign_outcomes') }}
having subscription_rate < 0.05 or subscription_rate > 0.20
