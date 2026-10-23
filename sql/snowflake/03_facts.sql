-- 03_facts.sql : fact tables at a declared grain
USE DATABASE TRAVEL_ANALYTICS;

-- Grain: one row per booking
CREATE OR REPLACE TABLE CORE.FCT_BOOKINGS AS
WITH pay AS (
  SELECT booking_id,
         SUM(amount) AS captured_amount,
         SUM(refund_amount) AS refunded_amount,
         MIN(payment_date) AS first_payment_date
  FROM STG.STG_PAYMENTS
  WHERE payment_status = 'captured'
  GROUP BY booking_id
)
SELECT b.booking_id,
       c.customer_key, d.destination_key,
       TO_NUMBER(TO_CHAR(b.booking_date, 'YYYYMMDD')) AS booking_date_key,
       TO_NUMBER(TO_CHAR(b.travel_start_date, 'YYYYMMDD')) AS travel_start_date_key,
       b.booking_channel, b.booking_status, b.num_travelers,
       DATEDIFF(day, b.booking_date, b.travel_start_date) AS lead_time_days,
       DATEDIFF(day, b.travel_start_date, b.travel_end_date) AS length_of_stay_nights,
       b.gross_amount,
       COALESCE(p.captured_amount, 0) AS captured_amount,
       COALESCE(p.refunded_amount, 0) AS refunded_amount,
       COALESCE(p.captured_amount, 0) - COALESCE(p.refunded_amount, 0) AS net_revenue,
       (b.booking_status = 'cancelled') AS is_cancelled
FROM STG.STG_BOOKINGS b
JOIN CORE.DIM_CUSTOMER c ON c.customer_id = b.customer_id
JOIN CORE.DIM_DESTINATION d ON d.destination_id = b.destination_id
LEFT JOIN pay p ON p.booking_id = b.booking_id;

-- Grain: one row per customer per day
CREATE OR REPLACE TABLE CORE.FCT_ENGAGEMENT_DAILY AS
SELECT MD5(e.customer_id) AS customer_key,
       TO_NUMBER(TO_CHAR(e.event_ts::DATE, 'YYYYMMDD')) AS date_key,
       COUNT(*) AS total_events,
       COUNT_IF(event_type = 'app_open') AS app_opens,
       COUNT_IF(event_type = 'search') AS searches,
       COUNT_IF(event_type = 'destination_view') AS destination_views,
       COUNT_IF(event_type = 'wishlist_add') AS wishlist_adds,
       COUNT_IF(event_type = 'checkout_start') AS checkout_starts
FROM STG.STG_ENGAGEMENT_EVENTS e
JOIN STG.STG_CUSTOMERS c ON c.customer_id = e.customer_id
GROUP BY 1, 2;
