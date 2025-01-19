# Comparing clubs across seasons🦆⚽

<div style="background-color:#E5E4D7">

<strong>Note for following along</strong>

- check out the [GitHub repo](https://github.com/Rotifer/duckdb_epl).
- See the data in Google sheets format [here](https://docs.google.com/spreadsheets/d/15EpbhgQibpv2haCeWsM77uApxgS5zYfq/edit?gid=1237416221#gid=1237416221).

</div>

Here we look at ways to compare clubs' performances across seasons using a variety of SQL techniques and we once again explot DuckDB's macro implementation.

## Basic statistics for clubs and seasons

We have all the tables and views we need to perform some comparisons between clubs over the seasons. 

We will start answering these questions:

- Which 10 clubs have collected the most points over all seasons?
- Which 10 clubs have collected the highest average points per game over all seasons that they have played in the EPL?
- Which season produced the highest/lowest goals total?


Answering these types of questions will develop our analytical skills using SQL. The view _vw_ltables_ contains all the data we need to answer these questions. Try answering them yourself and consult the solutions if needed. None of the SQL for this blog post is diffiecult.

### Which club has collected the most points over all seasons?

```sql
SELECT
  ccode,
  SUM(points) points_total
FROM vw_ltables
GROUP BY ccode
ORDER BY points_total DESC
LIMIT 10;
```

This produces the following 10 rows:

| ccode | points_total |
|-------|--------------|
| MUN   | 2518         |
| ARS   | 2329         |
| LIV   | 2233         |
| CHE   | 2215         |
| TOT   | 1902         |
| MCI   | 1805         |
| EVE   | 1655         |
| NEW   | 1563         |
| AVL   | 1503         |
| WHU   | 1334         |

Join to clubs and use the club name if you prefer this to the club code. The query output is not surprising because 6 of those clubs have been in the EPL for all seasons in our dataset and Manchester United have won the most league titles so it is hardly surprising that they have earned the most points over all the seasons. You might expect Manchester City (MCI) to be higher, but they have not played in all EPL season. Let's see how they fare when we calculate average points per game played in the next solution.

### Which club has collected the highest average points per game over all seasons that it has played in the EPL?

We suspect that because Manchester City have played in fewer EPL seasons that the other top 10 that we are underestimating their record. 
If we correct for the number of games played then perhaps we will see a different outcome.


```sql
SELECT
  ccode,
  ROUND(SUM(points)/SUM(played), 2) points_per_game
FROM vw_ltables
GROUP BY ccode
ORDER BY points_per_game DESC
LIMIT 10;
```

And we get:

| ccode | points_per_game |
|-------|----------------:|
| MUN   | 2.05            |
| ARS   | 1.9             |
| LIV   | 1.82            |
| CHE   | 1.8             |
| MCI   | 1.74            |
| TOT   | 1.55            |
| NEW   | 1.41            |
| LEE   | 1.4             |
| BLB   | 1.39            |
| BRE   | 1.38            |

Actually, not much change!

### Which five seasons produced the highest/lowest goals total?

```sql
SELECT
  season,
  SUM(scored) season_total_goals
FROM  vw_ltables
GROUP BY season
ORDER BY season_total_goals DESC
LIMIT 5;
```

|  season   | season_total_goals |
|-----------|--------------------|
| 2023_2024 | 1246               |
| 1992_1993 | 1222               |
| 1994_1995 | 1195               |
| 1993_1994 | 1195               |
| 2021_2022 | 1084               |

A point worth noting here is that in those seasons from the early to mid 1990s, 460 games were played per season rather than the 380
that are played now. This is undoubtedly skewing our results. You need to know your data well when making such comparisons.

To find the five seasons producing the fewest goals we just need to switch the ORDER BY from DESC to ASC (the default). 


```sql
SELECT
  season,
  SUM(scored) season_total_goals
FROM  vw_ltables
GROUP BY season
ORDER BY season_total_goals
LIMIT 5;
```

Here is the output:

|  season   | season_total_goals |
|-----------|--------------------|
| 2006_2007 | 931                |
| 2008_2009 | 942                |
| 2005_2006 | 944                |
| 1998_1999 | 959                |
| 1996_1997 | 970                |

## Comparing clubs across season

We would like to generate a table of a club's EPL position at the end of each season. To do this we will write the following macro:

```sql
CREATE OR REPLACE MACRO macros.club_league_positions(p_club) AS TABLE
SELECT
  season,
  league_position
FROM main.vw_ltables
WHERE ccode = p_club
ORDER BY league_position;
```

Here is an example of how we can call our macro to get Tottenham Hotspur's final league positions for each season:

```sql
SELECT * 
FROM macros.league_positions_club('TOT');
```

As in every league, there are hotly contested local rivalries in the EPL. One suck rivalry is that between North London neighbours Arsenal and Tottenham so let's generate a table comparing the two clubs's finishing positions over the seasons. 

__Note__ how we sort by season ascending by extracting the first year of the season and converting it to an integer

```sql
SELECT 
  ars.season,
  ars.league_position ars_pos,
  tot.league_position tot_pos
FROM macros.league_positions_club('ARS') ars
JOIN (SELECT * FROM macros.league_positions_club('TOT')) tot
  ON ars.season = tot.season
ORDER BY CAST(SUBSTR(ars.season, 1, 4) AS INTEGER);
```

Here is the output for the first 10 seasons

|  season   | ars_pos | tot_pos |
|-----------|--------:|--------:|
| 1992_1993 | 10      | 8       |
| 1993_1994 | 4       | 15      |
| 1994_1995 | 12      | 7       |
| 1995_1996 | 4       | 8       |
| 1996_1997 | 3       | 10      |
| 1997_1998 | 1       | 15      |
| 1998_1999 | 2       | 11      |
| 1999_2000 | 2       | 10      |
| 2000_2001 | 2       | 12      |
| 2001_2002 | 1       | 9       |
