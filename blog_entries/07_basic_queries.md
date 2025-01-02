# Chapter 7 - Basic queries

Now that we have our tables ready, we can begin asking questions of our data. To recap: we have three tables:

1. _clubs_: A lookup table matching the three letter club codes to the full clab names and the club names used in our main source data files.
2. _matches_: Records basic information on each match: the two clubs involved, the date and time if available, and the number of goals scored by each club in the match.
3. _ltables_: The final league table for each season recording the total points accrued by each club over the course of the season, the number of goals scored and conceded and the number of games won drawn and lost.

All three tables are in schema _main_ and we will not be using any tables in schema _staging_ from now on. Since _main_ is the default schema when you open a DuckDB database, you should not need to issue the _USE main;_ command unless you switch to another schema at some point.

## Checking our data

We are assuming that our tables contain correct and complete data accepting that we are missing match date and time values for our first season, 1992_1993 and only have match start times for later seasons. To repeat what I said in the introduction: one of the advantages of a dataset such as this one is that we can easliy check our data and query results against reliable sources. Basically, we know what the results of queries shoul be so if our answers differ then we can determine easliy if the error is due to bad data and faulty query logic.


## Questions

How many matches _do not_ have a match date, _mdate_, value?

How many many matches _do_ have a match start time _mtime_?

How many games were played in each league season? 

How many clubs make up the EPL for each season?

How many clubs were represented in the first season 1992_1993 and in season 2023_2024?

Which clubs have been represented in each of the 31 seasons?








