-- 01_staging.sql : cast types, standardize values, dedupe with window functions
USE DATABASE TRAVEL_ANALYTICS;

CREATE OR REPLACE TABLE STG.STG_CUSTOMERS AS
SELECT customer_id, email_hash,
       TRY_TO_DATE(signup_date) AS signup_date,
       UPPER(TRIM(country)) AS country,
       LOWER(loyalty_tier) AS loyalty_tier,
       LOWER(acquisition_channel) AS acquisition_channel
FROM RAW.CUSTOMERS
WHERE customer_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY signup_date) = 1;

CREATE OR REPLACE TABLE STG.STG_DESTINATIONS AS
SELECT destination_id, city, country, region, avg_price_index
FROM RAW.DESTINATIONS
QUALIFY ROW_NUMBER() OVER (PARTITION BY destination_id ORDER BY city) = 1;

CREATE OR REPLACE TABLE STG.STG_BOOKINGS AS
SELECT booking_id, customer_id, destination_id,
       TRY_TO_DATE(booking_date) AS booking_date,
       TRY_TO_DATE(travel_start_date) AS travel_start_date,
       TRY_TO_DATE(travel_end_date) AS travel_end_date,
       LOWER(booking_channel) AS booking_channel,
       LOWER(booking_status) AS booking_status,
       num_travelers, gross_amount, currency
FROM RAW.BOOKINGS
WHERE booking_id IS NOT NULL AND customer_id IS NOT NULL AND gross_amount >= 0
QUALIFY ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY booking_date DESC) = 1;

CREATE OR REPLACE TABLE STG.STG_PAYMENTS AS
SELECT payment_id, booking_id,
       TRY_TO_DATE(payment_date) AS payment_date,
       amount, LOWER(payment_method) AS payment_method,
       LOWER(payment_status) AS payment_status,
       COALESCE(refund_amount, 0) AS refund_amount
FROM RAW.PAYMENTS
WHERE payment_id IS NOT NULL AND amount >= 0
QUALIFY ROW_NUMBER() OVER (PARTITION BY payment_id ORDER BY payment_date DESC) = 1;

CREATE OR REPLACE TABLE STG.STG_ENGAGEMENT_EVENTS AS
SELECT event_id, customer_id,
       TRY_TO_TIMESTAMP_NTZ(event_ts) AS event_ts,
       LOWER(event_type) AS event_type, LOWER(device) AS device
FROM RAW.ENGAGEMENT_EVENTS
WHERE event_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY event_ts) = 1;
