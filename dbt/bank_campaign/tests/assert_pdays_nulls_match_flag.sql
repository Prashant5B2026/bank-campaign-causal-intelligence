-- Singular test: the pdays sentinel handling must be internally consistent.
-- was_previously_contacted = FALSE  iff  days_since_last_contact IS NULL.
--
-- Any row that violates the biconditional (flag FALSE but a non-null recency,
-- or flag TRUE but a null recency) is returned, failing the test.

select
    contact_id,
    was_previously_contacted,
    days_since_last_contact
from {{ ref('mart_campaign_outcomes') }}
where (was_previously_contacted = false and days_since_last_contact is not null)
   or (was_previously_contacted = true  and days_since_last_contact is null)
