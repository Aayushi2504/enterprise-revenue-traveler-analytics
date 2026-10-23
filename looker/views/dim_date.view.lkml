view: dim_date {
  sql_table_name: TRAVEL_ANALYTICS.CORE.DIM_DATE ;;
  dimension: date_key { primary_key: yes hidden: yes type: number sql: ${TABLE}.DATE_KEY ;; }
  dimension_group: booking { type: time timeframes: [date, week, month, quarter, year] convert_tz: no datatype: date sql: ${TABLE}.DATE_DAY ;; }
  dimension: month_name { type: string sql: ${TABLE}.MONTH_NAME ;; }
  dimension: is_weekend { type: yesno sql: ${TABLE}.IS_WEEKEND ;; }
}
