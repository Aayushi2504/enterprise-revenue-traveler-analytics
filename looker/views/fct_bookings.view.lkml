view: fct_bookings {
  sql_table_name: TRAVEL_ANALYTICS.CORE.FCT_BOOKINGS ;;

  dimension: booking_id { primary_key: yes type: string sql: ${TABLE}.BOOKING_ID ;; }
  dimension: customer_key { hidden: yes type: string sql: ${TABLE}.CUSTOMER_KEY ;; }
  dimension: destination_key { hidden: yes type: string sql: ${TABLE}.DESTINATION_KEY ;; }
  dimension: booking_date_key { hidden: yes type: number sql: ${TABLE}.BOOKING_DATE_KEY ;; }
  dimension: booking_channel { type: string sql: ${TABLE}.BOOKING_CHANNEL ;; }
  dimension: booking_status { type: string sql: ${TABLE}.BOOKING_STATUS ;; }
  dimension: is_cancelled { type: yesno sql: ${TABLE}.IS_CANCELLED ;; }
  dimension: lead_time_days { type: number sql: ${TABLE}.LEAD_TIME_DAYS ;; }
  dimension: lead_time_bucket {
    type: tier
    tiers: [0, 15, 30, 60, 90]
    style: integer
    sql: ${lead_time_days} ;;
  }

  measure: booking_count { type: count label: "Bookings" }
  measure: active_booking_count {
    type: count
    filters: [is_cancelled: "No"]
    label: "Active Bookings"
  }
  measure: net_revenue {
    type: sum
    sql: ${TABLE}.NET_REVENUE ;;
    value_format_name: usd_0
    description: "Captured payments minus refunds. See docs/kpi_definitions.md"
  }
  measure: gross_booking_value {
    type: sum
    sql: ${TABLE}.GROSS_AMOUNT ;;
    value_format_name: usd_0
  }
  measure: travelers { type: sum sql: ${TABLE}.NUM_TRAVELERS ;; }
  measure: cancellation_rate {
    type: number
    sql: COUNT_IF(${is_cancelled}) / NULLIF(${booking_count}, 0) ;;
    value_format_name: percent_1
  }
  measure: avg_booking_value {
    type: number
    sql: ${net_revenue} / NULLIF(${active_booking_count}, 0) ;;
    value_format_name: usd
  }
  measure: avg_lead_time { type: average sql: ${lead_time_days} ;; value_format_name: decimal_1 }
}
