{{ config(materialized='table') }}

with raw_sales as (
    select 1 as sale_id, 'john doe' as customer_name, 15000 as amount_cents, '2024-01-15'::date as sale_date
    union all
    select 2, 'jane smith', 25000, '2024-02-20'::date
    union all
    select 3, 'bob johnson', 35000, '2024-03-10'::date
    union all
    select 4, null, 10000, '2024-04-05'::date
)

select
    sale_id,
    {{ clean_string('customer_name') }} as customer_name_clean,
    amount_cents,
    {{ cents_to_dollars('amount_cents') }} as amount_dollars,
    sale_date,
    {{ fiscal_year('sale_date', 4) }} as fiscal_year,
    {{ get_current_timestamp() }} as loaded_at
from raw_sales
where customer_name is not null
