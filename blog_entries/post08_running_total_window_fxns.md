# Running totals with window functions 🦆⚽

As a season progresses, clubs accumulate points and comparisons between clubs at different points in the season are interesting. Some clubs "hit form" and surge ahead while others lose players through injury or experience "a dip in form" that is reflected in a reduced rate of points accumulation. Running totals are needed to see how clubs' positions change throughout the season. 

There is a general application for this approach to things like sales over time and it can be implemented in SQL using __window functions__ which are fully supported by DuckDB. I am only going to explain one example in this post but I will return to the topic again and perhaps then write a up a more comprehensive review of the topic. Bottom line is: if you don't know and use window functions, you're missing out on one of the most powerful features of modern SQL. 

In the meantime, as always check out the [DuckDB documentation](https://duckdb.org/docs/sql/functions/window_functions.html) and I also strongly recommend this [excellent tutorial](https://www.cpard.xyz/posts/sql_window_functions_tutorial/).

## Running totals

We are going to create a view that orders all the data from _matches_ table by season, club and match date and adds a column that displays the club's accrued points at that point in the season. The final view definition SQL will be quite long but it can be decomposed into manageable segments that we can run and test independently so we will build it up in steps and explain the steps as we go along.

### Calculating points earned home and away

As a reminder of our matches table columns and data, here is a sample of 10 rows:

| mid  |  season   |   mdate    | mtime | hcc | acc | hcg | acg |
|-----:|-----------|------------|-------|-----|-----|----:|----:|
| 4559 | 1993_1994 | 1993-08-14 |       | ARS | COV | 0   | 3   |
| 4560 | 1993_1994 | 1993-08-14 |       | AVL | QPR | 4   | 1   |
| 4561 | 1993_1994 | 1993-08-14 |       | CHE | BLB | 1   | 2   |
| 4562 | 1993_1994 | 1993-08-14 |       | LIV | SHW | 2   | 0   |
| 4563 | 1993_1994 | 1993-08-14 |       | MCI | LEE | 1   | 1   |
| 4564 | 1993_1994 | 1993-08-14 |       | NEW | TOT | 0   | 1   |
| 4565 | 1993_1994 | 1993-08-14 |       | OLD | IPS | 0   | 3   |
| 4566 | 1993_1994 | 1993-08-14 |       | SHU | SWI | 3   | 1   |
| 4567 | 1993_1994 | 1993-08-14 |       | SOU | EVE | 0   | 2   |
| 4568 | 1993_1994 | 1993-08-14 |       | WHU | WIM | 0   | 2   |


Clubs play each other club twice in a season: once at home and once away. Our _matches_ table records the goals scored by the home and away club for each match in separate columns (_hcg_: home club goals, _acg_: away club goals). We need to implement logic to assign points based on the winner and collect the points for each club in each match of each season in one column. We can do this in three steps:

1. Calculate the points earned for each club for each match in a season at home (first CTE).
2. Calculate the points earned for each club for each match in a season away from home (second CTE).
3. Bring the home and away results together using a UNION.

#### Home

The following SQL calculates the points each club gained when playing at home (hcc: home club code) for each match of each season using a CASE statement (3 points for a win, one for a draw, 0 for a loss).
We need the match date later to calculate the running totals but this value is not available for season 1992_1993 so we filter it out in the WHERE clause.

```sql
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
WHERE mdate IS NOT NULL;
```

|  season   | mid  |   mdate    | ccode | points |
|-----------|-----:|------------|-------|-------:|
| 1993_1994 | 4559 | 1993-08-14 | ARS   | 0      |
| 1993_1994 | 4560 | 1993-08-14 | AVL   | 3      |
| 1993_1994 | 4561 | 1993-08-14 | CHE   | 0      |
| 1993_1994 | 4562 | 1993-08-14 | LIV   | 3      |
| 1993_1994 | 4563 | 1993-08-14 | MCI   | 1      |
| 1993_1994 | 4564 | 1993-08-14 | NEW   | 0      |
| 1993_1994 | 4565 | 1993-08-14 | OLD   | 0      |
| 1993_1994 | 4566 | 1993-08-14 | SHU   | 3      |
| 1993_1994 | 4567 | 1993-08-14 | SOU   | 0      |
| 1993_1994 | 4568 | 1993-08-14 | WHU   | 0      |


#### Away

The points gained for each club away from home uses a very similar query but we are now selecting the away club (acc: away club code) and the order of the comparisons in the CASE statement is swapped around.

```sql
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
WHERE mdate IS NOT NULL;
```

#### UNION

In order to combine the home and away datasets returned by the two SQL statements above we can make them CTEs and then combine the two CTEs with a UNION. 

### The window function

We can now add the window function to query our two UNIONed CTEs like so:

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
UNION
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
```

The window function totals all the points (`SUM(points)`) for each season and club (`PARTITION BY season, ccode`) with the results ordered by the match date (`ORDER BY mdate`).

Let's query the view we just created for Manchester City, season 2017-2018:

```sql
SELECT *
FROM vw_cum_points
WHERE ccode = 'MCI'
AND season = '2017_2018';
```

The output shows us how they accumulated their very impressive 100 points in that season

|  season   | ccode |   mdate    | cum_points |
|-----------|-------|------------|------------|
| 2017_2018 | MCI   | 2017-08-12 | 3          |
| 2017_2018 | MCI   | 2017-08-21 | 4          |
| 2017_2018 | MCI   | 2017-08-26 | 7          |
| 2017_2018 | MCI   | 2017-09-09 | 10         |
| 2017_2018 | MCI   | 2017-09-16 | 13         |
| 2017_2018 | MCI   | 2017-09-23 | 16         |
| 2017_2018 | MCI   | 2017-09-30 | 19         |
| 2017_2018 | MCI   | 2017-10-14 | 22         |
| 2017_2018 | MCI   | 2017-10-21 | 25         |
| 2017_2018 | MCI   | 2017-10-28 | 28         |
| 2017_2018 | MCI   | 2017-11-05 | 31         |
| 2017_2018 | MCI   | 2017-11-18 | 34         |
| 2017_2018 | MCI   | 2017-11-26 | 37         |
| 2017_2018 | MCI   | 2017-11-29 | 40         |
| 2017_2018 | MCI   | 2017-12-03 | 43         |
| 2017_2018 | MCI   | 2017-12-10 | 46         |
| 2017_2018 | MCI   | 2017-12-13 | 49         |
| 2017_2018 | MCI   | 2017-12-16 | 52         |
| 2017_2018 | MCI   | 2017-12-23 | 55         |
| 2017_2018 | MCI   | 2017-12-27 | 58         |
| 2017_2018 | MCI   | 2017-12-31 | 59         |
| 2017_2018 | MCI   | 2018-01-02 | 62         |
| 2017_2018 | MCI   | 2018-01-14 | 62         |
| 2017_2018 | MCI   | 2018-01-20 | 65         |
| 2017_2018 | MCI   | 2018-01-31 | 68         |
| 2017_2018 | MCI   | 2018-02-03 | 69         |
| 2017_2018 | MCI   | 2018-02-10 | 72         |
| 2017_2018 | MCI   | 2018-03-01 | 75         |
| 2017_2018 | MCI   | 2018-03-04 | 78         |
| 2017_2018 | MCI   | 2018-03-12 | 81         |
| 2017_2018 | MCI   | 2018-03-31 | 84         |
| 2017_2018 | MCI   | 2018-04-07 | 84         |
| 2017_2018 | MCI   | 2018-04-14 | 87         |
| 2017_2018 | MCI   | 2018-04-22 | 90         |
| 2017_2018 | MCI   | 2018-04-29 | 93         |
| 2017_2018 | MCI   | 2018-05-06 | 94         |
| 2017_2018 | MCI   | 2018-05-09 | 97         |
| 2017_2018 | MCI   | 2018-05-13 | 100        |


## A macro to query the view

In the last post I described how macros can simplfy our lives by allowing us to write re-usable code. Generating the running total of points for a given club in a particular season is an ideal candidate for a macro that takes two parameters: the season and the club. Let's create a macro to do just this in the _macros_ schema from the last post:

```sql
USE macros;
CREATE MACRO get_club_season_cum_points(p_season, p_ccode) AS TABLE
  SELECT * 
  FROM main.vw_cum_points 
  WHERE season = p_season
  AND ccode = p_ccode
  ORDER BY mdate;
```

We can test our macro as follows:

```sql
SELECT * 
FROM macros.get_club_season_cum_points('2003_2004', 'ARS');
```

Another cool feature of DuckDB which we haven't covered yet is how easy it is to generate files from our query output using the `COPY` command. For example, if we want to send the output from the previous query to a CSV file with column headers we can do it as follows using the `COPY` command

```sql
COPY (SELECT * FROM macros.get_club_season_cum_points('2003_2004', 'ARS')) 
TO 'ars_2003_2004.csv' (HEADER, DELIMITER ',');
```

We could then use the output for generating plots, for example. 

## Wrap up

- We have only touched on window functions, there's lots more to learn and we will re-visit them as and when the need arises.

- We have also seen another example of how useful macros are.

- We used to `COPY` command to create a file from the output of our macro.