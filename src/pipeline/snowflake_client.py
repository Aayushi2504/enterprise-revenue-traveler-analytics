import logging

import pandas as pd
import snowflake.connector

from .config import RAW_DIR, SQL_DIR, TABLES, snowflake_params

log = logging.getLogger(__name__)


def connect():
    return snowflake.connector.connect(**snowflake_params())


def run_sql_file(conn, filename: str) -> None:
    sql = (SQL_DIR / filename).read_text()
    log.info("Running %s", filename)
    conn.execute_string(sql)


def load_raw(conn) -> dict[str, int]:
    """PUT local CSVs to the internal stage and COPY INTO RAW tables."""
    counts = {}
    cur = conn.cursor()
    cur.execute("USE SCHEMA RAW")
    for t in TABLES:
        path = (RAW_DIR / f"{t}.csv").as_posix()
        cur.execute(f"PUT file://{path} @RAW.RAW_STAGE AUTO_COMPRESS=TRUE OVERWRITE=TRUE")
        cur.execute(f"TRUNCATE TABLE RAW.{t.upper()}")
        cur.execute(
            f"COPY INTO RAW.{t.upper()} FROM @RAW.RAW_STAGE/{t}.csv.gz "
            "FILE_FORMAT=(FORMAT_NAME=RAW.CSV_FORMAT) ON_ERROR='ABORT_STATEMENT'"
        )
        cur.execute(f"SELECT COUNT(*) FROM RAW.{t.upper()}")
        counts[t] = cur.fetchone()[0]
        log.info("Loaded %s: %s rows", t, counts[t])
    return counts


def source_counts() -> dict[str, int]:
    return {t: len(pd.read_csv(RAW_DIR / f"{t}.csv")) for t in TABLES}
