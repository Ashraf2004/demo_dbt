CREATE SCHEMA IF NOT EXISTS POC_DBT_PROJECT.RAW_VAULT;

-- Use the database
USE DATABASE POC_DBT_PROJECT;
USE SCHEMA UTILS;

-- Create raw_customers table
CREATE TABLE IF NOT EXISTS raw_customers (
    customer_id NUMBER,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(200),
    phone VARCHAR(50)
);

-- Create raw_orders table  
CREATE TABLE IF NOT EXISTS raw_orders (
    order_id NUMBER,
    customer_id NUMBER,
    order_date DATE,
    total_amount NUMBER(10,2),
    status VARCHAR(50)
);


-- Insert sample customers
INSERT INTO raw_customers VALUES
(1, 'John', 'Doe', 'john.doe@email.com', '555-0101'),
(2, 'Jane', 'Smith', 'jane.smith@email.com', '555-0102'),
(3, 'Bob', 'Johnson', 'bob.johnson@email.com', '555-0103');

-- Insert sample orders
INSERT INTO raw_orders VALUES
(101, 1, '2024-01-15', 150.00, 'completed'),
(102, 2, '2024-01-16', 75.50, 'pending'),
(103, 1, '2024-01-17', 200.00, 'completed'),
(104, 3, '2024-01-18', 99.99, 'shipped');


------------------------------------------------------

-- stage tables creation
SELECT * FROM POC_DBT_PROJECT.UTILS_STAGING.STG_CUSTOMERS;
SELECT * FROM POC_DBT_PROJECT.UTILS_STAGING.STG_ORDERS;
-- note : we can add freshness to source table so we can check how data is getting from pipeline

-- hub creation
SELECT * FROM POC_DBT_PROJECT.UTILS_RAW_VAULT.HUB_CUSTOMER;

-- satilate creation

select * from POC_DBT_PROJECT.UTILS_RAW_VAULT.SAT_CUSTOMER

SELECT * FROM POC_DBT_PROJECT.RAW_VAULT.RAW_CUSTOMERS;
UPDATE POC_DBT_PROJECT.RAW_VAULT.RAW_CUSTOMERS SET EMAIL = 'john.shaik@email.com' where EMAIL = 'john.doe@email.com'

---------------------------------------------------------

-- manifest_file.json --> after executing the dbt project

SELECT SYSTEM$LOCATE_DBT_ARTIFACTS('01c2f8c8-0001-a8c7-000c-9f8600057ffa');

LIST 'snow://dbt/POC_DBT_PROJECT.UTILS.MY_TESTER_DBT_PROJECT_OBJECT_GH_ACTION/results/query_id_01c2f8c8-0001-a8c7-000c-9f8600057ffa/';

CREATE OR REPLACE STAGE POC_DBT_PROJECT.UTILS.dbt_artifacts_stage;

COPY FILES
    INTO @POC_DBT_PROJECT.UTILS.dbt_artifacts_stage/
    FROM 'snow://dbt/POC_DBT_PROJECT.UTILS.MY_TESTER_DBT_PROJECT_OBJECT_GH_ACTION/results/query_id_01c2f8c8-0001-a8c7-000c-9f8600057ffa/target/'
    FILES = ('manifest.json');

CREATE OR REPLACE FILE FORMAT json_format
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = FALSE;

SELECT
    *
FROM @POC_DBT_PROJECT.UTILS.dbt_artifacts_stage/manifest.json
    (FILE_FORMAT => POC_DBT_PROJECT.UTILS.json_format);

    

------

-- Reads manifest.json DIRECTLY from snow:// path, no stage needed
SELECT SYSTEM$GET_DBT_ARTIFACT(
    'POC_DBT_PROJECT.UTILS.MY_TESTER_DBT_PROJECT_OBJECT_GH_ACTION',
    'manifest.json'
);