# Architecture Notes

**Why layered schemas?** RAW preserves source fidelity for replay and audit. STG isolates cleansing logic. CORE holds conformed, business-ready entities. MART exposes KPI logic so BI tools never re-implement metric definitions.

**Why validate twice?** Pre-load checks stop bad extracts before they reach the warehouse. Post-load checks prove the transformations preserved totals (row counts, revenue tie-out) and results are persisted in `DQ.PIPELINE_AUDIT` for trend monitoring.

**Idempotency.** RAW tables are truncated and reloaded per run, and downstream tables use `CREATE OR REPLACE`, so re-running a DAG run is safe.

**PII.** Customer emails are hashed at source; no names, phone numbers, or addresses are modeled.
