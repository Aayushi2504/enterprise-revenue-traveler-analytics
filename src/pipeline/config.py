import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = ROOT / "data" / "raw"
SQL_DIR = ROOT / "sql" / "snowflake"
EXCEPTIONS_DIR = ROOT / "data" / "exceptions"

TABLES = ["destinations", "customers", "bookings", "payments", "engagement_events"]


def snowflake_params() -> dict:
    return {
        "account": os.environ["SNOWFLAKE_ACCOUNT"],
        "user": os.environ["SNOWFLAKE_USER"],
        "password": os.environ["SNOWFLAKE_PASSWORD"],
        "role": os.getenv("SNOWFLAKE_ROLE", "ANALYTICS_ROLE"),
        "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE", "ANALYTICS_WH"),
        "database": os.getenv("SNOWFLAKE_DATABASE", "TRAVEL_ANALYTICS"),
    }
