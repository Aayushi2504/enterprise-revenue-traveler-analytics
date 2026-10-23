-- 05_post_load_checks.sql : in-warehouse validation, results logged to DQ.PIPELINE_AUDIT
USE DATABASE TRAVEL_ANALYTICS;

INSERT INTO DQ.PIPELINE_AUDIT (check_name, table_name, passed, failed_rows, detail)
SELECT 'fk_customer', 'CORE.FCT_BOOKINGS', COUNT(*) = 0, COUNT(*), 'orphan customer_key'
FROM CORE.FCT_BOOKINGS f LEFT JOIN CORE.DIM_CUSTOMER c USING (customer_key) WHERE c.customer_key IS NULL
UNION ALL
SELECT 'fk_destination', 'CORE.FCT_BOOKINGS', COUNT(*) = 0, COUNT(*), 'orphan destination_key'
FROM CORE.FCT_BOOKINGS f LEFT JOIN CORE.DIM_DESTINATION d USING (destination_key) WHERE d.destination_key IS NULL
UNION ALL
SELECT 'unique_booking', 'CORE.FCT_BOOKINGS', COUNT(*) = 0, COUNT(*), 'duplicate booking_id'
FROM (SELECT booking_id FROM CORE.FCT_BOOKINGS GROUP BY 1 HAVING COUNT(*) > 1)
UNION ALL
SELECT 'revenue_reconciliation', 'CORE.FCT_BOOKINGS', ABS(a.core - b.stg) < 0.01, ROUND(ABS(a.core - b.stg)), 'core net revenue vs staging payments'
FROM (SELECT SUM(net_revenue) AS core FROM CORE.FCT_BOOKINGS) a,
     (SELECT SUM(amount - refund_amount) AS stg FROM STG.STG_PAYMENTS p
        JOIN STG.STG_BOOKINGS b USING (booking_id) WHERE p.payment_status = 'captured') b
UNION ALL
SELECT 'staging_vs_raw_bookings', 'STG.STG_BOOKINGS', s.n = r.n, ABS(s.n - r.n), 'rows dropped by dedupe/cleansing'
FROM (SELECT COUNT(*) n FROM STG.STG_BOOKINGS) s, (SELECT COUNT(*) n FROM RAW.BOOKINGS) r;
