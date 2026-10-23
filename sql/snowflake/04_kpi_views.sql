-- 04_kpi_views.sql : business-facing KPI layer (consumed by Looker)
USE DATABASE TRAVEL_ANALYTICS;

-- Monthly revenue with MoM growth and cancellation rate
CREATE OR REPLACE VIEW MART.V_MONTHLY_REVENUE_KPIS AS
WITH m AS (
  SELECT dd.month_start,
         COUNT(*) AS bookings,
         COUNT_IF(NOT f.is_cancelled) AS active_bookings,
         SUM(f.net_revenue) AS net_revenue,
         SUM(f.gross_amount) AS gross_booking_value,
         COUNT_IF(f.is_cancelled) / NULLIF(COUNT(*), 0) AS cancellation_rate
  FROM CORE.FCT_BOOKINGS f
  JOIN CORE.DIM_DATE dd ON dd.date_key = f.booking_date_key
  GROUP BY dd.month_start
)
SELECT month_start, bookings, active_bookings, net_revenue, gross_booking_value, cancellation_rate,
       net_revenue / NULLIF(active_bookings, 0) AS avg_booking_value,
       net_revenue / NULLIF(LAG(net_revenue) OVER (ORDER BY month_start), 0) - 1 AS revenue_mom_growth,
       SUM(net_revenue) OVER (ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) / 3 AS net_revenue_3m_avg
FROM m;

-- Destination performance with revenue rank per region
CREATE OR REPLACE VIEW MART.V_DESTINATION_PERFORMANCE AS
SELECT d.region, d.city, d.country,
       COUNT(*) AS bookings,
       SUM(f.num_travelers) AS travelers,
       SUM(f.net_revenue) AS net_revenue,
       AVG(f.lead_time_days) AS avg_lead_time_days,
       AVG(f.length_of_stay_nights) AS avg_length_of_stay,
       RANK() OVER (PARTITION BY d.region ORDER BY SUM(f.net_revenue) DESC) AS revenue_rank_in_region
FROM CORE.FCT_BOOKINGS f
JOIN CORE.DIM_DESTINATION d ON d.destination_key = f.destination_key
WHERE NOT f.is_cancelled
GROUP BY d.region, d.city, d.country;

-- Traveler engagement funnel by acquisition channel
CREATE OR REPLACE VIEW MART.V_ENGAGEMENT_FUNNEL AS
WITH eng AS (
  SELECT customer_key,
         SUM(searches) AS searches, SUM(destination_views) AS views,
         SUM(wishlist_adds) AS wishlists, SUM(checkout_starts) AS checkouts
  FROM CORE.FCT_ENGAGEMENT_DAILY GROUP BY customer_key
), bk AS (
  SELECT customer_key, COUNT_IF(NOT is_cancelled) AS completed_bookings
  FROM CORE.FCT_BOOKINGS GROUP BY customer_key
)
SELECT c.acquisition_channel,
       COUNT(*) AS customers,
       COUNT_IF(e.searches > 0) AS searched,
       COUNT_IF(e.views > 0) AS viewed,
       COUNT_IF(e.checkouts > 0) AS started_checkout,
       COUNT_IF(b.completed_bookings > 0) AS booked,
       COUNT_IF(b.completed_bookings > 0) / NULLIF(COUNT_IF(e.searches > 0), 0) AS search_to_book_rate
FROM CORE.DIM_CUSTOMER c
LEFT JOIN eng e ON e.customer_key = c.customer_key
LEFT JOIN bk b ON b.customer_key = c.customer_key
GROUP BY c.acquisition_channel;

-- Customer value and repeat-booking behaviour
CREATE OR REPLACE VIEW MART.V_CUSTOMER_VALUE AS
SELECT c.customer_id, c.loyalty_tier, c.acquisition_channel, c.signup_cohort_month,
       COUNT_IF(NOT f.is_cancelled) AS bookings,
       SUM(f.net_revenue) AS lifetime_net_revenue,
       MIN(f.booking_date_key) AS first_booking_date_key,
       COUNT_IF(NOT f.is_cancelled) > 1 AS is_repeat_customer
FROM CORE.DIM_CUSTOMER c
LEFT JOIN CORE.FCT_BOOKINGS f ON f.customer_key = c.customer_key
GROUP BY c.customer_id, c.loyalty_tier, c.acquisition_channel, c.signup_cohort_month;
