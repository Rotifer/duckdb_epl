# Promotions and relegations - Sets and Joins 🦆⚽

The composition of the Premier League, like other leagues in Europe, changes from season to season as clubs are relegated from it to the second tier, called the Championship in England, and promoted into it. In England three clubs are promoted to replace the three relegated teams. Season 1994-1995 was an exception when four clubs were relegated but only two were promoted thereby reducing the size of the league from 22 to its present size of 20 clubs.

We can determine which clubs were relegated in two ways:

1. Order the positions of each club for the season we are interested in by total points, goal difference and goals scored. Since we assign position 1 to the league winner, then we need descending order and that means that clubs in positions 18, 19 and 20 will be relegated.

2. Compare the club composition for the season we are interested in with the subsequent season: any clubs that are missing in the subsequent season must have been relegated. We will look at two ways of doing this in SQL using:

    1. The EXCEPT set operator.
    2. An OUTER JOIN.

We have to use the comparison approach to identift promoted clubs because our dataset does not include The Championship league standings. If we compare the season of interest to the _previous_ season, any clubs that absent in the previous season must have been promoted. We will see this in code.

## Identifying clubs relegated by league position

If we take season 1994-1995, we can identify the relegated clubs by ordering the final league table for that season with the four bottom clubs all being relegated. Our view _vw_ltables_ already has the league positions so we can just use them to filter for the four bottom clubs

```sql
SELECT
  ccode,
  club_name,
  league_position
FROM vw_ltables v
JOIN clubs c ON v.ccode = c.club_code
WHERE season = '1994_1995'
  AND league_position > 18
ORDER BY 3;
```

Yhis gives us the following:

| ccode |   club_name    | league_position |
|-------|----------------|----------------:|
| CRY   | Crystal Palace | 19              |
| NOR   | Norwich City   | 20              |
| LEI   | Leicester City | 21              |
| IPS   | Ipswich Town   | 22              |


## Identifying clubs relegated using EXCEPT

EXCEPT is one of the three set operators supported by DuckDB; they are documented [here](https://duckdb.org/docs/sql/query_syntax/setops.html). EXCEPT returns all the rows present in the first set but absent in the second one. Oracle uses the non-standard word _MINUS_ for this operator which is more descriptive as can envisage it as _first set Minus second set. It is probably easier to understand in code. Here is the SQL:

```sql
SELECT
  ccode
FROM
  vw_ltables
WHERE season = '1994_1995'
EXCEPT
SELECT
  ccode
FROM
  vw_ltables
WHERE season = '1995_1996';
```

We get back the same four club codes:

| ccode |
|-------|
| LEI   |
| NOR   |
| IPS   |
| CRY   |

What about promoted clubs that replaced them in the following season? We can use EXCEPT again but this time we need to invert the order so that it is season 1995-1996 minus season 1994-1995:

```sql
SELECT
  ccode
FROM
  vw_ltables
WHERE season = '1995_1996'
EXCEPT
SELECT
  ccode
FROM
  vw_ltables
WHERE season = '1994_1995';
```

This gives us the two clubs who were promted to the EPL the following season.

## An outer JOIN

```sql
WITH s1 AS(
  SELECT ccode
  FROM vw_ltables
WHERE season = '1994_1995'
),
s2 AS(
  SELECT ccode
  FROM vw_ltables
  WHERE season = '1995_1996'
)
SELECT
  COALESCE(s1.ccode, 'Promoted') season1,
  COALESCE(s2.ccode, 'Relegated') season2
FROM s1
FULL OUTER JOIN s2 ON s1.ccode = s2.ccode
WHERE s1.ccode IS NULL OR s2.ccode IS NULL;
```

Output:

| season1  |  season2  |
|----------|-----------|
| CRY      | Relegated |
| NOR      | Relegated |
| LEI      | Relegated |
| IPS      | Relegated |
| Promoted | BOL       |
| Promoted | MID       |


We use two CTEs to get the club codes for the two seasons of interest and then do a [FULL OUTER JOIN](https://duckdb.org/docs/sql/query_syntax/from.html) to flag clubs in one group and missing in the other. The FULL OUTER JOIN uses NULLs for missing values. The rows with NULLs for either season are returned by the WHERE filter that checks for NULLs and returns the row if either column (OR) is null. We replace the NULLs with text flag using the [COALESCE](https://duckdb.org/docs/sql/functions/utility.html#coalesceexpr-) function.

The FULL OUTER JOIN has the advantage over the EXCEPT approach that it can identify both relegated and promoted clubs in a single query.

## Exercise

Using both the query on league position and either the EXCEPT or FULL OUTER JOIN approaches, identify the three clubs relegated in season 1996-1997. There is a discrepancy between the results returned by the league position and the EXCEPT or JOIN approaches. I first thought this was a data error but it is explained [here](https://en.wikipedia.org/wiki/1996%E2%80%9397_FA_Premier_League). I will write a note on this in the next blog.


## Wrap up

- We have used the set operator EXCEPT and the FULL OUTER JOIN to identify differences between groups, the groups being clubs in one season and the previous or subsequent one. 

Warning ⚠️: When relying on sort order in SQL, you have to make sure you get the order correct. Ask your self what is the main ordering column, what column or columns do you use to break ties and have you used ASC and DESC flags appropriately. It is very easy to get this wrong. My original view definition for _vw_ltables_ was subtly wrong. The window function ORDER BY reads:

```sql
  ROW_NUMBER()
    OVER(PARTITION BY season 
         ORDER BY  points DESC, goal_diff DESC, scored DESC) league_position
```

I originally omitted the DESC for _goal_diff_ and _scored_. doing so erroneously awarded the 2011-2012 league title to Manchester United! I have been writing SQL for long enough not to fall into this trip but I have seen this type of bug in the past in a production system so be warned!

## Next up

DuckDB supports [macros](https://duckdb.org/docs/sql/statements/create_macro.html) that allow us to write re-usable SQL and provide a uer-defined function capability akin to PostgreSQL custom functions when you set _LAANGUAGE SQL_. This can provide parameterised views which, as will see, are convenient and reduce writing of repetitive code.
