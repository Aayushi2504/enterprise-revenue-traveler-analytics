# KPI Definitions

| KPI | Definition | Source |
|---|---|---|
| Gross Booking Value | Sum of `gross_amount` across all bookings, including cancelled | `FCT_BOOKINGS` |
| Captured Amount | Sum of payments with status `captured` | `STG_PAYMENTS` |
| Net Revenue | Captured amount minus refunds | `FCT_BOOKINGS.net_revenue` |
| Active Bookings | Bookings where `booking_status <> 'cancelled'` | `FCT_BOOKINGS` |
| Avg Booking Value | Net revenue / active bookings | `MART.V_MONTHLY_REVENUE_KPIS` |
| Cancellation Rate | Cancelled bookings / all bookings | `MART.V_MONTHLY_REVENUE_KPIS` |
| Revenue MoM Growth | Net revenue / prior-month net revenue − 1 | `MART.V_MONTHLY_REVENUE_KPIS` |
| Lead Time | Days between booking date and travel start | `FCT_BOOKINGS` |
| Search-to-Book Rate | Customers who booked / customers who searched, by acquisition channel | `MART.V_ENGAGEMENT_FUNNEL` |
| Repeat Customer | Customer with more than one non-cancelled booking | `MART.V_CUSTOMER_VALUE` |

Revenue is attributed to the **booking date** month.
