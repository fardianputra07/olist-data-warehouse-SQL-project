/*
=====================================================================
Script  : 02_bronze_load.sql
Layer   : Bronze
Purpose : Load the 9 raw CSV files into olist_bronze, then reconcile.

BEFORE RUNNING
1. Replace C:/YOUR/PATH/datasets/ below with the real absolute path
   to your datasets folder. Use forward slashes, even on Windows.
2. Enable local file loading:
       SET GLOBAL local_infile = 1;
   and connect with:
       mysql --local-infile=1 -u <user> -p
3. Run from the mysql CLI:  source 02_bronze_load.sql
   (the CLI prints SHOW WARNINGS output clearly)

LINE TERMINATOR
- Line endings can differ PER FILE. Check each file before loading
  (Python snippet in project_log.md) and set LINES TERMINATED BY to
  '\n' or '\r\n' individually for each LOAD DATA.
- Verified per file: CRLF = order_reviews, product_category_name_translation.
  All other files are LF.
- A wrong choice has two faces. If the last column is exactly as wide as
  the data, the stray \r is truncated and the LOAD reports warnings. If the
  column is wider, the \r is stored silently with NO warning (this happened
  to product_category_name_translation). So check BOTH the warning count
  and the CR checks at the end of this file.

PARSING NOTES
- OPTIONALLY ENCLOSED BY '"'  : required (review text contains commas
                                and line breaks inside quotes).
- ESCAPED BY ''               : CSV escapes quotes by doubling them, not
                                with backslash. Disables MySQL's default
                                backslash escaping.
- Empty CSV fields load as empty strings (''), not NULL. This is
  intentional in Bronze; handling empties is a Silver task.

After EACH load, the line "Records: N  Deleted: 0  Skipped: 0  Warnings: 0"
must show Warnings: 0, and SHOW WARNINGS must return nothing. Any warning means
data may have been truncated or altered: stop and investigate.
=====================================================================
*/

USE olist_bronze;

-- ---------------------------------------------------------------
-- customers_dataset
-- ---------------------------------------------------------------
TRUNCATE TABLE customers_dataset;
LOAD DATA LOCAL INFILE 'C:/YOUR/PATH/datasets/olist_customers_dataset.csv'
INTO TABLE customers_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
SHOW WARNINGS;

-- ---------------------------------------------------------------
-- geolocation_dataset
-- ---------------------------------------------------------------
TRUNCATE TABLE geolocation_dataset;
LOAD DATA LOCAL INFILE 'C:/YOUR/PATH/datasets/olist_geolocation_dataset.csv'
INTO TABLE geolocation_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
SHOW WARNINGS;

-- ---------------------------------------------------------------
-- order_items_dataset
-- ---------------------------------------------------------------
TRUNCATE TABLE order_items_dataset;
LOAD DATA LOCAL INFILE 'C:/YOUR/PATH/datasets/olist_order_items_dataset.csv'
INTO TABLE order_items_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
SHOW WARNINGS;

-- ---------------------------------------------------------------
-- order_payments_dataset
-- ---------------------------------------------------------------
TRUNCATE TABLE order_payments_dataset;
LOAD DATA LOCAL INFILE 'C:/YOUR/PATH/datasets/olist_order_payments_dataset.csv'
INTO TABLE order_payments_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
SHOW WARNINGS;

-- ---------------------------------------------------------------
-- order_reviews_dataset  (most fragile: embedded line breaks; CRLF file)
-- ---------------------------------------------------------------
TRUNCATE TABLE order_reviews_dataset;
LOAD DATA LOCAL INFILE '.../olist_order_reviews_dataset.csv'
INTO TABLE order_reviews_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


-- ---------------------------------------------------------------
-- orders_dataset
-- ---------------------------------------------------------------
TRUNCATE TABLE orders_dataset;
LOAD DATA LOCAL INFILE 'C:/YOUR/PATH/datasets/olist_orders_dataset.csv'
INTO TABLE orders_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
SHOW WARNINGS;

-- ---------------------------------------------------------------
-- products_dataset
-- ---------------------------------------------------------------
TRUNCATE TABLE products_dataset;
LOAD DATA LOCAL INFILE 'C:/YOUR/PATH/datasets/olist_products_dataset.csv'
INTO TABLE products_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
SHOW WARNINGS;

-- ---------------------------------------------------------------
-- sellers_dataset
-- ---------------------------------------------------------------
TRUNCATE TABLE sellers_dataset;
LOAD DATA LOCAL INFILE 'C:/YOUR/PATH/datasets/olist_sellers_dataset.csv'
INTO TABLE sellers_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
SHOW WARNINGS;

-- ---------------------------------------------------------------
-- product_category_name_translation  (CRLF file)
-- ---------------------------------------------------------------
TRUNCATE TABLE product_category_name_translation;
LOAD DATA LOCAL INFILE 'C:/YOUR/PATH/datasets/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;
SHOW WARNINGS;


