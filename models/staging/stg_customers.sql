{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model:
  raw_data: raw_customers
derived_columns:
  RECORD_SOURCE: '!RAW_CUSTOMERS'
  LOAD_DATE: 'CURRENT_TIMESTAMP()'
  EFFECTIVE_FROM: 'CURRENT_TIMESTAMP()'
hashed_columns:
  CUSTOMER_HK: 'CUSTOMER_ID'
  CUSTOMER_HASHDIFF:
    is_hashdiff: true
    columns:
      - 'CUSTOMER_ID'
      - 'FIRST_NAME'
      - 'LAST_NAME'
      - 'EMAIL'
      - 'PHONE'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns'],
                     ranked_columns=none) }}