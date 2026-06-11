-- Mart (table): one row per customer contact — demographic/financial profile
-- plus the subscription outcome. The customer-centric analysis table.

select
    profile.contact_id,
    profile.age,
    profile.age_bucket,
    profile.job,
    profile.marital,
    profile.education,
    profile.has_default,
    profile.has_housing_loan,
    profile.has_personal_loan,
    stg.subscribed

from {{ ref('int_customer_profile') }} as profile
inner join {{ ref('stg_campaign_contacts') }} as stg
    on profile.contact_id = stg.contact_id
