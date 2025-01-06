# Basic queries - Joining, grouping and counting🦆⚽

The EPL data is now ready for analysis. We will start with some simple queries to familiarise ourselves with the data. We will be working in schema _main_ where we have two tables and a one view. Tables: _matches_ and _clubs_. View: _vw_ltables_. Basic SQL knowledge is assumed here meaning that you know what SELECT, FROM, WHERE, JOIN and GROUP BY mean. I will start this and subsequent posts with a series of questions and then provide my solutions. There are often many ways to accomplish th same tasks in SQL, your solutions might very well be better than mine!

## Questions

1. How many matches were played in each season in our dataset? Order the output from earliest to latest season. Your output should contain 32 rows.

2. How many clubs have participated in each season? Order the output from earliest to latest season. Once again your output should have 32 rows.

3. Generate a list of all clubs (club names) that have played in every season in our dataset?

4. List all the clubs (club name) that have won the EPL at least once.

5. Continuing from question 4, how many times has each of those clubs clubs won the EPL and which club has won the most?

## Interesting EPL facts

1. One club was undefeated throughout an entire season. Which club achieved this feat and in which season.

2. In one season, two clubs were tied on points and the league was decided on goal difference. What season was that and what two clubs were tied on points?

3. Which club got the highest ever points total? 

4. Which club won the EPL with the lowest points total?

5. Which club ended an EPL season with the lowest total of points?

## My solutions

### Question 1

The _matches_ has the data we need and the wording of the question suggests a COUNT() of matches and a GROUP BY on season.

```sql
SELECT
  season,
  COUNT(mid) season_match_count
FROM matches
GROUP BY season
ORDER BY CAST(STRING_SPLIT(season, '_')[1] AS INTEGER);
```

The ORDER BY sorts on an the extracted four digit first year of each season. I used this trick in the previous post in creation of the view _vw_ltables_.

### Question 2

Once again the question wording suggests a COUNT() and a GROUP BY on season. The data we need can be derived from either the _matches_ table or the _vw_ltables_ view. If we use the _matches_, we need to first perform a DISTINCT on season and club code using either the hcg or acc columns. We will do the DISTINCT part in a CTE.

```sql
WITH uniq_season_club AS(
  SELECT DISTINCT
    season,
    hcc
FROM matches)
SELECT
  season,
  COUNT(hcc) season_club_count
FROM uniq_season_club
GROUP BY season
ORDER BY CAST(STRING_SPLIT(season, '_')[1] AS INTEGER);
```

### Question 3

Since we need a list of club names, this suggests we need to join to the clubs table with a COUNT() of seasons with a GROUP BY club. We know we have 32 season worth of data so we need to know how many clubs have played in each of these seasons. We can use the same CTE as in the previous solution but this time we have to switch around the COUNT and GROUP BY in the query of the CTE.

```sql
WITH uniq_season_club AS(
SELECT DISTINCT
  season,
  c.club_name
FROM matches
JOIN clubs c
    ON matches.hcc = c.club_code)
SELECT
  club_name,
  COUNT(season) season_count
FROM uniq_season_club
GROUP BY club_name
HAVING COUNT(season) = 32;
```

This generates the following output:

|     club_name     | season_count |
|-------------------|-------------:|
| Liverpool         | 32           |
| Manchester United | 32           |
| Tottenham Hotspur | 32           |
| Everton           | 32           |
| Arsenal           | 32           |
| Chelsea           | 32           |

Surprisingly only six clubs have been represented in all 32 seasons.

### Question 4

This is an easy one; we only need to query _vs_ltables_ and filter on _league_position_ equals 1. The DISTICT qualifier removes duplicates 

```sql
SELECT DISTINCT
  c.club_name 
FROM vw_ltables vlt
  JOIN clubs c ON vlt.ccode = c.club_code
WHERE league_position = 1;
```
This produces the following output:

|     club_name     |
|-------------------|
| Blackburn Rovers  |
| Arsenal           |
| Leicester City    |
| Chelsea           |
| Liverpool         |
| Manchester City   |
| Manchester United |

Only seven clubs have won the EPL over these 32 seasons.

### Question 5

Once again we are counting and grouping and we need to replace club code with club name.

```sql
SELECT
  (SELECT club_name 
   FROM clubs 
   WHERE ccode = club_code) club_name,
  COUNT(season) league_titles
FROM  vw_ltables vlt
WHERE league_position = 1
GROUP BY ccode
ORDER BY league_titles DESC;
```

Our output:

|     club_name     | league_titles |
|-------------------|--------------:|
| Manchester United | 14            |
| Manchester City   | 7             |
| Chelsea           | 5             |
| Arsenal           | 3             |
| Blackburn Rovers  | 1             |
| Liverpool         | 1             |
| Leicester City    | 1             |


We have used a SELECT subquery in the main SELECT to do the lookup of club name using club code. When used like this, the subquery can only return a single value, that it, it must be _scalar. Our ORDER BY  DESC clause highlights Manchester United as the most successful club of the EPL era with 14 titles, twice as many as their city neighbours Manchester City.

## Intersting EPL facts

1. 

```sql
SELECT
  season,
  (SELECT club_name 
   FROM clubs 
   WHERE ccode = club_code) club_name
FROM
  vw_ltables
WHERE lost = 0;
```

Yes indeed, it was Arsenal in 2003-2004, the famous _invincibles_.

2.

```sql
WITH winners AS(
SELECT
  season,
  ccode winner,
  points
FROM
  vw_ltables
WHERE league_position = 1),
runners_up AS(
SELECT
  season,
  ccode runner_up,
  points
FROM
  vw_ltables
WHERE league_position = 2)
SELECT
  winners.season,
  winner,
  runner_up
FROM winners
  JOIN runners_up 
    ON winners.points = runners_up.points
    AND winners.season = runners_up.season;
```

It was season 2011_2012 when the league was decided on the last day when Sergio Agüero scored a dramatic goal for Manchester City in injury time to seal the victory they needed to snatch the title from their Manchester United  neighbours and rivals on goal difference both clubs having finished on 89 points, an unforgettable climax to the season!

3. 

```sql
SELECT
  season,
  ccode,
  points
FROM vw_ltables
WHERE league_position = 1
  AND points = (SELECT MAX(points) FROM vw_ltables)
ORDER BY league_position  ;
```
Only one club has ever attained 100 points in a single EPL season; it was the famous Manchester City "centurians". A phenomenol feat getting 100 out of a possible 114 points in a single season.