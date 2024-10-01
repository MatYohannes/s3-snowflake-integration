-- models/staging/stg_movies.sql
select
    count(*) as movie_count
from
    {{ source('movies_db', 'movies') }}

