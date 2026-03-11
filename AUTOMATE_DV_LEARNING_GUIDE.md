# AutomateDV Learning Guide - Complete Data Vault Implementation

This guide will walk you through all automate_dv concepts using practical examples. We'll explore every feature and scenario to understand the real power of Data Vault automation.

## Table of Contents
1. [Data Vault Basics](#data-vault-basics)
2. [AutomateDV Architecture](#automatedv-architecture)
3. [Staging Layer Deep Dive](#staging-layer-deep-dive)
4. [Hub Implementation](#hub-implementation)
5. [Link Implementation](#link-implementation)
6. [Satellite Implementation](#satellite-implementation)
7. [Advanced Scenarios](#advanced-scenarios)
8. [Performance Optimization](#performance-optimization)
9. [Testing and Validation](#testing-and-validation)

## Data Vault Basics

### What is Data Vault?
Data Vault is a data modeling methodology designed for data warehouses that provides:
- **Auditability**: Complete history of data changes
- **Flexibility**: Easy to add new data sources
- **Scalability**: Handles large volumes efficiently
- **Traceability**: Track data lineage

### Core Components:
1. **Hubs**: Business keys (customers, orders, products)
2. **Links**: Relationships between business keys
3. **Satellites**: Descriptive attributes and history

## AutomateDV Architecture

AutomateDV automates the creation of Data Vault structures using DBT macros:

```
Raw Data → Staging → Raw Vault → Business Vault → Information Marts
```

## Staging Layer Deep Dive

### Current Staging Models Analysis

Let's examine what our current staging models do:

#### stg_customers.sql
```sql
{%- set yaml_metadata -%}
source_model:
  raw_data: raw_customers
derived_columns:
  RECORD_SOURCE: '!RAW_CUSTOMERS'      # Source system identifier
  LOAD_DATE: 'CURRENT_TIMESTAMP()'     # When record was loaded
  EFFECTIVE_FROM: 'CURRENT_TIMESTAMP()' # When record became effective
hashed_columns:
  CUSTOMER_HK: 'CUSTOMER_ID'           # Hub hash key
  CUSTOMER_HASHDIFF:                   # Satellite hash diff
    is_hashdiff: true
    columns:
      - 'CUSTOMER_ID'
      - 'FIRST_NAME'
      - 'LAST_NAME'
      - 'EMAIL'
      - 'PHONE'
{%- endset -%}
```

### What AutomateDV Staging Does:
1. **Generates Hash Keys**: Creates consistent hash values for business keys
2. **Creates Hash Diffs**: Detects changes in satellite data
3. **Adds Metadata**: Load dates, record sources, effective dates
4. **Standardizes Format**: Consistent column naming and types

## Hub Implementation

### Current Hub Models

#### hub_customer.sql
```sql
{%- set source_model = "stg_customers" -%}
{%- set src_pk = "CUSTOMER_HK" -%}
{%- set src_nk = "CUSTOMER_ID" -%}
```

### Hub Functionality:
- **Deduplication**: Only unique business keys
- **Auditability**: Load date tracking
- **Immutability**: Once created, never updated

## Link Implementation

### Current Link Model

#### link_customer_order.sql
```sql
{%- set source_model = "stg_orders" -%}
{%- set src_pk = "CUSTOMER_ORDER_HK" -%}
{%- set src_fk = ["CUSTOMER_HK", "ORDER_HK"] -%}
```

### Link Functionality:
- **Relationships**: Connects business entities
- **Many-to-Many**: Handles complex relationships
- **Temporal**: Tracks when relationships existed

## Satellite Implementation

### Current Satellite Models

#### sat_customer.sql
```sql
{%- set source_model = "stg_customers" -%}
{%- set src_pk = "CUSTOMER_HK" -%}
{%- set src_hashdiff = "CUSTOMER_HASHDIFF" -%}
```

### Satellite Functionality:
- **Change Detection**: Only stores when data changes
- **History**: Maintains complete audit trail
- **Efficiency**: Hash diff prevents unnecessary inserts

---

# Practical Learning Scenarios

## Scenario 1: Adding New Data Sources

Let's add a new products table to understand how automate_dv scales:

### Step 1: Create Raw Product Data
```sql
-- Add to your Snowflake UTILS schema
CREATE TABLE IF NOT EXISTS raw_products (
    product_id NUMBER,
    product_name VARCHAR(200),
    category VARCHAR(100),
    price NUMBER(10,2),
    supplier_id NUMBER,
    created_date DATE
);

INSERT INTO raw_products VALUES
(1001, 'Laptop Pro', 'Electronics', 1299.99, 501, '2024-01-01'),
(1002, 'Wireless Mouse', 'Electronics', 29.99, 502, '2024-01-02'),
(1003, 'Office Chair', 'Furniture', 199.99, 503, '2024-01-03');
```

### Step 2: Add to Sources
```yaml
# Add to sources.yml
- name: raw_products
  description: Raw product data
  columns:
    - name: product_id
    - name: product_name
    - name: category
    - name: price
    - name: supplier_id
    - name: created_date
```

### Step 3: Create Staging Model
```sql
-- models/staging/stg_products.sql
{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model:
  raw_data: raw_products
derived_columns:
  RECORD_SOURCE: '!RAW_PRODUCTS'
  LOAD_DATE: 'CURRENT_TIMESTAMP()'
  EFFECTIVE_FROM: 'CURRENT_TIMESTAMP()'
hashed_columns:
  PRODUCT_HK: 'PRODUCT_ID'
  SUPPLIER_HK: 'SUPPLIER_ID'
  PRODUCT_SUPPLIER_HK:
    - 'PRODUCT_ID'
    - 'SUPPLIER_ID'
  PRODUCT_HASHDIFF:
    is_hashdiff: true
    columns:
      - 'PRODUCT_ID'
      - 'PRODUCT_NAME'
      - 'CATEGORY'
      - 'PRICE'
      - 'CREATED_DATE'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns'],
                     ranked_columns=none) }}
```

## Scenario 2: Complex Relationships

### Multi-Hub Links
```sql
-- models/raw_vault/links/link_order_product.sql
{{ config(materialized='incremental') }}

{%- set source_model = "stg_order_items" -%}  -- New staging model needed
{%- set src_pk = "ORDER_PRODUCT_HK" -%}
{%- set src_fk = ["ORDER_HK", "PRODUCT_HK"] -%}
{%- set src_ldts = "LOAD_DATE" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
```

## Scenario 3: Handling Data Changes

### Satellite Change Detection
When source data changes, satellites automatically:
1. Calculate new hash diff
2. Compare with existing hash diff
3. Insert only if different
4. Maintain complete history

### Example: Customer Email Change
```sql
-- Original record
CUSTOMER_HK | HASHDIFF | EMAIL | LOAD_DATE
ABC123     | XYZ789   | old@email.com | 2024-01-01

-- After email change
CUSTOMER_HK | HASHDIFF | EMAIL | LOAD_DATE  
ABC123     | XYZ789   | old@email.com | 2024-01-01  -- Historical
ABC123     | DEF456   | new@email.com | 2024-01-15  -- Current
```

## Scenario 4: Advanced Hash Strategies

### Composite Business Keys
```sql
hashed_columns:
  CUSTOMER_ORDER_HK:
    - 'CUSTOMER_ID'
    - 'ORDER_ID'
    - 'ORDER_DATE'  -- Include date for uniqueness
```

### Excluding Columns from Hash Diff
```sql
hashed_columns:
  ORDER_HASHDIFF:
    is_hashdiff: true
    columns:
      - 'ORDER_ID'
      - 'TOTAL_AMOUNT'
      - 'STATUS'
    exclude_columns:  -- Don't include in change detection
      - 'LAST_UPDATED'
      - 'INTERNAL_NOTES'
```

## Scenario 5: Performance Optimization

### Incremental Loading
```sql
{{ config(
    materialized='incremental',
    unique_key='CUSTOMER_HK',
    on_schema_change='append_new_columns'
) }}
```

### Partitioning Strategy
```sql
{{ config(
    materialized='incremental',
    cluster_by=['LOAD_DATE', 'CUSTOMER_HK']
) }}
```

## Scenario 6: Data Quality and Testing

### Hub Tests
```yaml
# models/raw_vault/hubs/schema.yml
models:
  - name: hub_customer
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - CUSTOMER_HK
    columns:
      - name: CUSTOMER_HK
        tests:
          - not_null
          - unique
```

### Satellite Tests
```yaml
models:
  - name: sat_customer
    tests:
      - automate_dv.sat_hashdiff_test:
          parent_table: hub_customer
          parent_column: CUSTOMER_HK
```

## Scenario 7: Business Vault Layer

### Calculated Satellites
```sql
-- models/business_vault/sat_customer_calculated.sql
{{ config(materialized='incremental') }}

WITH customer_metrics AS (
    SELECT 
        c.CUSTOMER_HK,
        COUNT(o.ORDER_HK) as TOTAL_ORDERS,
        SUM(o.TOTAL_AMOUNT) as LIFETIME_VALUE,
        MAX(o.ORDER_DATE) as LAST_ORDER_DATE,
        CURRENT_TIMESTAMP() as LOAD_DATE,
        '!CALCULATED' as RECORD_SOURCE
    FROM {{ ref('hub_customer') }} c
    LEFT JOIN {{ ref('link_customer_order') }} l ON c.CUSTOMER_HK = l.CUSTOMER_HK
    LEFT JOIN {{ ref('sat_order') }} o ON l.ORDER_HK = o.ORDER_HK
    GROUP BY c.CUSTOMER_HK
)

SELECT * FROM customer_metrics
```

## Scenario 8: Point-in-Time Tables

### PIT Implementation
```sql
-- models/business_vault/pit_customer.sql
{{ config(materialized='incremental') }}

{%- set src_pk = 'CUSTOMER_HK' -%}
{%- set src_ldts = 'LOAD_DATE' -%}
{%- set satellites = ['sat_customer', 'sat_customer_calculated'] -%}

{{ automate_dv.pit(src_pk=src_pk, src_ldts=src_ldts, 
                   satellites=satellites, stage_tables_ldts='LOAD_DATE') }}
```

## Key AutomateDV Benefits Demonstrated

### 1. **Consistency**
- Standardized hash algorithms
- Consistent metadata columns
- Uniform naming conventions

### 2. **Automation**
- Automatic change detection
- Built-in deduplication
- Incremental loading patterns

### 3. **Scalability**
- Easy to add new sources
- Handles complex relationships
- Performance optimizations built-in

### 4. **Auditability**
- Complete data lineage
- Change history preservation
- Source system tracking

### 5. **Flexibility**
- Multiple source formats
- Custom hash strategies
- Configurable loading patterns

## Next Steps for Learning

1. **Implement the product scenario** above
2. **Create order_items table** for many-to-many relationships
3. **Add business vault calculations**
4. **Implement PIT tables**
5. **Create information marts**

This guide provides a foundation for understanding automate_dv's power in creating robust, scalable Data Vault implementations.