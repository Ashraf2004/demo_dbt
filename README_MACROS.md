# dbt Macros Guide for Snowflake Migration

## Setup Instructions

### 1. Install Package Dependencies
```bash
dbt deps
```
This installs `dbt-utils` package into `dbt_packages/` folder.

### 2. Run the Models
```bash
dbt run
```

### 3. Test the Models
```bash
dbt test
```

## Macros Created

### Custom Macros (`macros/custom_macros.sql`)

1. **cents_to_dollars(column_name, scale=2)**
   - Converts cents to dollars
   - Usage: `{{ cents_to_dollars('amount_cents') }}`
   - Snowflake compatible

2. **clean_string(column_name)**
   - Trims and uppercases strings
   - Usage: `{{ clean_string('customer_name') }}`

3. **get_current_timestamp()**
   - Returns current timestamp with warehouse-specific syntax
   - Adapts automatically for Snowflake, BigQuery, Postgres
   - Usage: `{{ get_current_timestamp() }}`

4. **generate_alias_name()**
   - Controls model naming in the warehouse
   - Overrides dbt's default behavior

### Date Macros (`macros/date_macros.sql`)

1. **date_spine(start_date, end_date)**
   - Generates date dimension using dbt_utils
   - Usage: `{{ date_spine('2024-01-01', '2024-12-31') }}`

2. **fiscal_year(date_column, fiscal_year_start_month)**
   - Calculates fiscal year from calendar date
   - Usage: `{{ fiscal_year('sale_date', 4) }}` for April start

## Models Using Macros

### sales_data.sql
- Uses: `clean_string`, `cents_to_dollars`, `fiscal_year`, `get_current_timestamp`
- Demonstrates custom macro usage

### date_dimension.sql
- Uses: `date_spine` (which wraps dbt_utils.date_spine)
- Creates a full calendar table

### sales_with_utils.sql
- Uses: `dbt_utils.generate_surrogate_key`, `dbt_utils.safe_divide`
- Demonstrates package macro usage
- Uses `ref()` for model dependencies

## Snowflake-Specific Features

### Adapter Macros
The `get_current_timestamp()` macro shows how to handle warehouse differences:
```sql
{% if target.type == 'snowflake' %}
    current_timestamp()
{% elif target.type == 'bigquery' %}
    current_timestamp()
{% endif %}
```

### Testing in Snowflake
After running `dbt deps` and `dbt run`, you can query in Snowflake:
```sql
-- Check the transformed data
SELECT * FROM POC_DBT_PROJECT.UTILS.sales_data;

-- Check date dimension
SELECT * FROM POC_DBT_PROJECT.UTILS.date_dimension LIMIT 10;

-- Check surrogate keys
SELECT * FROM POC_DBT_PROJECT.UTILS.sales_with_utils;
```

## Migration Benefits

1. **Reusability**: Write once, use everywhere
2. **Maintainability**: Update logic in one place
3. **Cross-database**: Macros adapt to different warehouses
4. **DRY Code**: No repeated SQL patterns
5. **Package Ecosystem**: Leverage community macros from dbt-utils

## Next Steps

1. Run `dbt deps` to install dbt_utils
2. Run `dbt run` to build models in Snowflake
3. Run `dbt test` to validate data quality
4. Check Snowflake warehouse to see the results
5. Modify macros and see changes propagate to all models
