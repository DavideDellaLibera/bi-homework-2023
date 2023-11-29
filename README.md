# UniMiB - Business Intelligence (Homework 2023) 

**Group**: Le Belle e la Bestia
Altieri Mariarosaria, Della Libera Davide and Longoni Letizia

DB and SQL Code on GitHub: https://github.com/DavideDellaLibera/bi-homework-2023

Dashboard and Visualizations on Tableau: https://public.tableau.com/app/profile/letizia5214/viz/BIproject_17012907139470/Appelli

**GitHub Folder Structure**
- _db_:
	- db-only-format: database obtained after a first formatting phase (RAR format);
	- db-processed: database resulting from all pre-processing steps (RAR format).

- _queries_:
	- denorm: folder which contains all the queries related to the denormalized database;
	- norm: folder that contains all the queries for the normalized database.

- _results_: 
	- CSV files obtained as output of the queries and used as inputs for the Tableau visualizations;
	- general_info.csv: contains the general information for each Course of Study.

- _sql_:
	- pre-proccessing: folder that contains the code which allows to reproduce the pre-processing phase, starting from db-only-format;
	- info.sql: SQL code to compute the general information for each Course of Study.
	- table-stats-appelli.sql: SQL code to compute all the statistic related to exams.

**Reproducibility**
Starting from the already processed database:\
1- Download and open the _db_only_processed_
2- Query the database, using the SQL code contained in the _queries_ folder

Starting from scratch:
1- Download and open the _db_only_format_
2- Download the files from _sql_ folder: launch the pre-processing SQL files for both normalized and denormalized database, the _info.sql_ file and also the _table-stats-appelli-sql_
3- Now you can query the database as previously explained

