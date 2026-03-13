
    
    

select
    date_day as unique_field,
    count(*) as n_records

from POC_DBT_PROJECT.UTILS_staging.date_dimension
where date_day is not null
group by date_day
having count(*) > 1


