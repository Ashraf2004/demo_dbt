# AutomateDV Hands-On Exercises

This file contains step-by-step exercises to learn automate_dv concepts practically.

## Exercise 1: Add Products Data Source

### Step 1: Create Raw Product Table in Snowflake
```sql
-- Run this in Snowflake (UTILS schema)
USE DATABASE POC_DBT_PROJECT;
USE SCHEMA UTILS;

CREATE TABLE IF NOT EXISTS raw_products (
    product_id NUMBER,
    product_name VARCHAR(200),
    category VARCHAR(100),
    price NUMBER(10,2),
    supplier_id NUMBER,
    created_date DATE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Insert sample data
INSERT INTO raw_products VALUES
(1001, 'Laptop Pro 15"', 'Electronics', 1299.99, 501, '2024-01-01', '2024-01-01 10:00:00'),
(1002, 'Wireless Mouse', 'Electronics', 29.99, 502, '2024-01-02', '2024-01-02 11:00:00'),
(1003, 'Office Chair Deluxe', 'Furniture', 199.99, 503, '2024-01-03', '2024-01-03 12:00:00'),
(1004, 'Standing Desk', 'Furniture', 399.99, 503, '2024-01-04', '2024-01-04 13:00:00'),
(1005, 'Bluetooth Headphones', 'Electronics', 89.99, 502, '2024-01-05', '2024-01-05 14:00:00');

-- Create suppliers table for relationships
CREATE TABLE IF NOT EXISTS raw_suppliers (
    supplier_id NUMBER,
    supplier_name VARCHAR(200),
    country VARCHAR(100),
    contact_email VARCHAR(200)
);

INSERT INTO raw_suppliers VALUES
(501, 'TechCorp Inc', 'USA', 'contact@techcorp.com'),
(502, 'ElectroSupply Ltd', 'Canada', 'sales@electrosupply.ca'),
(503, 'FurniturePlus', 'Germany', 'info@furnitureplus.de');

-- Create order items for many-to-many relationship
CREATE TABLE IF NOT EXISTS raw_order_items (
    order_item_id NUMBER,
    order_id NUMBER,
    product_id NUMBER,
    quantity NUMBER,
    unit_price NUMBER(10,2),
    line_total NUMBER(10,2)
);

INSERT INTO raw_order_items VALUES
(1, 101, 1001, 1, 1299.99, 1299.99),
(2, 102, 1002, 2, 29.99, 59.98),
(3, 103, 1003, 1, 199.99, 199.99),
(4, 103, 1005, 1, 89.99, 89.99),
(5, 104, 1004, 1, 399.99, 399.99);
```

### Step 2: Update sources.yml
Add these to your existing sources.yml:

```yaml
      - name: raw_products
        description: Raw product catalog data
        columns:
          - name: product_id
            description: Unique product identifier
          - name: product_name
            description: Product display name
          - name: category
            description: Product category
          - name: price
            description: Current product price
          - name: supplier_id
            description: Supplier who provides this product
          - name: created_date
            description: Date product was added to catalog

      - name: raw_suppliers
        description: Raw supplier data
        columns:
          - name: supplier_id
            description: Unique supplier identifier
          - name: supplier_name
            description: Supplier company name
          - name: country
            description: Supplier country
          - name: contact_email
            description: Supplier contact email

      - name: raw_order_items
        description: Raw order line items
        columns:
          - name: order_item_id
            description: Unique order item identifier
          - name: order_id
            description: Parent order identifier
          - name: product_id
            description: Product being ordered
          - name: quantity
            description: Quantity ordered
          - name: unit_price
            description: Price per unit
          - name: line_total
            description: Total for this line item
```

## Exercise 2: Create Staging Models

### Create stg_products.sql
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

### Create stg_suppliers.sql
```sql
-- models/staging/stg_suppliers.sql
{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model:
  raw_data: raw_suppliers
derived_columns:
  RECORD_SOURCE: '!RAW_SUPPLIERS'
  LOAD_DATE: 'CURRENT_TIMESTAMP()'
  EFFECTIVE_FROM: 'CURRENT_TIMESTAMP()'
hashed_columns:
  SUPPLIER_HK: 'SUPPLIER_ID'
  SUPPLIER_HASHDIFF:
    is_hashdiff: true
    columns:
      - 'SUPPLIER_ID'
      - 'SUPPLIER_NAME'
      - 'COUNTRY'
      - 'CONTACT_EMAIL'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns'],
                     ranked_columns=none) }}
```

