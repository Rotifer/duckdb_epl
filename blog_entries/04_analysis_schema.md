# Chapter 4 - Creation of the analysis schema

## Clubs table

Source data prepared in Google Sheets

### Table creation and population

```sql
CREATE TABLE clubs(
  club_code VARCHAR PRIMARY KEY,
  club_name VARCHAR,
  club_given_name VARCHAR);
```

Populating the table

```sql
INSERT INTO clubs(club_code,
                  club_name, 
                  club_given_name) 
SELECT 
  club_code, 
  club_name, 
  given_name 
FROM '../source_data/clubs.tsv';
```

## Macros

```sql
CREATE SCHEMA macros;
USE macros;
CREATE MACRO get_club_code(p_club_name) AS TABLE
  SELECT club_code 
  FROM main.clubs 
  WHERE club_given_name = p_club_name
  LIMIT 1;
```

## Create the _matches_ table

We want a table that records details of matches where match_id is unique

```sql
CREATE TABLE matches(
  match_id VARCHAR PRIMARY KEY,
  season VARCHAR,
  match_date DATE,
  match_time TIME
);
```

### Make the data to append using a view

- We need the rows for _matches_ from both the 1992-1993 season and all the other seasons in one table or view that we can append to the _matches_ table created above.

```sql
CREATE OR REPLACE TABLE staging.epl_matches_1992_2024 AS
WITH matches_temp AS(
  SELECT
    '1992_1993' season,
    NULL match_date,
    NULL match_time,
    home_club_code,
    away_club_code,
    home_club_score,
    away_club_score
  FROM season_1992_1993_ready
  UNION
  SELECT
    season,
    CASE
      WHEN REGEXP_MATCHES(match_date, '\d{2}\/\d{2}\/\d{2}$') THEN
        STRPTIME(match_date, '%d/%m/%y') 
      WHEN REGEXP_MATCHES(match_date, '\d{2}\/\d{2}\/\d{4}$') THEN
        STRPTIME(match_date, '%d/%m/%Y')
    END match_date,
    CASE
      WHEN match_time = 'NA' THEN NULL
      ELSE CAST(match_time AS TIME)
    END match_time,
    (SELECT club_code 
     FROM macros.get_club_code(home_club_name)) home_club_code,
    (SELECT club_code 
     FROM macros.get_club_code(away_club_name)) away_club_code,
    home_club_goals,
    away_club_goals
  FROM seasons_1993_2023_raw
  WHERE home_club_name IS NOT NULL
)
SELECT
  *
FROM  matches_temp;
```


```sql
COPY epl_matches_1992_2024 TO '../output_data/epl_matches_1992_2024.csv' (FORMAT 'csv', DELIMITER ',', HEADER true);
```

### Fix the date fields

```sql
SELECT match_date FROM seasons_1993_2023_raw WHERE REGEXP_MATCHES(match_date, '\d{2}\/\d{2}\/\d{2}$');
```


### date issue

```sql
select strptime('14/05/00', '%d/%m/%Y');
select strptime('14/05/01', '%d/%m/%Y');
select strptime('14/05/00', '%d/%m/%y');
```

## Create the final table

```sql
CREATE SEQUENCE seq_match_id START 1;
CREATE OR REPLACE TABLE main.matches(
  mid INTEGER PRIMARY KEY DEFAULT NEXTVAL('seq_match_id'),
  season TEXT NOT NULL,
  mdate DATE,
  mtime TIME,
  hcc TEXT NOT NULL,
  acc TEXT NOT NULL,
  hcg TINYINT NOT NULL,
  acg TINYINT NOT NULL
);
```

### Move the data from the temp table

```sql
INSERT INTO matches(season,
                    mdate,
                    mtime,
                    hcc,
                    acc,
                    hcg,
                    acg)
SELECT
  season,
  match_date,
  match_time,
  home_club_code,
  away_club_code,
  home_club_score,
  away_club_score
FROM staging.epl_matches_1992_2024
ORDER BY season, match_date, match_time, home_club_code;
```

- Create the table in schema main 
- Add a match id column using a sequence
- Insert the data from the staging table in a defined order
- Export the final table t0 an output file

```sql
COPY matches TO '../output_data/matches.csv' (FORMAT 'csv', DELIMITER ',', HEADER true);
```


## Create the league tables

### Create an empty table

```sql
CREATE OR REPLACE TABLE ltables(
  season VARCHAR,
  ccode VARCHAR,
  played TINYINT,
  won TINYINT,
  drawn TINYINT,
  lost TINYINT,
  scored INT,
  conceded INT,
  goal_diff INT,
  points TINYINT
);
```


```sql
WITH mresults AS(
  SELECT
    mid,
    season,
    hcc ccode,
    hcg scored,
    acg conceded,
    CASE
      WHEN hcg = acg THEN 1
      WHEN hcg > acg THEN 3
      ELSE 0
    END points,
    CASE
      WHEN hcg > acg THEN 1
      ELSE 0
    END won,
    CASE
      WHEN hcg = acg THEN 1
      ELSE 0
    END drawn,
    CASE
      WHEN hcg < acg THEN 1
      ELSE 0
    END lost
  FROM matches
  UNION
  SELECT
    mid,
    season,
    acc,
    acg scored,
    hcg conceded,
    CASE
      WHEN acg = hcg THEN 1
      WHEN acg > hcg THEN 3
      ELSE 0
    END points,
    CASE
      WHEN acg > hcg THEN 1
      ELSE 0
    END won,
    CASE
      WHEN acg = hcg THEN 1
      ELSE 0
    END drawn,
    CASE
      WHEN acg < hcg THEN 1
      ELSE 0
    END lost
  FROM matches
),
season_summary AS(
  SELECT
    season,
    ccode,
    COUNT(mid) played,
    SUM(won) won,
    SUM(drawn) drawn,
    SUM(lost) lost,
    SUM(scored) scored,
    SUM(conceded) conceded,
    SUM(scored - conceded) goal_diff,
    SUM(points) points
  FROM mresults
  GROUP BY season, ccode
)
INSERT INTO ltables(
  season,
  ccode,
  played,
  won,
  drawn,
  lost,
  scored,
  conceded,
  goal_diff,
  points
)
SELECT
  season,
  ccode,
  played,
  won,
  drawn,
  lost,
  scored,
  conceded,
  goal_diff,
  points
FROM season_summary;
```

### Export ltables

```sql
COPY ltables TO '../output_data/ltables.csv' (FORMAT 'csv', DELIMITER ',', HEADER true);
```