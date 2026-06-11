-- Staging: one cleaned, typed row per campaign contact.
--
-- Responsibilities of this layer:
--   * snake_case / unambiguous column names (the source `default`, `housing`,
--     `loan`, `contact`, `month`, `day_of_week` are renamed).
--   * explicit casts so nothing downstream relies on inferred types.
--   * pdays == 999 ("never previously contacted") -> NULL, with an explicit
--     was_previously_contacted boolean flag.
--   * a surrogate contact_id (the source has no primary key).
--
-- duration is carried here for completeness but is a LEAKAGE feature (only
-- known after a call ends) and is dropped at the mart layer.

with source as (

    select
        age,
        job,
        marital,
        education,
        `default`   as credit_default,
        housing     as housing_loan,
        loan        as personal_loan,
        contact     as contact_channel,
        month       as contact_month,
        day_of_week as contact_dow,
        duration,
        campaign,
        pdays,
        previous,
        poutcome,
        emp_var_rate,
        cons_price_idx,
        cons_conf_idx,
        euribor3m,
        nr_employed,
        y
    from {{ source('raw', 'campaign_contacts') }}

)

select
    -- Surrogate key. The source has no primary key, so assign a row number
    -- ordered by a fingerprint of the whole row: deterministic across rebuilds
    -- as long as the underlying data is unchanged.
    row_number() over (order by farm_fingerprint(to_json_string(source))) as contact_id,

    cast(age as int64)             as age,
    cast(job as string)            as job,
    cast(marital as string)        as marital,
    cast(education as string)      as education,

    cast(credit_default as string) as credit_default,
    cast(housing_loan as string)   as housing_loan,
    cast(personal_loan as string)  as personal_loan,

    cast(contact_channel as string) as contact_channel,
    cast(contact_month as string)   as contact_month,
    cast(contact_dow as string)     as contact_dow,

    -- LEAKAGE: known only after the call completes. Excluded from all marts.
    cast(duration as int64)        as duration,

    cast(campaign as int64)        as campaign,
    cast(previous as int64)        as previous,

    -- 999 is a sentinel for "never previously contacted" -> NULL + flag.
    case when pdays = 999 then null else cast(pdays as int64) end as days_since_last_contact,
    (pdays != 999)                 as was_previously_contacted,

    cast(poutcome as string)       as poutcome,

    cast(emp_var_rate as float64)   as emp_var_rate,
    cast(cons_price_idx as float64) as cons_price_idx,
    cast(cons_conf_idx as float64)  as cons_conf_idx,
    cast(euribor3m as float64)      as euribor3m,
    cast(nr_employed as float64)    as nr_employed,

    (y = 'yes')                    as subscribed

from source