### Create stg_order_items.sql
```sql
-- models/staging/stg_order_items.sql
{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model:
  raw_data: raw_order_items
derived_columns:
  RECORD_SOURCE: '!RAW_ORDER_ITEMS'
  LOAD_DATE: 'CURRENT_TIMESTAMP()'
  EFFECTIVE_FROM: 'CURRENT_TIMESTAMP()'
hashed_columns:
  ORDER_ITEM_HK: 'ORDER_ITEM_ID'
  ORDER_HK: 'ORDER_ID'
  PRODUCT_HK: 'PRODUCT_ID'
  ORDER_PRODUCT_HK:
    - 'ORDER_ID'
    - 'PRODUCT_ID'
  ORDER_ITEM_HASHDIFF:
    is_hashdiff: true
    columns:
      - 'ORDER_ITEM_ID'
      - 'QUANTITY'
      - 'UNIT_PRICE'
      - 'LINE_TOTAL'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns'],
                     ranked_columns=none) }}
```

## Exercise 3: Create Hub Models

### Create hub_product.sql
```sql
-- models/raw_vault/hubs/hub_product.sql
{{ config(materialized='incremental') }}

{%- set source_model = "stg_products" -%}
{%- set src_pk = "PRODUCT_HK" -%}
{%- set src_nk = "PRODUCT_ID" -%}
{%- set src_ldts = "LOAD_DATE" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                   src_source=src_source, source_model=source_model) }}
```

### Create hub_supplier.sql
```sql
-- models/raw_vault/hubs/hub_supplier.sql
{{ config(materialized='incremental') }}

{%- set source_model = "stg_suppliers" -%}
{%- set src_pk = "SUPPLIER_HK" -%}
{%- set src_nk = "SUPPLIER_ID" -%}
{%- set src_ldts = "LOAD_DATE" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                   src_source=src_source, source_model=source_model) }}
```

## Exercise 4: Create Link Models

### Create link_product_supplier.sql
```sql
-- models/raw_vault/links/link_product_supplier.sql
{{ config(materialized='incremental') }}

{%- set source_model = "stg_products" -%}
{%- set src_pk = "PRODUCT_SUPPLIER_HK" -%}
{%- set src_fk = ["PRODUCT_HK", "SUPPLIER_HK"] -%}
{%- set src_ldts = "LOAD_DATE" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
```

### Create link_order_product.sql
```sql
-- models/raw_vault/links/link_order_product.sql
{{ config(materialized='incremental') }}

{%- set source_model = "stg_order_items" -%}
{%- set src_pk = "ORDER_PRODUCT_HK" -%}
{%- set src_fk = ["ORDER_HK", "PRODUCT_HK"] -%}
{%- set src_ldts = "LOAD_DATE" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
```

## Exercise 5: Create Satellite Models

### Create sat_product.sql
```sql
-- models/raw_vault/satellites/sat_product.sql
{{ config(materialized='incremental') }}

{%- set source_model = "stg_products" -%}
{%- set src_pk = "PRODUCT_HK" -%}
{%- set src_hashdiff = "PRODUCT_HASHDIFF" -%}
{%- set src_payload = ["PRODUCT_NAME", "CATEGORY", "PRICE", "CREATED_DATE"] -%}
{%- set src_eff = "EFFECTIVE_FROM" -%}
{%- set src_ldts = "LOAD_DATE" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff, src_payload=src_payload,
                   src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                   source_model=source_model) }}
```