/* =====================================================================
   RECONCILIATION: loaded vs. expected row counts
   (expected values come from the pre-load CSV inspection)
   ===================================================================== */
SELECT tbl, expected, loaded,
       IF(expected = loaded, 'OK', 'MISMATCH') AS result
FROM (
  SELECT 'customers_dataset' AS tbl, 99441 AS expected, COUNT(*) AS loaded FROM customers_dataset
  UNION ALL SELECT 'geolocation_dataset',  1000163, COUNT(*) FROM geolocation_dataset
  UNION ALL SELECT 'order_items_dataset',   112650, COUNT(*) FROM order_items_dataset
  UNION ALL SELECT 'order_payments_dataset', 103886, COUNT(*) FROM order_payments_dataset
  UNION ALL SELECT 'order_reviews_dataset',   99224, COUNT(*) FROM order_reviews_dataset
  UNION ALL SELECT 'orders_dataset',          99441, COUNT(*) FROM orders_dataset
  UNION ALL SELECT 'products_dataset',        32951, COUNT(*) FROM products_dataset
  UNION ALL SELECT 'sellers_dataset',          3095, COUNT(*) FROM sellers_dataset
  UNION ALL SELECT 'product_category_name_translation', 71, COUNT(*) FROM product_category_name_translation
) r;


/* =====================================================================
   SANITY CHECKS: detect a wrong line terminator or misparsed fields
   Every result below should be 0 (run AFTER confirming Warnings: 0 on each load).
   ===================================================================== */

-- Wrong terminator leaves a trailing \r in the LAST column of each row.
SELECT 'customers: state length <> 2' AS check_name,
       COUNT(*) AS bad_rows
FROM customers_dataset WHERE CHAR_LENGTH(customer_state) <> 2
UNION ALL
SELECT 'orders: trailing CR in last column',
       COUNT(*) FROM orders_dataset
       WHERE order_estimated_delivery_date LIKE CONCAT('%', CHAR(13))
UNION ALL
SELECT 'products: trailing CR in last column',
       COUNT(*) FROM products_dataset
       WHERE product_width_cm LIKE CONCAT('%', CHAR(13))
UNION ALL
SELECT 'reviews: trailing CR in last column',
       COUNT(*) FROM order_reviews_dataset
       WHERE review_answer_timestamp LIKE CONCAT('%', CHAR(13))
UNION ALL
-- Misparsed rows shift columns, so a score outside 1-5 reveals them.
SELECT 'reviews: score not in 1..5',
       COUNT(*) FROM order_reviews_dataset
       WHERE review_score NOT IN ('1','2','3','4','5')
UNION ALL
-- Last column of every table must not end with a carriage return.
SELECT 'geolocation: trailing CR', COUNT(*) FROM geolocation_dataset
       WHERE geolocation_state LIKE CONCAT('%', CHAR(13))
UNION ALL
SELECT 'order_items: trailing CR', COUNT(*) FROM order_items_dataset
       WHERE freight_value LIKE CONCAT('%', CHAR(13))
UNION ALL
SELECT 'order_payments: trailing CR', COUNT(*) FROM order_payments_dataset
       WHERE payment_value LIKE CONCAT('%', CHAR(13))
UNION ALL
SELECT 'sellers: trailing CR', COUNT(*) FROM sellers_dataset
       WHERE seller_state LIKE CONCAT('%', CHAR(13))
UNION ALL
SELECT 'translation: trailing CR', COUNT(*) FROM product_category_name_translation
       WHERE product_category_name_english LIKE CONCAT('%', CHAR(13))
UNION ALL
-- Timestamp format check (works after truncation has been eliminated).
SELECT 'reviews: answer_timestamp bad format', COUNT(*) FROM order_reviews_dataset
       WHERE review_answer_timestamp NOT REGEXP
       '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$';
SELECT 'geolocation: trailing CR' AS check_name, COUNT(*) AS bad_rows
FROM geolocation_dataset WHERE geolocation_state LIKE CONCAT('%', CHAR(13))
UNION ALL
SELECT 'order_items: trailing CR', COUNT(*)
FROM order_items_dataset WHERE freight_value LIKE CONCAT('%', CHAR(13))
UNION ALL
SELECT 'order_payments: trailing CR', COUNT(*)
FROM order_payments_dataset WHERE payment_value LIKE CONCAT('%', CHAR(13))
UNION ALL
SELECT 'sellers: trailing CR', COUNT(*)
FROM sellers_dataset WHERE seller_state LIKE CONCAT('%', CHAR(13))
UNION ALL
SELECT 'translation: trailing CR', COUNT(*)
FROM product_category_name_translation
WHERE product_category_name_english LIKE CONCAT('%', CHAR(13))
UNION ALL
SELECT 'reviews: answer_timestamp bad format', COUNT(*)
FROM order_reviews_dataset
WHERE review_answer_timestamp NOT REGEXP
  '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$';