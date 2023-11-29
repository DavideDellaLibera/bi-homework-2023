# bi-homework-2023

Visualizations on Tableau: https://public.tableau.com/app/profile/letizia5214/viz/BI1_211112/Overview

Code on GitHub: https://github.com/DavideDellaLibera/bi-homework-2023

Structure:
- db:
	- db-only-format: db obtained after a first formatting phase
	- db-processed: db resulting from all pre-processing steps

- queries:
	- denorm: contains all the queries for the denormalized DB
	- norm: contains all the queries for the normalized DB

- results: 
	- CSV files obtained as oputput of the queries and used as inputs in Tableau
	- general_info.csv: contains all the information related to all Course of Studies

- sql:
	- pre-proccessing: contains the code which allows the reproducibility, starting from db-only-format
	- info.sql: contains all the general informations per Course of Study
	- table-stats-appelli.sql: contains all the statistic related to the exams

To reproduce the code:
- start from "db_only_processed"
- reproduce the code contained in the folder "pre-processing", do so for both normalized and denormalized DB
