- dashboard: executive_revenue_overview
  title: Executive Revenue & Traveler Overview
  layout: newspaper
  preferred_viewer: dashboards-next

  filters:
  - name: region
    title: Region
    type: field_filter
    explore: bookings
    field: dim_destination.region

  elements:
  - name: net_revenue_kpi
    title: Net Revenue
    model: travel_analytics
    explore: bookings
    type: single_value
    fields: [bookings.net_revenue]
    listen: {region: dim_destination.region}
    row: 0
    col: 0
    width: 6
    height: 4

  - name: cancellation_kpi
    title: Cancellation Rate
    model: travel_analytics
    explore: bookings
    type: single_value
    fields: [bookings.cancellation_rate]
    listen: {region: dim_destination.region}
    row: 0
    col: 6
    width: 6
    height: 4

  - name: revenue_trend
    title: Net Revenue by Month
    model: travel_analytics
    explore: bookings
    type: looker_line
    fields: [dim_date.booking_month, bookings.net_revenue]
    sorts: [dim_date.booking_month]
    listen: {region: dim_destination.region}
    row: 4
    col: 0
    width: 12
    height: 7

  - name: revenue_by_destination
    title: Top Destinations by Net Revenue
    model: travel_analytics
    explore: bookings
    type: looker_bar
    fields: [dim_destination.city, bookings.net_revenue]
    sorts: [bookings.net_revenue desc]
    limit: 10
    listen: {region: dim_destination.region}
    row: 11
    col: 0
    width: 12
    height: 7
