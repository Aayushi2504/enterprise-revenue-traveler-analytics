# Data Dictionary

## CORE.FCT_BOOKINGS (grain: one row per booking)
| Column | Type | Description |
|---|---|---|
| booking_id | STRING | Natural key |
| customer_key / destination_key | STRING | MD5 surrogate keys to dimensions |
| booking_date_key / travel_start_date_key | NUMBER | `YYYYMMDD` keys to `DIM_DATE` |
| booking_channel | STRING | web, app, call_center, partner |
| booking_status | STRING | confirmed, completed, cancelled |
| num_travelers | NUMBER | Travelers on the booking |
| lead_time_days | NUMBER | Booking date to travel start |
| length_of_stay_nights | NUMBER | Travel start to travel end |
| gross_amount | NUMBER(12,2) | Quoted booking value |
| captured_amount / refunded_amount | NUMBER(12,2) | Payments captured and refunded |
| net_revenue | NUMBER(12,2) | captured − refunded |
| is_cancelled | BOOLEAN | True when status is cancelled |

## CORE.FCT_ENGAGEMENT_DAILY (grain: customer x day)
Counts of `total_events`, `app_opens`, `searches`, `destination_views`, `wishlist_adds`, `checkout_starts`.

## Dimensions
- `DIM_CUSTOMER`: country, loyalty_tier, acquisition_channel, signup_cohort_month. Email is stored only as a hash.
- `DIM_DESTINATION`: city, country, region, avg_price_index.
- `DIM_DATE`: calendar attributes for 2023-2028.
