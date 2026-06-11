-- Mart (table): one row per contact — campaign features + macro context +
-- subscription outcome. This is the primary analysis table for Days 3-5,
-- including the causal work (the macro columns are the confounders).
--
-- `duration` (call length) is deliberately EXCLUDED: it is a leakage feature,
-- known only after the call ends, so it trivially predicts the outcome.

select
    feat.contact_id,
    feat.n_contacts_this_campaign,
    feat.n_contacts_prior,
    feat.prior_outcome,
    feat.days_since_last_contact,
    feat.was_previously_contacted,
    feat.contact_channel,
    feat.contact_month,
    feat.contact_dow,
    macro_ctx.emp_var_rate,
    macro_ctx.cons_price_idx,
    macro_ctx.cons_conf_idx,
    macro_ctx.euribor3m,
    macro_ctx.nr_employed,
    stg.subscribed

from {{ ref('int_campaign_features') }} as feat
inner join {{ ref('int_macro_context') }} as macro_ctx
    on feat.contact_id = macro_ctx.contact_id
inner join {{ ref('stg_campaign_contacts') }} as stg
    on feat.contact_id = stg.contact_id
