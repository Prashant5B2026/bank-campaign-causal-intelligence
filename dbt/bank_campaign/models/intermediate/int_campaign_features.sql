-- Intermediate (ephemeral): one row per contact_id holding campaign-specific
-- features (how the client was contacted and their prior-campaign history).

select
    contact_id,
    campaign                 as n_contacts_this_campaign,
    previous                 as n_contacts_prior,
    poutcome                 as prior_outcome,
    days_since_last_contact,
    was_previously_contacted,
    contact_channel,
    contact_month,
    contact_dow

from {{ ref('stg_campaign_contacts') }}
