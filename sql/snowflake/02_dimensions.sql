-- 02_dimensions.sql : conformed dimensions (surrogate keys via hash)
USE DATABASE TRAVEL_ANALYTICS;

CREATE OR REPLACE TABLE CORE.DIM_DATE AS
WITH d AS (
  SELECT DATEADD(day, SEQ4(), '2023-01-01'::DATE) AS date_day
  FROM TABLE(GENERATOR(ROWCOUNT => 2192))   -- 2023-01-01 .. 2028-12-31
)
SELECT TO_NUMBER(TO_CHAR(date_day, 'YYYYMMDD')) AS date_key,
       date_day,
       YEAR(date_day) AS year, QUARTER(date_day) AS quarter, MONTH(date_day) AS month,
       MONTHNAME(date_day) AS month_name, WEEKOFYEAR(date_day) AS week_of_year,
       DAYOFWEEKISO(date_day) AS day_of_week,
       DAYOFWEEKISO(date_day) IN (6, 7) AS is_weekend,
       DATE_TRUNC('month', date_day) AS month_start
FROM d;

CREATE OR REPLACE TABLE CORE.DIM_CUSTOMER AS
SELECT MD5(customer_id) AS customer_key, customer_id, signup_date, country,
       loyalty_tier, acquisition_channel,
       DATE_TRUNC('month', signup_date) AS signup_cohort_month
FROM STG.STG_CUSTOMERS;

CREATE OR REPLACE TABLE CORE.DIM_DESTINATION AS
SELECT MD5(destination_id) AS destination_key, destination_id, city, country, region, avg_price_index
FROM STG.STG_DESTINATIONS;
