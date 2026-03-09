-- first we need to create a service user follow below steps:

-- STEP 1 : CREATE SERVICE USER
CREATE or replace USER github_actions_service_user
  TYPE = SERVICE
  WORKLOAD_IDENTITY = (
    TYPE = OIDC
    ISSUER = 'https://token.actions.githubusercontent.com',
    SUBJECT = 'repo:Ashraf2004/demo_dbt:environment:prod'
  )
  DEFAULT_ROLE = SYSADMIN
  COMMENT = 'Service user for GitHub Actions';

-- STEP 2 : GRANT ROLE TO USER
CREATE ROLE DBT_CICD_ROLE;

GRANT ROLE DBT_CICD_ROLE TO USER github_actions_service_user;

GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE DBT_CICD_ROLE;

GRANT USAGE ON DATABASE POC_DBT_PROJECT TO ROLE DBT_CICD_ROLE;

GRANT USAGE ON SCHEMA POC_DBT_PROJECT.UTILS TO ROLE DBT_CICD_ROLE;

GRANT CREATE TABLE, CREATE VIEW ON SCHEMA POC_DBT_PROJECT.UTILS TO ROLE DBT_CICD_ROLE;

GRANT ALL PRIVILEGES ON SCHEMA POC_DBT_PROJECT.UTILS TO ROLE DBT_CICD_ROLE;

-- STEP 3 : SET DEFAULT WAREHOUSE

ALTER USER github_actions_service_user SET DEFAULT_WAREHOUSE = 'COMPUTE_WH';

-- STEP 4 : SET NETWORK RULES

IF YOU GET "Incoming request with IP/Token <IP> is not allowed to access Snowflake." THEN WE NEED TO SET RULE OR ELSE SKIP

-- STEP 5 : 

-- Alternative: PAT-based authentication (less secure)