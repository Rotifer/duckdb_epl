# Loading and viewing data in DuckDB 🦆⚽

Now that we have created our source files, we need to upload them into a DuckDB database, verify the data and re-format to create our final analysis-ready tables. DuckDB makes loading data very easy and its schema feature is very convenient for organasing tables and other database objects.


## Before we start

I am assuming the following:

- You have installed DuckDB - to verify execute `which duckdb` from your terminal. If you get nothing back, then DuckDB is not installed or is not in your executables path.
- You have checked out the code from the GitHub repo


## Getting started

We now have our files ready for loading into DuckDB. Our DuckDB database file is simply called _epl.ddb_. To load our data, we first need to create a DuckDB database which we can do very easliy by changing to the _db_files_ directory and executing the command:

```sh
duckdb epl.ddb
```

Executing this command now lands us in the _duckdb_ command line client and you should see the _D_ prompt. You can now start issuing commands that the client will execute against the DuckDB database file. If you have used the SQLite _sqlite3_ client it will feel very familiar. However, even if you are new to it, it is not difficult to learn. The most important point to remember is that it takes two types of commands:

1. Dot commands: so called because they begind with a period (.). They are used to perform tasks such as listing all objects of a certain type such as tables, importing/exporting data and for setting certain DuckDB variables. From the client, try `.help` to see the options. Note that _nothing_, not even white space can precede the dot and the dot command is _not_ terminated by a semicolon.

2. SQL commands: These are standard DuckDB SQL commands and they are _not_ preceded by a dot but are terminated by a semi-colon. We will see loads of these throughout for creating tables, selecting/updating/deleting data and do on. When you enter a command in the DuckDB shell and hit return without the the terminating semi-colon, you will see the _secondary prompt_, ‣ whiich indicates that the client is waiting for additional input.

If you exit the DuckDB client by issuing one of the dot commands _.q_ or _.quit_ without creating any objects, the database file will not be saved. If you create any content, even an empty table, the file named _epl.ddb_ will be created and saved.

## Importing our first file

We cannot do much with the data in DuckDB until we import it but first we can have a look at it before we do a full import.

### Explore before loading 

We are going to import the file _seasons_1993_2023.tsv_ which we generated using a shell script in the previous chapter. Before we import the file, we can take a "sneak peak" at it by executing the following command in the DuckDB client at the _D_ prompt:

```sql
SELECT * FROM  '../output_data/seasons_1993_2023.tsv' LIMIT 5;
```

You should see something that looks like the follwing in your teminal:

![post 3 - figure 1](images/post_03_fig1.png)

By default the output appears in what DuckDB calls _current output mode: duckbox_. You can verify this by issuing the `.mode` dot command. We will see later how to change this mode to customise outputs from queries.

Like the Unix _head_ command, the SQL query above shows all columns for the file. However, unlike _head_, by default it recognises the first row as the column names. To get the equivalent output from _head_, you woud need to execute `head -6 ../output_data/seasons_1993_2023.tsv`. The SQL query output also informs us that there are seven columns and it has assigned data types to those columns. The data types are DuckDB guesses based on available data and we are free to change column data types to other compatible data types for particular columns which we will do later. 

The SQL command above is interesting because DuckDB is allowing to to select data directly from a file. This is a novel and very useful feature of DuckDB. It is one of its many very convenient features and really useful for exploring data. 

### Import the file

You can import files in the same way as in SQLite using the _.import FILE TABLE_ command but DuckDB has added easier ways to do this which we will exploit here.

### Schemas

Unlike SQLite but like PostgreSQL, DuckDB provides a _schemas_ which are convenient for dividing your database into logical units. Every DuckDB database has a default schema called _main_; in PostgreSQL the equivalent default schema is called _public_. They are somewhat like namespaces and allow us to group similar objects together. A common pattern in database programming is to load new and unverified data into a _staging_ area where it can be stored, analysed and manipulated before the data is transferred into another schema and integrated with other verified data for analysis. To create a schema we simply execute the _CREATE SCHEMA_ command and then switch to it like so:

```sql
-- Create a schema for holding newly uploaded data that is to be checked and re-formatted for analysis.
CREATE SCHEMA staging;
USE staging;
```

