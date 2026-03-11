{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model:
  raw_data: raw_orders
derived_columns:
  RECORD_SOURCE: '!RAW_ORDERS'
  LOAD_DATE: 'CURRENT_TIMESTAMP()'
  EFFECTIVE_FROM: 'CURRENT_TIMESTAMP()'
hashed_columns:
  ORDER_HK: 'ORDER_ID'
  CUSTOMER_HK: 'CUSTOMER_ID'
  CUSTOMER_ORDER_HK:
    - 'CUSTOMER_ID'
    - 'ORDER_ID'
  ORDER_HASHDIFF:
    is_hashdiff: true
    columns:
      - 'ORDER_ID'
      - 'ORDER_DATE'
      - 'TOTAL_AMOUNT'
      - 'STATUS'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns'],
                     ranked_columns=none) }}