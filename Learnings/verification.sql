desc view POC_DBT_PROJECT.UTILS.MY_second_DBT_MODEL

DESC TABLE SNOWFLAKE.TELEMETRY.EVENTS;

EXECUTE DBT PROJECT poc_sf_dbt_project;

SHOW PARAMETERS LIKE 'EVENT_TABLE' IN ACCOUNT;
ALTER ACCOUNT SET EVENT_TABLE = SNOWFLAKE.TELEMETRY.EVENTS;

SHOW DBT PROJECTS;

ALTER DBT PROJECT poc_sf_dbt_project
SET LOG_LEVEL = 'INFO';

ALTER DBT PROJECT poc_sf_dbt_project
SET TRACE_LEVEL = 'ALWAYS';

SELECT *
FROM SNOWFLAKE.TELEMETRY.EVENTS
LIMIT 10;

///////////////////

CREATE EVENT TABLE POC_DBT_PROJECT.UTILS.dbt_event_table;

ALTER DATABASE POC_DBT_PROJECT
SET EVENT_TABLE = POC_DBT_PROJECT.UTILS.dbt_event_table;

SELECT *
FROM POC_DBT_PROJECT.UTILS.dbt_event_table
LIMIT 10;

///


-- Use admin role
USE ROLE ACCOUNTADMIN;

-- Verify dbt project exists
SHOW DBT PROJECTS;

-- Go to the database where the dbt project is deployed
USE DATABASE POC_DBT_PROJECT;

-- Create event table for telemetry
CREATE OR REPLACE EVENT TABLE POC_DBT_PROJECT.UTILS.DBT_EVENTS;

-- Verify event table
SHOW EVENT TABLES;

-- Attach event table to database
ALTER DATABASE POC_DBT_PROJECT SET EVENT_TABLE = POC_DBT_PROJECT.UTILS.DBT_EVENTS;

-- Verify the parameter is set
SHOW PARAMETERS LIKE 'EVENT_TABLE' IN DATABASE POC_DBT_PROJECT;

-- Enable detailed logging on dbt project
ALTER DBT PROJECT POC_DBT_PROJECT.UTILS.poc_sf_dbt_project SET LOG_LEVEL = 'DEBUG';

-- Enable tracing
ALTER DBT PROJECT poc_sf_dbt_project SET TRACE_LEVEL = 'ALWAYS';

-- Run the dbt project
EXECUTE DBT PROJECT poc_sf_dbt_project;

-- Wait a few seconds, then query telemetry logs
SELECT
    TIMESTAMP,
    RECORD_TYPE,
    RESOURCE_ATTRIBUTES,
    VALUE
FROM DBT_EVENTS
ORDER BY TIMESTAMP DESC
LIMIT 20;

/// 

ALTER SCHEMA poc_dbt_project.utils SET LOG_LEVEL = 'INFO';
ALTER SCHEMA poc_dbt_project.utils SET TRACE_LEVEL = 'ALWAYS';
ALTER SCHEMA poc_dbt_project.utils SET METRIC_LEVEL = 'ALL';

ALTER SCHEMA tasty_bytes_dbt_db.prod SET LOG_LEVEL = 'INFO';
ALTER SCHEMA tasty_bytes_dbt_db.prod SET TRACE_LEVEL = 'ALWAYS';
ALTER SCHEMA tasty_bytes_dbt_db.prod SET METRIC_LEVEL = 'ALL';

show tables in schema poc_dbt_project.utils

SELECT table_name
FROM poc_dbt_project.information_schema.tables
WHERE table_schema = '';


create schema POC_DBT_PROJECT.UTILS_STAGING

select * from DBT_PROJECT_EXECUTION_HISTORY

DESCRIBE DBT PROJECT poc_sf_dbt_project;

--- versions

SHOW VERSIONS IN DBT PROJECT POC_SF_DBT_PROJECT;

-- run specific version
EXECUTE DBT PROJECT POC_SF_DBT_PROJECT
ARGS='run'
VERSION='VERSION$1';

---- from git repo directly without using workspace
CREATE OR REPLACE GIT REPOSITORY my_git_repo
API_INTEGRATION = my_git_integration
ORIGIN = 'https://github.com/<org>/<repo>.git';
