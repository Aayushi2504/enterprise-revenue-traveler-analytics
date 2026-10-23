-- 00_setup.sql : database, schemas, file format, stage, RAW tables
CREATE DATABASE IF NOT EXISTS TRAVEL_ANALYTICS;
USE DATABASE TRAVEL_ANALYTICS;

CREATE SCHEMA IF NOT EXISTS RAW;   -- landed as-is from source extracts
CREATE SCHEMA IF NOT EXISTS STG;   -- typed, deduplicated, standardized
CREATE SCHEMA IF NOT EXISTS CORE;  -- dimensional model (star schema)
CREATE SCHEMA IF NOT EXISTS MART;  -- KPI views consumed by Looker
CREATE SCHEMA IF NOT EXISTS DQ;    -- data-quality audit tables

CREATE FILE FORMAT IF NOT EXISTS RAW.CSV_FORMAT
  TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1
  NULL_IF = ('', 'NULL') EMPTY_FIELD_AS_NULL = TRUE;

CREATE STAGE IF NOT EXISTS RAW.RAW_STAGE FILE_FORMAT = RAW.CSV_FORMAT;

CREATE TABLE IF NOT EXISTS RAW.DESTINATIONS (
  destination_id STRING, city STRING, country STRING, region STRING, avg_price_index FLOAT);

CREATE TABLE IF NOT EXISTS RAW.CUSTOMERS (
  customer_id STRING, email_hash STRING, signup_date STRING, country STRING,
  loyalty_tier STRING, acquisition_channel STRING);

CREATE TABLE IF NOT EXISTS RAW.BOOKINGS (
  booking_id STRING, customer_id STRING, destination_id STRING, booking_date STRING,
  travel_start_date STRING, travel_end_date STRING, booking_channel STRING,
  booking_status STRING, num_travelers NUMBER, gross_amount NUMBER(12,2), currency STRING);

CREATE TABLE IF NOT EXISTS RAW.PAYMENTS (
  payment_id STRING, booking_id STRING, payment_date STRING, amount NUMBER(12,2),
  payment_method STRING, payment_status STRING, refund_amount NUMBER(12,2));

CREATE TABLE IF NOT EXISTS RAW.ENGAGEMENT_EVENTS (
  event_id STRING, customer_id STRING, event_ts STRING, event_type STRING, device STRING);

CREATE TABLE IF NOT EXISTS DQ.PIPELINE_AUDIT (
  run_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(), check_name STRING,
  table_name STRING, passed BOOLEAN, failed_rows NUMBER, detail STRING);
