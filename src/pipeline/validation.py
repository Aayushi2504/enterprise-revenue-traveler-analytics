"""Pre-load data validation. Each check returns a dict so results can be logged,
written to an exceptions file, and asserted on in tests."""
from __future__ import annotations

import pandas as pd

from .config import EXCEPTIONS_DIR


def _result(name, table, passed, failed_rows, detail=""):
    return {"check": name, "table": table, "passed": bool(passed),
            "failed_rows": int(failed_rows), "detail": detail}


def check_not_null(df, table, cols):
    out = []
    for c in cols:
        n = int(df[c].isna().sum())
        out.append(_result("not_null", table, n == 0, n, c))
    return out


def check_unique(df, table, col):
    n = int(df[col].duplicated().sum())
    return _result("unique", table, n == 0, n, col)


def check_range(df, table, col, min_value=None, max_value=None):
    mask = pd.Series(False, index=df.index)
    if min_value is not None:
        mask |= df[col] < min_value
    if max_value is not None:
        mask |= df[col] > max_value
    return _result("range", table, mask.sum() == 0, mask.sum(), f"{col} in [{min_value},{max_value}]")


def check_allowed_values(df, table, col, allowed):
    n = int((~df[col].isin(allowed)).sum())
    return _result("allowed_values", table, n == 0, n, col)


def check_referential(child, child_table, child_col, parent, parent_col):
    n = int((~child[child_col].dropna().isin(parent[parent_col])).sum())
    return _result("referential_integrity", child_table, n == 0, n, f"{child_col}->{parent_col}")


def check_date_order(df, table, start_col, end_col):
    n = int((pd.to_datetime(df[start_col]) > pd.to_datetime(df[end_col])).sum())
    return _result("date_order", table, n == 0, n, f"{start_col}<={end_col}")


def run_all(tables: dict[str, pd.DataFrame]) -> pd.DataFrame:
    """Run the full rule set against the raw extracts."""
    b, c, p, d, e = (tables[k] for k in
                     ("bookings", "customers", "payments", "destinations", "engagement_events"))
    r = []
    r += check_not_null(b, "bookings", ["booking_id", "customer_id", "destination_id", "booking_date", "gross_amount"])
    r.append(check_unique(b, "bookings", "booking_id"))
    r.append(check_range(b, "bookings", "gross_amount", min_value=0))
    r.append(check_range(b, "bookings", "num_travelers", min_value=1, max_value=20))
    r.append(check_allowed_values(b, "bookings", "booking_status", ["confirmed", "completed", "cancelled"]))
    r.append(check_date_order(b, "bookings", "travel_start_date", "travel_end_date"))
    r.append(check_referential(b, "bookings", "customer_id", c, "customer_id"))
    r.append(check_referential(b, "bookings", "destination_id", d, "destination_id"))
    r += check_not_null(c, "customers", ["customer_id", "signup_date"])
    r.append(check_unique(c, "customers", "customer_id"))
    r += check_not_null(p, "payments", ["payment_id", "booking_id", "amount"])
    r.append(check_unique(p, "payments", "payment_id"))
    r.append(check_range(p, "payments", "amount", min_value=0))
    r.append(check_referential(p, "payments", "booking_id", b, "booking_id"))
    r.append(check_unique(e, "engagement_events", "event_id"))
    r.append(check_referential(e, "engagement_events", "customer_id", c, "customer_id"))
    return pd.DataFrame(r)


def reconcile_counts(source: dict[str, int], target: dict[str, int]) -> pd.DataFrame:
    rows = []
    for t, s in source.items():
        tg = target.get(t, 0)
        rows.append(_result("row_count_reconciliation", t, s == tg, abs(s - tg), f"source={s}, target={tg}"))
    return pd.DataFrame(rows)


def write_exceptions(report: pd.DataFrame) -> str:
    EXCEPTIONS_DIR.mkdir(parents=True, exist_ok=True)
    path = EXCEPTIONS_DIR / "validation_report.csv"
    report.to_csv(path, index=False)
    return str(path)
