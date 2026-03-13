{{ config(materialized='table') }}

with source_data as (

    select 3 as id

)

select *
from source_data