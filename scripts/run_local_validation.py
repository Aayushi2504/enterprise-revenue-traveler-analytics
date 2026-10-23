"""Run the validation rule set on local CSVs (no Snowflake needed)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import pandas as pd

from src.pipeline.config import RAW_DIR, TABLES
from src.pipeline.validation import run_all, write_exceptions

tables = {t: pd.read_csv(RAW_DIR / f"{t}.csv") for t in TABLES}
report = run_all(tables)
print(report.to_string(index=False))
print("\nReport written to", write_exceptions(report))
failed = report[~report.passed]
print(f"\n{len(report) - len(failed)}/{len(report)} checks passed")
sys.exit(1 if len(failed) else 0)
