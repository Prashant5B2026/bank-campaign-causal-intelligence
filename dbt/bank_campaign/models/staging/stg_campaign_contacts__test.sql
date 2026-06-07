-- Trivial connection-test model: counts rows in the raw landing table.
-- If this materializes, the dbt -> BigQuery connection and the raw source
-- are both working. Materialized as a view per the staging layer config.

select
    count(*) as row_count
from {{ source('raw', 'campaign_contacts') }}
