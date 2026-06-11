-- Intermediate (ephemeral): one row per contact_id holding the customer's
-- demographic profile and financial signals. Pure derivations from staging;
-- no joins, no outcome.

select
    contact_id,
    age,
    case
        when age < 30 then 'under_30'
        when age < 45 then '30_to_45'
        when age < 60 then '45_to_60'
        else '60_plus'
    end as age_bucket,
    job,
    marital,
    education,

    -- 'unknown' (and any non-'yes' value) is treated as not-held.
    (credit_default = 'yes') as has_default,
    (housing_loan = 'yes')   as has_housing_loan,
    (personal_loan = 'yes')  as has_personal_loan

from {{ ref('stg_campaign_contacts') }}
