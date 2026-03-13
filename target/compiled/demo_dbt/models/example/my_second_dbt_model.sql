-- Use the `ref` function to select from other models

select *
from POC_DBT_PROJECT.UTILS_staging.my_first_dbt_model
where id = 1