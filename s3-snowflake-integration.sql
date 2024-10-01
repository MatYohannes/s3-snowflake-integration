CREATE DATABASE MOVIES;
CREATE SCHEMA MOVIES_SCHEMA;

CREATE OR REPLACE STORAGE INTEGRATION aws_s3_integration
type=external_stage
storage_provider='S3'
enabled=true
storage_aws_role_arn='arn:aws:iam::<AWS Account Number>:role/SnowflakeAccessRole' // Get from IAM role created
storage_allowed_locations=('s3://movies-myy-093024/') // Get from s3 bucket
;

SHOW INTEGRATIONS;

DESC INTEGRATION aws_s3_integration;

GRANT usage on integration aws_s3_integration to role accountadmin;

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

CREATE OR REPLACE TEMPORARY TABLE s3_snowflake_info (
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
SELECT count(*) FROM s3_snowflake_info;

COPY INTO s3_snowflake_info
FROM @s3_snowflake_stage/Movies.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"')
ON_ERROR = 'CONTINUE';


