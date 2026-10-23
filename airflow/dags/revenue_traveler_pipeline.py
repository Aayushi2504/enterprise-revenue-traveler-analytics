"""Daily ELT pipeline: extract -> validate -> load RAW -> transform -> post-load checks.

Task graph:
  generate_extracts >> validate_extracts >> load_raw >> build_staging
      >> build_dimensions >> build_facts >> build_kpi_views >> post_load_checks
"""
from __future__ import annotations

import sys
from datetime import timedelta
from pathlib import Path

import pendulum
from airflow.decorators import dag, task
from airflow.exceptions import AirflowFailException

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src.pipeline import snowflake_client as sf  # noqa: E402
from src.pipeline.config import RAW_DIR, TABLES  # noqa: E402
from src.pipeline.validation import reconcile_counts, run_all, write_exceptions  # noqa: E402

default_args = {
    "owner": "analytics",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}


def _run_sql(filename: str):
    conn = sf.connect()
    try:
        sf.run_sql_file(conn, filename)
    finally:
        conn.close()


@dag(
    dag_id="revenue_traveler_analytics",
    schedule="0 5 * * *",
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    catchup=False,
    default_args=default_args,
    tags=["snowflake", "analytics", "looker"],
)
def revenue_traveler_pipeline():
    @task
    def generate_extracts():
        """Stand-in for source extraction. Swap for API/DB extracts in production."""
        import subprocess
        subprocess.run([sys.executable, "scripts/generate_synthetic_data.py"], check=True)

    @task
    def validate_extracts():
        import pandas as pd
        tables = {t: pd.read_csv(RAW_DIR / f"{t}.csv") for t in TABLES}
        report = run_all(tables)
        write_exceptions(report)
        failed = report[~report.passed]
        if len(failed):
            raise AirflowFailException(f"{len(failed)} validation checks failed:\n{failed.to_string()}")

    @task
    def load_raw():
        conn = sf.connect()
        try:
            sf.run_sql_file(conn, "00_setup.sql")
            loaded = sf.load_raw(conn)
        finally:
            conn.close()
        report = reconcile_counts(sf.source_counts(), loaded)
        if not report.passed.all():
            raise AirflowFailException(f"Row-count reconciliation failed:\n{report.to_string()}")

    @task
    def build_staging():
        _run_sql("01_staging.sql")

    @task
    def build_dimensions():
        _run_sql("02_dimensions.sql")

    @task
    def build_facts():
        _run_sql("03_facts.sql")

    @task
    def build_kpi_views():
        _run_sql("04_kpi_views.sql")

    @task
    def post_load_checks():
        conn = sf.connect()
        try:
            sf.run_sql_file(conn, "05_post_load_checks.sql")
            cur = conn.cursor()
            cur.execute("SELECT COUNT(*) FROM DQ.PIPELINE_AUDIT "
                        "WHERE passed = FALSE AND run_ts > DATEADD(hour, -1, CURRENT_TIMESTAMP())")
            n_failed = cur.fetchone()[0]
        finally:
            conn.close()
        if n_failed:
            raise AirflowFailException(f"{n_failed} post-load checks failed; see DQ.PIPELINE_AUDIT")

    (generate_extracts() >> validate_extracts() >> load_raw() >> build_staging()
     >> build_dimensions() >> build_facts() >> build_kpi_views() >> post_load_checks())


revenue_traveler_pipeline()
