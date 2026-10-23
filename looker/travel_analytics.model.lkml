connection: "snowflake_travel_analytics"

include: "/views/*.view.lkml"
include: "/dashboards/*.dashboard.lookml"

datagroup: daily_refresh {
  sql_trigger: SELECT MAX(run_ts) FROM TRAVEL_ANALYTICS.DQ.PIPELINE_AUDIT WHERE passed ;;
  max_cache_age: "24 hours"
}
persist_with: daily_refresh

explore: bookings {
  label: "Bookings & Revenue"
  from: fct_bookings
  join: dim_customer {
    type: left_outer
    relationship: many_to_one
    sql_on: ${bookings.customer_key} = ${dim_customer.customer_key} ;;
  }
  join: dim_destination {
    type: left_outer
    relationship: many_to_one
    sql_on: ${bookings.destination_key} = ${dim_destination.destination_key} ;;
  }
  join: dim_date {
    type: left_outer
    relationship: many_to_one
    sql_on: ${bookings.booking_date_key} = ${dim_date.date_key} ;;
  }
}
