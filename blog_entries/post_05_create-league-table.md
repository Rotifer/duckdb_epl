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