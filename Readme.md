1. Create venv and activate
```shell
python3 -m venv snow-s3
source snow-s3/bin/activate
```
2. Install kaggle. Note (create kaggle api token and copy to ~/.kaggle)
```shell
pip install kaggle
```
3. Run deploy file
```shell
./deploy <AWS Account Name>
```
4. Run kaggleupload
```shell
./kaggleupload
```
5. Copy uploaded S3 URL eg. s3://movies-myy-093024/Movies.csv
6. Go to role and update role "SnowflakeAccessRole" Trust relationship with content in 
role.json. Copy and paste.
7. Create a Snowflake sql worksheet
```snowflake sql
// switches active role to 'accountadmin' for full privileges
use role accountadmin;

// create virtual warehouse 
create warehouse movies_wh 
with warehouse_size='x-small'
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE;

// create database to store tables, schemas, and objects
create database if not exists movies_db;
// roles are used to assign and manage permissions
create role if not exists movies_role;
// ctrl + enter to run

// display existing grants(permissions)
show grants on warehouse movies_wh;

// allows dbt_role to use dbt_wh for querying
grant usage on warehouse movies_wh to role movies_role;


grant role accountadmin to role movies_role;

grant role movies_role to user matyohannes;
// grant all privileges(read, write, etc.)
grant all on database movies_db to role movies_role;
// switches active role to dbt_role, so next actions will be executed under this role's permissions
use role movies_role;

SHOW GRANTS TO USER matyohannes;

// creates new schema in movies_db.
create schema if not exists movies_db.movies_schema;
grant usage on schema movies_db.movies_schema to role movies_role;

// Switch back to accountadmin to run integration
use role accountadmin;

// Need to have accountadmin to create integration
CREATE OR REPLACE STORAGE INTEGRATION aws_s3_integration
type=external_stage
storage_provider='S3'
enabled=true
storage_aws_role_arn='arn:aws:iam::<AWS Account Number>:role/SnowflakeAccessRole' // Get from IAM role created
storage_allowed_locations=('s3://movies-myy-093024/') // Get from s3 bucket
;

SHOW INTEGRATIONS;

// Below will display the iam_user_arn and external_id for AWS role
DESC INTEGRATION aws_s3_integration;

GRANT usage on integration aws_s3_integration to role movies_role;

use role movies_role;

CREATE OR REPLACE file format s3_snowflake_format
type='CSV'
field_delimiter=','
skip_header=1;

CREATE OR REPLACE stage s3_snowflake_stage
storage_integration=aws_s3_integration
file_format='s3_snowflake_format'
url='s3://movies-myy-093024/'

// Checking the stage
List @s3_snowflake_stage;

CREATE OR REPLACE TABLE movies_db.movies_schema.movies(
  movie_id STRING,
  title STRING,
  vote_average NUMBER(5, 3),
  vote_count INTEGER,
  status STRING,
  release_date DATE,  
  revenue INTEGER,
  adult BOOLEAN,
  budget INTEGER,
  imdb_id STRING,
  original_language STRING,
  original_title STRING,
  overview STRING,
  popularity FLOAT,
  genres STRING,
  production_companies STRING,
  production_countries STRING,
  spoken_languages STRING
);


// Check the table
SELECT * FROM movies_db.movies_schema.movies limit 10;

COPY INTO movies_db.movies_schema.movies
FROM @s3_snowflake_stage/Movies.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"')
ON_ERROR = 'CONTINUE';


SHOW TABLES IN SCHEMA movies_db.movies_schema;

-- use database movies_db;
-- use schema movies_schema;
-- show tables;
SHOW GRANTS TO ROLE movies_role;

GRANT SELECT ON TABLE movies_db.movies_schema.movies TO ROLE movies_role;


// Clean up
DROP TABLE IF EXISTS movies_db.movies_schema.movies;
DROP STAGE IF EXISTS s3_snowflake_stage;
DROP FILE FORMAT IF EXISTS s3_snowflake_format;
DROP STORAGE INTEGRATION IF EXISTS aws_s3_integration;
DROP SCHEMA IF EXISTS movies_db.movies_schema CASCADE;
DROP DATABASE IF EXISTS movies_db CASCADE;
DROP role movies_role;
drop warehouse movies_wh;

```
After creating integration, use following command to get STORAGE_AWS_IAM_USER_ARN and
STORAGE_AWS_EXTERNAL_ID
```snowflake sql
DESC INTEGRATION aws_s3_integration;
```
8. Install dbt
```shell
pip install dbt dbt-snowflake
```
9. Initialize dbt
```shell
dbt  init snow_integration
cd snow_integration
```
10. Update dbt_project.yml
11. Create folder staging under models
12. Create sources.yml 
13. Create stg_movies.sql
14. Use the following commands
```shell
dbt debug
dbt run
dbt test
```