__Tip__: Use schemas to group like with like but ensure you are using the correct schema for you your queries. Either issue a `USE SCHEMA;` command or qualify your objects with the schema name like so: `schema_name.table_name` in queries.

### Executing a data loading command

We are now going to create a table in the staging schema for the entire contents of the file _seasons_1993_2023.tsv_ by executing the following command:

```sql
CREATE OR REPLACE TABLE seasons_1993_2023_raw AS 
SELECT * 
FROM  '../output_data/seasons_1993_2023.tsv';
```

Like many command command line tools, when you execute a command, "no news is good news!". If all went well, you simply get back an empty prompt. That wasn't very difficult, in fact, DuckDB makes this kind of task trivial. We were able to create a table by simply selecting everything ( _SELECT * _) from an external text file. DuckDB also allow more fine-grained control over data imports using functions such as _read_csv_ that take options which we can explicitly set

```sql
SELECT COUNT(*) loaded_row_count FROM seasons_1993_2023_raw;
```

This query reports that 12641 rows were loaded. The `wc -l` Unix command gives a row count of 12642, its extra line is the first column names row that DuckDB correctly identified as the table column names rather than as a data row. 

### Examining the newly created table in depth

The _CREATE TABLE_ command above guessed correctly that our input file has a non-data column header row and that the columns are tab-separated. We have ended up with a table of seven columns and 12641 data rows. Using SELECT and LIMIT in SQL allows us to view the first rows in the table but we can go further and get a detailed view of the _structure_ of the table with respect to data types and unique column values using some quite straightforward SQL.

#### DESCRIBE the table

When you execute the following SQL, you should see the output shown in the figure below.

```sql
DESCRIBE seasons_1993_2023_raw;
```

![Post 3 - figure 2](images/post_03_fig2.png)

The column names we added in our processing shell script were correctly used by DuckDB as table column names. The column types are more interesting; it has assigned type _VARCHAR_ to five of the seven columns. DuckDB's _VARCHAR_ type behaves like the _TEXT_ type in PostgreSQL which is convenient because it does not requires a length value as it does in many other database software where you need type declarations like _VARCHAR(50)_. It is also a general data type that can represent date values or numbers as text that can be converted to more appropriate types as needed. For example, we have a date column but DuckDB has interpreted the date strings as _VARCHAR_ and has not tried to be "clever" like Excel and do automatic type conversions! It has inferred a type of _BIGINT_ for the columns _home_club_goals_ and _away_club_goals_. DuckDB has many numeric types and it has correctly inferred an integer type for these columns; it has "played safe" by assigning the biggest integer type but common sense tells us no football score is ever going to need such large integers as this type allows. We will cast these columns to a more suitable integer type later. 

__Tip__:It is always worth checking carefully what types DuckDB has inferred because if you expect a numeric type for a column and it assings a character type, then it may indicate mixed data types in the column or that the columns are not aligned correctly.

## Loading season 1992_1993 data

We only have a Wikipedia crosstab table version of the match scores for this season. For now, we will just import into the _staging_ schema. 

Let's first take a look at the first 10 rows:

```sql
SELECT * 
FROM '../source_data/season_1992_1993.tsv' 
LIMIT 10;
```
This shows us the first 10 rows and confirms that we have the expected 23 columns, as show below:

![Post 5 fig1](images/post_05_fig1.png)
_
We can now import the table and get to work extracting its data into a more usable format. 

```sql
USE SCHEMA staging;
CREATE OR REPLACE TABLE season_1992_1993_raw AS
SELECT * 
FROM '../source_data/season_1992_1993.tsv';
```

Re-formatting this dataset to make it compatible with the other seasons' data will be an interesting challenge and a chance to practice with DuckDB's very powerful _UNPIVOT_ SQL command. 

## Main points

- Discussed the two types of commands that you can execute in the DuckDB client
    1. Dot commands
    2. SQL commands
- Created the following DuckDB objects
    - A DuckDB database - _epl.ddb_
    - A schema within the database - _staging_
- Created a new DuckDB table _seasons_1993_2023_raw_ in the schema new schema
- Verified that both data row counts and the number of columns in the new table were as expected
- Used the _DESCRIBE_ command to get a convenient view of the table column names and data types.

