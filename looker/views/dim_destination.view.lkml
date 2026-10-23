view: dim_destination {
  sql_table_name: TRAVEL_ANALYTICS.CORE.DIM_DESTINATION ;;
  dimension: destination_key { primary_key: yes hidden: yes type: string sql: ${TABLE}.DESTINATION_KEY ;; }
  dimension: city { type: string sql: ${TABLE}.CITY ;; }
  dimension: country { type: string map_layer_name: countries sql: ${TABLE}.COUNTRY ;; }
  dimension: region { type: string sql: ${TABLE}.REGION ;; }
}
