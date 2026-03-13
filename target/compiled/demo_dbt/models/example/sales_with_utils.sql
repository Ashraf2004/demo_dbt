

with sales as (
    select * from POC_DBT_PROJECT.UTILS_staging.sales_data
),

date_dim as (
    select * from POC_DBT_PROJECT.UTILS_staging.date_dimension
)

select
    s.sale_id,
    s.customer_name_clean,
    s.amount_dollars,
    s.sale_date,
    d.day_name,
    d.month_num,
    md5(cast(coalesce(cast(s.sale_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(s.customer_name_clean as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as surrogate_key,
    
    ( s.amount_dollars ) / nullif( ( nullif(d.month_num, 0) ), 0)
 as amount_per_month_num
from sales s
left join date_dim d on s.sale_date = d.date_day