import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import pandas as pd

from scripts.generate_synthetic_data import build
from src.pipeline.validation import reconcile_counts, run_all


def test_clean_data_passes_all_checks():
    report = run_all(build(500, 1, inject_defects=False))
    assert report.passed.all(), report[~report.passed]


def test_injected_defects_are_caught():
    report = run_all(build(500, 1, inject_defects=True))
    failed = set(report[~report.passed].check)
    assert {"unique", "not_null", "range"} <= failed


def test_row_count_reconciliation_flags_mismatch():
    r = reconcile_counts({"a": 10, "b": 5}, {"a": 10, "b": 4})
    assert r.set_index("table").passed.to_dict() == {"a": True, "b": False}
