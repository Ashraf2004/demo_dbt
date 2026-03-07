Serverless tasks can’t be used to run dbt projects. When you create a task that executes the EXECUTE DBT PROJECT command, you must specify a user-managed warehouse.
A dbt project in a workspace can’t have more than 20,000 files ( make sure to check and clear log files)

------ logging
>> You see logs only after the command finishes. live stream is not available as dbt core
>> you can create an event table to collect telemetry data and associate it with the database where the dbt project object is deployed. NOTE : MAKE SURE TO ALTER SCHMA AS BELOW
ALTER SCHEMA poc_dbt_project.utils SET LOG_LEVEL = 'INFO';
ALTER SCHEMA poc_dbt_project.utils SET TRACE_LEVEL = 'ALWAYS';
ALTER SCHEMA poc_dbt_project.utils SET METRIC_LEVEL = 'ALL';

------- flags not supported
--state
--target-path
--log-path
--profiles-dir
--project-dir
--log-format
--log-format-file