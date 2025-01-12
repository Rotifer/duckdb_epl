# Running totals with window functions 🦆⚽

As a season progresses, clubs accumulate points and comparisons between clubs at different points in the season are interesting. Some clubs "hit form" and surge ahead while others lose players through injury or experience "a dip in form". Running totals are needed to see how clubs positions change throughout the season. There is a general application for this approach to things like sales over time and it can be implemented in SQL using window functions which are fully supported by DuckDB. I am only going to explain one example in this post but I will return to the topic again and perhaps then write a up a more comprehensive review of the topic. Bottom line is: if you don't know and use window functions, you're missing out on one of the most powerful features of modern SQL. In the meantime, as always check out the [DuckDB documentation](https://duckdb.org/docs/sql/functions/window_functions.html) and I also strongly recommend this [excellent tutorial](https://www.cpard.xyz/posts/sql_window_functions_tutorial/).

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


Clubs play each other club twice in a season: once at home and once away. Our matches _table_ records the goals scored by the home and away club for each match in separate columns (_hcg_: home club goals, _acg_: away club goals). We need to implement logic to assign points based on the winner and collect the points for each club in each season match in one column. We can do this in three steps:

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

The points gained for each club away from home uses a very similar query but we are now selecting the away club (acc:away club code) and the order of the comparisons in the CASE statement is swapped around.

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

#### Union

In order to combine the home and away datasets returned by the two SQL statements above we can male them CTEs and then combine the two CTEs with a UNION. Here is a view definition that does just that.



### window function