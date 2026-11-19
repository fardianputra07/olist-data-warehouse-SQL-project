Olist E-Commerce Data Warehouse (MySQL 8.4)

An end-to-end data preparation project: taking raw, multi-table e-commerce data and turning it into a clean, documented, analysis-ready warehouse using MySQL 8.4 and the Medallion Architecture (Bronze → Silver → Gold).

Status: 🚧 In progress. Source analysis is done; database setup is next. See the Roadmap.

🎯 Project Goal

Real-world data is rarely analysis-ready. This project shows how I approach that gap:

Understand the source data and its relationships before touching the database.
Ingest raw CSV files without altering them (Bronze).
Profile and clean the data: fix type, consistency, and duplication problems (Silver).
Model the clean data into a star schema for reporting (Gold).
Prove it works with reconciliation checks, automated data quality tests, and business-facing SQL analysis.

The emphasis is on data preparation: finding what is wrong with the data, deciding how to fix it, and documenting why.

📦 Dataset

Brazilian E-Commerce Public Dataset by Olist, available on Kaggle. It describes orders placed on a Brazilian marketplace, split across 9 relational CSV files.

File	Describes	Rows	Columns
olist_orders_dataset	Order header: status and key timestamps	99,441	8
olist_order_items_dataset	Items per order: price, freight, seller	112,650	7
olist_order_payments_dataset	Payment method, installments, value	103,886	5
olist_order_reviews_dataset	Customer review scores and comments	99,224	7
olist_customers_dataset	Customer location data	99,441	5
olist_sellers_dataset	Seller location data	3,095	4
olist_products_dataset	Product attributes and category	32,951	9
olist_geolocation_dataset	Zip code prefix to coordinates	1,000,163	5
product_category_name_translation	Category names, Portuguese to English	71	2

Row counts come from a pre-load inspection of the raw CSV files (logical rows, with multi-line text fields counted once). They serve as the expected values for post-load reconciliation.

License: Please review the dataset license on its Kaggle page before reuse. The raw files are not redistributed in this repository; see Getting the Data.

🔍 Source Analysis

Before loading anything, I inspected each file's structure and mapped how the tables relate.

![alt text](<olist dataset diagram.jpg>)

Important notes on this diagram:

Olist is a single source system. The CRM/ERP grouping is an analytical assumption used to organize tables by business domain; it is not part of the dataset.
Relationships shown are hypotheses from documentation and file inspection. They are verified (or corrected) during profiling.
geolocation joins through zip code prefix, which is not unique in that table, so it is a soft reference rather than a true foreign key.
customer_id appears to be generated per order, while customer_unique_id identifies the actual person. This will drive the design of dim_customers.
Hypotheses to verify during profiling
#	Hypothesis	Status
H1	review_id is unique in the reviews table	⏳ Pending
H2	customer_id outnumbers customer_unique_id (same person, multiple orders)	⏳ Pending
H3	Every customer zip prefix exists in geolocation	⏳ Pending
H4	Every order has at least one order item	⏳ Pending
H5	Every product category has an English translation	⏳ Pending
H6	customer_id is unique in the orders table	⏳ Pending
H7	Some orders have no review	⏳ Pending

Other expected data quality issues, to be confirmed and documented:

Empty strings from CSV vs. true NULL values
Timestamps stored as text that need type conversion
Heavy duplication in the geolocation table
Column-name typos inherited from the source (e.g. product_name_lenght)
Free-text review fields with embedded line breaks and quotes
🏗️ Architecture
CSV files ──► BRONZE ──► SILVER ──► GOLD ──► Analytics
              (raw)      (clean)    (star schema)
Layer	Database	Purpose	Approach
Bronze	bronze	Raw data exactly as received	All columns stored as text; loaded with LOAD DATA LOCAL INFILE
Silver	silver	Cleaned, typed, standardized data	Type casting, NULL handling, deduplication, standardization, translation
Gold	gold	Business-ready model	Star schema exposed as views: fact and dimension tables

Each layer is its own MySQL database (in MySQL, schema and database are the same thing), so cross-layer queries stay simple and layers stay isolated.

Planned Gold model
Fact: fact_order_items (price, freight, payment, review, delivery timing)
Dimensions: dim_customers, dim_products, dim_sellers, dim_date

(Final design will be documented in docs/ once Silver is complete.)

✅ Load Reconciliation

After loading Bronze, each table's COUNT(*) is compared with the expected CSV row count. Any mismatch is investigated and documented.

Table	Expected	Loaded	Match
orders	99,441	–	⏳
order_items	112,650	–	⏳
order_payments	103,886	–	⏳
order_reviews	99,224	–	⏳
customers	99,441	–	⏳
sellers	3,095	–	⏳
products	32,951	–	⏳
geolocation	1,000,163	–	⏳
product_category_translation	71	–	⏳
📊 Planned Analysis

Questions the Gold layer should be able to answer:

Which product categories drive the most revenue?
How does delivery delay relate to review scores?
What does monthly sales growth look like over time?
Which sellers perform best, and by what measure?
How many customers come back for a second purchase?
🛠️ Tools
Tool	Use
MySQL 8.4	Database engine (CTEs and window functions used heavily)
MySQL Workbench / CLI	Development and execution
Python (pandas)	Pre-load file inspection
PlantUML	ERD and diagrams
Git & GitHub	Version control
📂 Repository Structure
olist-data-warehouse-SQL-project/
│
├── datasets/              # Raw CSVs (git-ignored, not included)
│
├── docs/                  # ERD, data model, data catalog, naming conventions
│
├── scripts/
│   ├── bronze/            # Table DDL + load scripts
│   ├── silver/            # Cleaning and transformation logic
│   └── gold/              # Star schema views
│
├── tests/                 # Data quality checks
│
├── .gitignore
└── README.md
🚀 Getting the Data
Download the dataset from Kaggle (search: Brazilian E-Commerce Public Dataset by Olist).
Place the CSV files in a local datasets/ folder (git-ignored).
Enable local file loading in MySQL 8.4 (local_infile is off by default):
sql
SET GLOBAL local_infile = 1;

and connect with mysql --local-infile=1 -u <user> -p. 4. Run the scripts in order: scripts/bronze → scripts/silver → scripts/gold.

🗺️ Roadmap
[x] Define scope and architecture
[x] Source analysis: file inspection and hypothesis ERD
[ ] Bronze: create tables and load all 9 CSV files
[ ] Reconciliation: compare loaded vs. expected row counts
[ ] Profiling: verify hypotheses H1–H7 and document findings
[ ] Silver: clean and standardize each table
[ ] Quality tests: automated checks on Silver
[ ] Gold: build star schema views
[ ] Analysis: business queries and written insights
[ ] Documentation: data catalog and final model diagram
🙏 Acknowledgements
Dataset: Olist, via Kaggle.
Project structure and Medallion Architecture approach inspired by the SQL Data Warehouse Project by Data With Baraa (MIT License). This project re-implements the concept in MySQL with a different dataset and its own cleaning and modeling decisions.
