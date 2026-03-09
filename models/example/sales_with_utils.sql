{{ config(materialized='view') }}

with sales as (
    select * from {{ ref('sales_data') }}
),

date_dim as (
    select * from {{ ref('date_dimension') }}
)

select
    s.sale_id,
    s.customer_name_clean,
    s.amount_dollars,
    s.sale_date,
    d.day_name,
    d.month_num,
    {{ dbt_utils.generate_surrogate_key(['s.sale_id', 's.customer_name_clean']) }} as surrogate_key,
    {{ dbt_utils.safe_divide('s.amount_dollars', 'nullif(d.month_num, 0)') }} as amount_per_month_num
from sales s
left join date_dim d on s.sale_date = d.date_day
