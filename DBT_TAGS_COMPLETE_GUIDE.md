# DBT Tags Complete Guide - Grouping and Organization

Tags in DBT are labels that help you organize, group, and selectively run models. They're essential for managing large projects and creating efficient CI/CD workflows.

## Table of Contents
1. [What are DBT Tags?](#what-are-dbt-tags)
2. [Tag Configuration Methods](#tag-configuration-methods)
3. [Running Models by Tags](#running-models-by-tags)
4. [Advanced Tag Strategies](#advanced-tag-strategies)
5. [Real-World Examples](#real-world-examples)
6. [Best Practices](#best-practices)
7. [Tag Combinations](#tag-combinations)

## What are DBT Tags?

Tags are metadata labels that you can assign to models, tests, snapshots, and seeds. They enable:
- **Selective execution**: Run only specific groups of models
- **Logical organization**: Group related models together
- **CI/CD optimization**: Run different model sets in different environments
- **Dependency management**: Control execution order and dependencies

## Tag Configuration Methods

### 1. Model-Level Tags (Individual Files)

#### In Model Config Block
```sql
-- models/staging/stg_customers.sql
{{ config(
    materialized='view',
    tags=['staging', 'customer_domain', 'daily']
) }}

SELECT * FROM {{ source('raw_data', 'raw_customers') }}
```

#### In Model Properties (schema.yml)
```yaml
# models/staging/schema.yml
version: 2

models:
  - name: stg_customers
    tags: ['staging', 'customer_domain', 'pii']
    description: "Staged customer data"
    
  - name: stg_orders
    tags: ['staging', 'order_domain', 'daily']
    description: "Staged order data"
```

### 2. Directory-Level Tags (dbt_project.yml)

```yaml
# dbt_project.yml
models:
  demo_dbt:
    # All staging models get these tags
    staging:
      +tags: ['staging', 'raw_data']
      +materialized: view
      
    # All raw vault models get these tags  
    raw_vault:
      +tags: ['raw_vault', 'data_vault']
      +materialized: incremental
      
      # Specific subdirectory tags
      hubs:
        +tags: ['hub', 'core_entity']
      links:
        +tags: ['link', 'relationship']
      satellites:
        +tags: ['satellite', 'descriptive_data']
        
    # Business vault tags
    business_vault:
      +tags: ['business_vault', 'calculated', 'hourly']
      
    # Mart layer tags
    marts:
      +tags: ['mart', 'end_user', 'reporting']
      finance:
        +tags: ['finance_domain']
      marketing:
        +tags: ['marketing_domain']
```

### 3. Mixed Approach (Inheritance + Override)

```sql
-- This model inherits ['raw_vault', 'data_vault', 'hub', 'core_entity'] from dbt_project.yml
-- Plus adds its own specific tags
{{ config(
    materialized='incremental',
    tags=['customer_hub', 'gdpr_sensitive']  -- Additional tags
) }}

-- models/raw_vault/hubs/hub_customer.sql
{%- set source_model = "stg_customers" -%}
{%- set src_pk = "CUSTOMER_HK" -%}
{%- set src_nk = "CUSTOMER_ID" -%}
{%- set src_ldts = "LOAD_DATE" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                   src_source=src_source, source_model=source_model) }}
```

## Running Models by Tags

### Basic Tag Selection

```bash
# Run all staging models
dbt run --select tag:staging

# Run all hub models
dbt run --select tag:hub

# Run all satellite models
dbt run --select tag:satellite

# Run all models with 'daily' tag
dbt run --select tag:daily
```

### Multiple Tag Selection

```bash
# Run models that have BOTH tags (AND logic)
dbt run --select tag:staging,tag:customer_domain

# Run models that have EITHER tag (OR logic)
dbt run --select tag:staging tag:customer_domain

# Exclude specific tags
dbt run --exclude tag:satellite

# Complex combinations
dbt run --select tag:raw_vault --exclude tag:satellite
```

### Tag with Other Selectors

```bash
# Combine tags with model names
dbt run --select tag:hub stg_customers

# Run tagged models and their downstream dependencies
dbt run --select tag:staging+

# Run tagged models and their upstream dependencies  
dbt run --select +tag:mart

# Run tagged models and all dependencies (up and down)
dbt run --select +tag:hub+
```

## Advanced Tag Strategies

### 1. Layer-Based Tags

```yaml
# dbt_project.yml - Architectural layers
models:
  demo_dbt:
    staging:
      +tags: ['layer:staging', 'frequency:daily']
    raw_vault:
      +tags: ['layer:raw_vault', 'frequency:hourly']
    business_vault:
      +tags: ['layer:business_vault', 'frequency:hourly']
    marts:
      +tags: ['layer:mart', 'frequency:daily']
```

### 2. Domain-Based Tags

```yaml
# Domain-driven design approach
models:
  demo_dbt:
    staging:
      customer:
        +tags: ['domain:customer', 'owner:customer_team']
      order:
        +tags: ['domain:order', 'owner:order_team']
      product:
        +tags: ['domain:product', 'owner:product_team']
```

### 3. Frequency-Based Tags

```sql
-- models/staging/stg_customers.sql
{{ config(
    tags=['frequency:daily', 'priority:high', 'sla:4hours']
) }}

-- models/business_vault/customer_metrics.sql  
{{ config(
    tags=['frequency:hourly', 'priority:medium', 'sla:2hours']
) }}

-- models/marts/finance/revenue_report.sql
{{ config(
    tags=['frequency:weekly', 'priority:low', 'sla:24hours']
) }}
```

### 4. Environment-Based Tags

```yaml
# Different tags for different environments
models:
  demo_dbt:
    staging:
      +tags: 
        - 'env:all'
        - 'ci:required'
    raw_vault:
      +tags:
        - 'env:prod'
        - 'env:staging'
        - 'ci:optional'
    marts:
      +tags:
        - 'env:prod'
        - 'ci:skip'
```

## Real-World Examples

### Example 1: Data Vault Project Structure

```yaml
# dbt_project.yml
models:
  demo_dbt:
    staging:
      +tags: ['layer:staging', 'vault:input']
      +materialized: view
      
    raw_vault:
      +tags: ['layer:raw_vault', 'vault:core']
      +materialized: incremental
      
      hubs:
        +tags: ['vault:hub', 'entity:business_key']
        customer:
          +tags: ['domain:customer']
        order:
          +tags: ['domain:order']
        product:
          +tags: ['domain:product']
          
      links:
        +tags: ['vault:link', 'entity:relationship']
        
      satellites:
        +tags: ['vault:satellite', 'entity:descriptive']
        
    business_vault:
      +tags: ['layer:business_vault', 'vault:calculated']
      
      pit:
        +tags: ['vault:pit', 'performance:optimized']
      bridge:
        +tags: ['vault:bridge', 'performance:optimized']
        
    marts:
      +tags: ['layer:mart', 'vault:presentation']
      finance:
        +tags: ['domain:finance', 'audience:finance_team']
      marketing:
        +tags: ['domain:marketing', 'audience:marketing_team']
```

### Example 2: CI/CD Workflow Tags

```yaml
# .github/workflows/dbt-ci.yml
# Fast CI pipeline - only essential models
- name: Run CI Models
  run: dbt run --select tag:ci_required

# Full deployment pipeline  
- name: Run All Staging
  run: dbt run --select tag:layer:staging
  
- name: Run Raw Vault
  run: dbt run --select tag:layer:raw_vault
  
- name: Run Business Vault
  run: dbt run --select tag:layer:business_vault
  
- name: Run Critical Marts Only
  run: dbt run --select tag:priority:high,tag:layer:mart
```

### Example 3: Incremental Development

```bash
# Developer working on customer domain
dbt run --select tag:domain:customer

# Data engineer working on vault layer
dbt run --select tag:layer:raw_vault

# Analyst working on finance reports
dbt run --select tag:domain:finance

# DevOps running daily batch
dbt run --select tag:frequency:daily

# Emergency fix - only high priority
dbt run --select tag:priority:high
```

## Best Practices

### 1. Consistent Naming Convention

```yaml
# Use consistent prefixes
tags:
  - 'layer:staging'      # Architecture layer
  - 'domain:customer'    # Business domain  
  - 'frequency:daily'    # Run frequency
  - 'priority:high'      # Business priority
  - 'owner:data_team'    # Responsible team
  - 'env:prod'          # Environment
  - 'sla:4hours'        # Service level agreement
```

### 2. Hierarchical Tagging

```yaml
# From general to specific
models:
  - name: customer_revenue_monthly
    tags: 
      - 'layer:mart'           # Architecture
      - 'domain:finance'       # Business area
      - 'subdomain:revenue'    # Specific area
      - 'frequency:monthly'    # Schedule
      - 'audience:executives'  # End users
```

### 3. Tag Documentation

```yaml
# Document your tagging strategy
version: 2

models:
  - name: hub_customer
    tags: ['layer:raw_vault', 'vault:hub', 'domain:customer']
    description: |
      Customer hub containing unique customer business keys.
      
      Tags explained:
      - layer:raw_vault: Part of the raw data vault layer
      - vault:hub: Data vault hub entity type  
      - domain:customer: Customer business domain
```

## Tag Combinations

### Complex Selection Examples

```bash
# Run all hubs and links but not satellites
dbt run --select tag:hub tag:link

# Run customer domain models in raw vault layer
dbt run --select tag:domain:customer,tag:layer:raw_vault

# Run daily models excluding low priority
dbt run --select tag:frequency:daily --exclude tag:priority:low

# Run staging and downstream dependencies
dbt run --select tag:layer:staging+

# Run everything upstream of marts
dbt run --select +tag:layer:mart

# Run specific domain end-to-end
dbt run --select +tag:domain:customer+
```

### Environment-Specific Runs

```bash
# Development environment - fast feedback
dbt run --select tag:ci_required tag:priority:high

# Staging environment - broader testing
dbt run --select tag:env:staging tag:env:all

# Production environment - everything
dbt run --select tag:env:prod tag:env:all

# Disaster recovery - critical only
dbt run --select tag:priority:critical
```

## Practical Implementation

### Step 1: Update Your Current Project

Add tags to your existing models:

```yaml
# models/staging/schema.yml
version: 2

models:
  - name: stg_customers
    tags: ['staging', 'customer_domain', 'daily', 'pii']
    
  - name: stg_orders  
    tags: ['staging', 'order_domain', 'daily']
```

### Step 2: Update dbt_project.yml

```yaml
models:
  demo_dbt:
    staging:
      +tags: ['layer:staging']
    raw_vault:
      +tags: ['layer:raw_vault']
      hubs:
        +tags: ['vault:hub']
      links:
        +tags: ['vault:link']  
      satellites:
        +tags: ['vault:satellite']
```

### Step 3: Test Tag Selection

```bash
# Test your tags
dbt ls --select tag:staging
dbt ls --select tag:vault:hub
dbt run --select tag:layer:staging
```

## Advanced Use Cases

### 1. Conditional Model Execution

```sql
-- Only run in production
{{ config(
    enabled=target.name == 'prod',
    tags=['env:prod_only']
) }}
```

### 2. Tag-Based Testing

```yaml
# Run tests only on tagged models
version: 2

models:
  - name: hub_customer
    tags: ['critical_path']
    tests:
      - unique:
          column_name: customer_hk
          config:
            where: "load_date >= current_date - 7"
```

### 3. Dynamic Tag Assignment

```sql
-- Assign tags based on conditions
{{ config(
    tags=['layer:mart'] + 
         (['pii'] if var('include_pii', false) else []) +
         (['critical'] if target.name == 'prod' else [])
) }}
```

Tags are one of DBT's most powerful organizational features. Use them strategically to create efficient, maintainable, and scalable data pipelines!