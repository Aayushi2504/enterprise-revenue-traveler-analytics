view: dim_customer {
  sql_table_name: TRAVEL_ANALYTICS.CORE.DIM_CUSTOMER ;;
  dimension: customer_key { primary_key: yes hidden: yes type: string sql: ${TABLE}.CUSTOMER_KEY ;; }
  dimension: country { type: string sql: ${TABLE}.COUNTRY ;; }
  dimension: loyalty_tier { type: string sql: ${TABLE}.LOYALTY_TIER ;; }
  dimension: acquisition_channel { type: string sql: ${TABLE}.ACQUISITION_CHANNEL ;; }
  dimension_group: signup_cohort { type: time timeframes: [month, quarter, year] sql: ${TABLE}.SIGNUP_COHORT_MONTH ;; }
}