### Create sat_supplier.sql
```sql
-- models/raw_vault/satellites/sat_supplier.sql
{{ config(materialized='incremental') }}

{%- set source_model = "stg_suppliers" -%}
{%- set src_pk = "SUPPLIER_HK" -%}
{%- set src_hashdiff = "SUPPLIER_HASHDIFF" -%}
{%- set src_payload = ["SUPPLIER_NAME", "COUNTRY", "CONTACT_EMAIL"] -%}
{%- set src_eff = "EFFECTIVE_FROM" -%}
{%- set src_ldts = "LOAD_DATE" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff, src_payload=src_payload,
                   src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                   source_model=source_model) }}
```

### Create sat_order_item.sql
```sql
-- models/raw_vault/satellites/sat_order_item.sql
{{ config(materialized='incremental') }}

{%- set source_model = "stg_order_items" -%}
{%- set src_pk = "ORDER_PRODUCT_HK" -%}
{%- set src_hashdiff = "ORDER_ITEM_HASHDIFF" -%}
{%- set src_payload = ["QUANTITY", "UNIT_PRICE", "LINE_TOTAL"] -%}
{%- set src_eff = "EFFECTIVE_FROM" -%}
{%- set src_ldts = "LOAD_DATE" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff, src_payload=src_payload,
                   src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                   source_model=source_model) }}
```

## Exercise 6: Test the Implementation

### Run Commands in Order:
```bash
# 1. Test staging models
dbt run --select staging

# 2. Run hubs
dbt run --select tag:hub

# 3. Run links  
dbt run --select tag:link

# 4. Run satellites
dbt run --select tag:satellite

# 5. Run everything
dbt run

# 6. Test data quality
dbt test
```

## Exercise 7: Simulate Data Changes

### Add New Products
```sql
-- Run in Snowflake to simulate new data
INSERT INTO raw_products VALUES
(1006, 'Gaming Keyboard RGB', 'Electronics', 129.99, 502, '2024-01-10', '2024-01-10 15:00:00'),
(1007, 'Monitor 27" 4K', 'Electronics', 449.99, 501, '2024-01-11', '2024-01-11 16:00:00');

-- Update existing product price
UPDATE raw_products 
SET price = 1199.99, last_updated = '2024-01-12 10:00:00'
WHERE product_id = 1001;
```

### Run Incremental Load
```bash
# Run again to see incremental loading
dbt run

# Check what changed
dbt run --select sat_product
```

## Exercise 8: Query the Data Vault

### Current State Queries
```sql
-- Current products with suppliers
SELECT 
    h.PRODUCT_ID,
    s.PRODUCT_NAME,
    s.CATEGORY,
    s.PRICE,
    sup.SUPPLIER_NAME
FROM hub_product h
JOIN sat_product s ON h.PRODUCT_HK = s.PRODUCT_HK
JOIN link_product_supplier l ON h.PRODUCT_HK = l.PRODUCT_HK  
JOIN hub_supplier hs ON l.SUPPLIER_HK = hs.SUPPLIER_HK
JOIN sat_supplier sup ON hs.SUPPLIER_HK = sup.SUPPLIER_HK
WHERE s.LOAD_DATE = (
    SELECT MAX(LOAD_DATE) 
    FROM sat_product s2 
    WHERE s2.PRODUCT_HK = s.PRODUCT_HK
);
```

### Historical Queries
```sql
-- Product price history
SELECT 
    h.PRODUCT_ID,
    s.PRODUCT_NAME,
    s.PRICE,
    s.LOAD_DATE,
    s.RECORD_SOURCE
FROM hub_product h
JOIN sat_product s ON h.PRODUCT_HK = s.PRODUCT_HK
WHERE h.PRODUCT_ID = 1001
ORDER BY s.LOAD_DATE;
```

## Key Learning Points

After completing these exercises, you'll understand:

1. **Hash Key Generation**: How automate_dv creates consistent hash keys
2. **Change Detection**: How hash diffs identify data changes
3. **Incremental Loading**: How satellites only store changes
4. **Relationship Modeling**: How links connect business entities
5. **Historical Tracking**: How to query current vs historical data
6. **Scalability**: How easy it is to add new data sources

## Next Advanced Exercises

1. Create business vault calculations
2. Implement Point-in-Time (PIT) tables
3. Add data quality tests
4. Create information marts
5. Implement slowly changing dimensions (SCD)

This hands-on approach will give you deep understanding of automate_dv's power and flexibility!