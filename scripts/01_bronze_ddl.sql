/*
=====================================================================
Script  : 01_bronze_ddl.sql
Layer   : Bronze (raw, no transformation)
Purpose : Create the three layer databases and the 9 Bronze tables.

Design notes
- Every column is stored as text. Type conversion belongs in Silver.
- Column order matches the CSV header order exactly (required by LOAD DATA).
- VARCHAR widths are based on the measured maximum length per column
  (pre-load inspection), plus headroom. Bronze must never truncate.
- olist_bronze uses an accent-sensitive, case-sensitive collation so that
  profiling shows the real spelling variations (e.g. "sao paulo" vs
  "são paulo"). The MySQL default (utf8mb4_0900_ai_ci) would silently
  treat them as equal.
- Table names = CSV file names without the "olist_" prefix.

WARNING: re-running this script drops and recreates the Bronze tables.
=====================================================================
*/

CREATE DATABASE IF NOT EXISTS olist_bronze
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_cs;
CREATE DATABASE IF NOT EXISTS olist_silver
  CHARACTER SET utf8mb4;
CREATE DATABASE IF NOT EXISTS olist_gold
  CHARACTER SET utf8mb4;

USE olist_bronze;

-- ---------------------------------------------------------------
-- customers_dataset  (expected: 99,441 rows)
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS customers_dataset;
CREATE TABLE customers_dataset (
  customer_id               VARCHAR(32),
  customer_unique_id        VARCHAR(32),
  customer_zip_code_prefix  VARCHAR(5),
  customer_city             VARCHAR(50),
  customer_state            VARCHAR(2)
);

-- ---------------------------------------------------------------
-- geolocation_dataset  (expected: 1,000,163 rows)
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS geolocation_dataset;
CREATE TABLE geolocation_dataset (
  geolocation_zip_code_prefix  VARCHAR(5),
  geolocation_lat              VARCHAR(30),
  geolocation_lng              VARCHAR(30),
  geolocation_city             VARCHAR(50),
  geolocation_state            VARCHAR(2)
);

-- ---------------------------------------------------------------
-- order_items_dataset  (expected: 112,650 rows)
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS order_items_dataset;
CREATE TABLE order_items_dataset (
  order_id             VARCHAR(32),
  order_item_id        VARCHAR(5),
  product_id           VARCHAR(32),
  seller_id            VARCHAR(32),
  shipping_limit_date  VARCHAR(19),
  price                VARCHAR(15),
  freight_value        VARCHAR(15)
);

-- ---------------------------------------------------------------
-- order_payments_dataset  (expected: 103,886 rows)
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS order_payments_dataset;
CREATE TABLE order_payments_dataset (
  order_id              VARCHAR(32),
  payment_sequential    VARCHAR(5),
  payment_type          VARCHAR(20),
  payment_installments  VARCHAR(5),
  payment_value         VARCHAR(15)
);

-- ---------------------------------------------------------------
-- order_reviews_dataset  (expected: 99,224 rows)
-- Free-text columns use TEXT (multi-line comments are possible).
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS order_reviews_dataset;
CREATE TABLE order_reviews_dataset (
  review_id                VARCHAR(32),
  order_id                 VARCHAR(32),
  review_score             VARCHAR(5),
  review_comment_title     TEXT,
  review_comment_message   TEXT,
  review_creation_date     VARCHAR(19),
  review_answer_timestamp  VARCHAR(19)
);

-- ---------------------------------------------------------------
-- orders_dataset  (expected: 99,441 rows)
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS orders_dataset;
CREATE TABLE orders_dataset (
  order_id                       VARCHAR(32),
  customer_id                    VARCHAR(32),
  order_status                   VARCHAR(20),
  order_purchase_timestamp       VARCHAR(19),
  order_approved_at              VARCHAR(19),
  order_delivered_carrier_date   VARCHAR(19),
  order_delivered_customer_date  VARCHAR(19),
  order_estimated_delivery_date  VARCHAR(19)
);

-- ---------------------------------------------------------------
-- products_dataset  (expected: 32,951 rows)
-- Note: "lenght" is a typo inherited from the source. Kept as-is in Bronze;
-- corrected in Silver.
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS products_dataset;
CREATE TABLE products_dataset (
  product_id                  VARCHAR(32),
  product_category_name       VARCHAR(60),
  product_name_lenght         VARCHAR(10),
  product_description_lenght  VARCHAR(10),
  product_photos_qty          VARCHAR(10),
  product_weight_g            VARCHAR(10),
  product_length_cm           VARCHAR(10),
  product_height_cm           VARCHAR(10),
  product_width_cm            VARCHAR(10)
);

-- ---------------------------------------------------------------
-- sellers_dataset  (expected: 3,095 rows)
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS sellers_dataset;
CREATE TABLE sellers_dataset (
  seller_id               VARCHAR(32),
  seller_zip_code_prefix  VARCHAR(5),
  seller_city             VARCHAR(50),
  seller_state            VARCHAR(2)
);

-- ---------------------------------------------------------------
-- product_category_name_translation  (expected: 71 rows)
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS product_category_name_translation;
CREATE TABLE product_category_name_translation (
  product_category_name          VARCHAR(60),
  product_category_name_english  VARCHAR(60)
);

SHOW COLLATION LIKE 'utf8mb4_0900_as_cs';