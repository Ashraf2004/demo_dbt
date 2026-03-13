
    
    

select
    sale_id as unique_field,
    count(*) as n_records

from POC_DBT_PROJECT.UTILS_staging.sales_data
where sale_id is not null
group by sale_id
having count(*) > 1


