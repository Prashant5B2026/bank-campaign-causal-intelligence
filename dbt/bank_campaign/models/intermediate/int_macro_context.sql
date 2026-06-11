-- Intermediate (ephemeral): one row per contact_id holding the macro-economic
-- context at the time of contact.
--
-- CAUSAL NOTE: these five socioeconomic indicators are the macro CONFOUNDERS
-- for the Day 5 causal analysis. They move both the bank's propensity to call
-- (campaign intensity tracks the economic cycle) and a client's propensity to
-- subscribe (deposit appetite tracks rates/employment). Any honest estimate of
-- the campaign's causal effect must adjust for them.

select
    contact_id,
    emp_var_rate,
    cons_price_idx,
    cons_conf_idx,
    euribor3m,
    nr_employed

from {{ ref('stg_campaign_contacts') }}
