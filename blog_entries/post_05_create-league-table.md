## Final club positions for each season 🦆⚽

Our _matches_ table records all the data we need to contruct the final league positions for each season. However, we need to perform a series of aggregations and calculations to produce these league position tables. Since, the league positions are calculated from the _matches_ table only, I am going to store them in a __view__ based on that table. A view is a stored query so each time we use the view, it is re-calculated. This has a minimal cost in our example because the dataset is very small and DuckDB is highly performant. It also has the advantage that if we add matches for another season, say 2024-2025, the data will automatically picked up by the view. 

Here is the view definition, all 70 lines of it! 😨 It might look scary but it is actually not difficult once we break it down into its constituent parts. When building big SQL statements like this one, I build it up iteratively and check the outputs as I go along. Hopefully, the notes below will clarify my approach.


## View definition

Here is the full SQL definition of the view:

```tsql
USE main;
CREATE OR REPLACE VIEW vw_ltables AS
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
    SUM(points) points,
  FROM mresults
  GROUP BY season, ccode
)
SELECT *, 
  ROW_NUMBER()
    OVER(PARTITION BY season 
         ORDER BY  points DESC, goal_diff DESC, scored DESC) league_position
FROM
  season_summary
ORDER BY 
  CAST(STRING_SPLIT(season, '_')[1] AS INTEGER) DESC;
```
As with tables, we can add descriptive comments to views also.

```
COMMENT ON VIEW vw_ltables IS 'The final league table positions for each season in order of league winner to bottom club.';
```

## Code notes

### Overview

The view definition SQL statement is composed of two [common table expressions](https://duckdb.org/docs/sql/query_syntax/with.html) (CTE) and a final SELECT statement that extracts the data from the second CTE, assigns league positions and orders the output.

CTEs are a powerful mechanism for structuring complex SQL statements. They create a temporary table for the query and allow us to encapsulate units of logic within them. The CTEs can be "chained" like with the two CTEs here where the second CTE pulls data from the first one. 

### First CTE

The first CTE, named _mresults__ (match results) performs a __UNION__ operation that appends the away match results to the home match results. _UNION_ is one of the three standard SQL __set operators__ supported by DuckDB, we will meet the others later. We need to perform this UNION because in our _matches_ table home and away match results are recorded in separate columns so if we wish to perform calculations for all matches - home and away -, we need them in the same columns. Let's look at the first SQL statement of the UNION query in detail:

```tsql
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
FROM matches;
```

Execute this query and you will return 12406 rows, that is one for each match where the _ccode_ column value is the three-letter club code for the home club in that match. It has four CASE conditional statements in its SELECT clause which perform calcuations.

1. Create a _points_  column and assign points to the home club: 3 if it won, one if it drew, 0 if it lost.
2. Create a _won_ column and assign the home club 1 if it won, otherwise assign 0.
3. Create a _drawn_ column and assign the home club 1 if the match was drawn, otherwise assign 0.
4. Create a _lost_ column and assign the home club 1 if it lost, otherwise assign 0.

The same logic is repeated in the second SELECT of the UNION but this time for the match away club. The output of the UNION is 2x12406 rows, that is two rows for each match, one row for the home club and one row for the away club.

We now have all the numbers we need to calculculate the final league tables in the second CTE.

### Second CTE

The second CTE, named _season_summary_, performs the aggregations on the rows created by the first CTE by counting the number of matches, summing the column calculations in the first CTE and then grouping on _season_ and _ccode_ (club code). Since this CTE depends on the first one, you cannot execute it as a standalone statement. If you wish to do this, turn the first CTE into a view or table and then execute the second CTE against that.

### Final SELECT

The final SELECT statement pulls the data from the second CTE and performs the ordering to generate the final league tables ordered by season and the descending number of points achieved by each club in that season. 

- The [__window function__](https://duckdb.org/docs/sql/functions/window_functions.html) _ROW_NUMBER()_ assigns league finish positions to each club by season ordered by total points, goal difference and goals scored. The two additional ordering columns break ties when the points tally for clubs in a season is the same.

- The final ORDER BY clause isn't really necessary but it ensures the view displays the most recent seasons first. Note how the season start year is extracted and cast to an integer to ensure numeric rather than text sorting order.

## Wrapping up

🎈 We now have our final set of tables and views to work with. To recap, we have two tables: _clubs_ and _matches_ and the one view we created here _vw_ltables_. 🎈

## Next up

We will start answering some questions about our data. For example, which club has won the most premier leagues? which club 
attained the most/fewest points in a season? etc. I will try to come up with some interesting questions that also stretch our SQL knowledge and deepen our understanding of SQL.