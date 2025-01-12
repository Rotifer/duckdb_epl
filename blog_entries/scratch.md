```sql
CREATE OR REPLACE VIEW vw_cum_points AS
WITH home AS(
SELECT
  season,
  mid,
  mdate,
  hcc ccode,
  CASE
    WHEN hcg > acg THEN 3
	WHEN hcg = acg THEN 1
	ELSE 0
  END points
FROM
  matches
WHERE mdate IS NOT NULL),
away AS(
SELECT
  season,
  mid,
  mdate,
  acc ccode,
  CASE
    WHEN acg > hcg THEN 3
	WHEN acg = hcg THEN 1
	ELSE 0
  END points
FROM
  matches
WHERE mdate IS NOT NULL),
home_and_away AS(
SELECT *
FROM home
UNION ALL
SELECT *
FROM away)
SELECT
  season,
  ccode,
  mdate,
  SUM(points) OVER(PARTITION BY season, ccode 
                   ORDER BY mdate) cum_points
FROM home_and_away
ORDER BY season, ccode, mdate;

COPY vw_cum_points TO cum_points.csv (HEADER, DELIMITER ',');

CREATE SCHEMA macros;

USE macros;

CREATE MACRO get_club_season_cum_points(p_season, p_ccode) AS TABLE
  SELECT * 
  FROM main.vw_cum_points 
  WHERE season = p_season
  AND ccode = p_ccode
  ORDER BY mdate;
  
  
COPY (SELECT * FROM macros.get_club_season_cum_points('2011_2012', 'MUN')) TO 'mun_2011_2012.csv' (HEADER, DELIMITER ',');
COPY (SELECT * FROM macros.get_club_season_cum_points('2011_2012', 'MCI')) TO 'mci_2011_2012.csv' (HEADER, DELIMITER ',');
```
