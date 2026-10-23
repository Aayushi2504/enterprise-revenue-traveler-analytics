"""Generate a synthetic travel dataset (customers, destinations, bookings,
payments, engagement events). No real or personal data is used.

Usage:
    python scripts/generate_synthetic_data.py --customers 5000 --out data/raw
    python scripts/generate_synthetic_data.py --inject-defects   # add dupes/nulls for DQ demo
"""
import argparse
import hashlib
from pathlib import Path

import numpy as np
import pandas as pd

DESTINATIONS = [
    ("Paris", "France", "Europe"), ("Rome", "Italy", "Europe"),
    ("Barcelona", "Spain", "Europe"), ("London", "United Kingdom", "Europe"),
    ("Tokyo", "Japan", "Asia"), ("Bangkok", "Thailand", "Asia"),
    ("Singapore", "Singapore", "Asia"), ("Dubai", "UAE", "Middle East"),
    ("New York", "USA", "North America"), ("Cancun", "Mexico", "North America"),
    ("Sydney", "Australia", "Oceania"), ("Cape Town", "South Africa", "Africa"),
]
COUNTRIES = ["USA", "India", "UK", "Germany", "Canada", "Australia", "France"]
CHANNELS = ["organic_search", "paid_search", "email", "social", "referral", "direct"]
TIERS = ["none", "silver", "gold", "platinum"]
PAY_METHODS = ["card", "paypal", "bank_transfer", "wallet"]
EVENT_TYPES = ["app_open", "search", "destination_view", "wishlist_add", "checkout_start", "email_click"]
DEVICES = ["ios", "android", "web", "tablet"]


def build(n_customers: int, seed: int, inject_defects: bool) -> dict:
    rng = np.random.default_rng(seed)

    # destinations
    dest = pd.DataFrame(DESTINATIONS, columns=["city", "country", "region"])
    dest.insert(0, "destination_id", [f"D{i:03d}" for i in range(1, len(dest) + 1)])
    dest["avg_price_index"] = rng.uniform(0.7, 1.6, len(dest)).round(2)

    # customers
    ids = [f"C{i:06d}" for i in range(1, n_customers + 1)]
    signup = pd.to_datetime("2023-01-01") + pd.to_timedelta(rng.integers(0, 1000, n_customers), unit="D")
    cust = pd.DataFrame({
        "customer_id": ids,
        "email_hash": [hashlib.sha256(f"{i}@example.test".encode()).hexdigest()[:32] for i in ids],
        "signup_date": signup.date,
        "country": rng.choice(COUNTRIES, n_customers, p=[.35, .2, .12, .08, .1, .08, .07]),
        "loyalty_tier": rng.choice(TIERS, n_customers, p=[.55, .25, .15, .05]),
        "acquisition_channel": rng.choice(CHANNELS, n_customers, p=[.25, .2, .15, .15, .1, .15]),
    })

    # bookings (~45% of customers book, some repeat)
    n_bk = int(n_customers * 0.9)
    bk_cust = rng.choice(ids, n_bk)
    signup_map = dict(zip(cust.customer_id, signup))
    booking_dt = [signup_map[c] + pd.Timedelta(days=int(rng.integers(0, 365))) for c in bk_cust]
    lead = rng.integers(7, 120, n_bk)
    start = pd.to_datetime(booking_dt) + pd.to_timedelta(lead, unit="D")
    nights = rng.integers(2, 15, n_bk)
    travelers = rng.integers(1, 6, n_bk)
    d_idx = rng.integers(0, len(dest), n_bk)
    base = dest["avg_price_index"].values[d_idx] * 180
    gross = (base * nights * np.sqrt(travelers) * rng.uniform(0.8, 1.3, n_bk)).round(2)
    bookings = pd.DataFrame({
        "booking_id": [f"B{i:07d}" for i in range(1, n_bk + 1)],
        "customer_id": bk_cust,
        "destination_id": dest["destination_id"].values[d_idx],
        "booking_date": pd.to_datetime(booking_dt).date,
        "travel_start_date": start.date,
        "travel_end_date": (start + pd.to_timedelta(nights, unit="D")).date,
        "booking_channel": rng.choice(["web", "app", "call_center", "partner"], n_bk, p=[.4, .4, .08, .12]),
        "booking_status": rng.choice(["confirmed", "completed", "cancelled"], n_bk, p=[.25, .62, .13]),
        "num_travelers": travelers,
        "gross_amount": gross,
        "currency": "USD",
    })

    # payments
    paid = bookings[bookings.booking_status != "cancelled"]
    pay = pd.DataFrame({
        "payment_id": [f"P{i:07d}" for i in range(1, len(paid) + 1)],
        "booking_id": paid.booking_id.values,
        "payment_date": paid.booking_date.values,
        "amount": paid.gross_amount.values,
        "payment_method": rng.choice(PAY_METHODS, len(paid), p=[.6, .15, .1, .15]),
        "payment_status": "captured",
        "refund_amount": np.where(rng.random(len(paid)) < 0.04,
                                  (paid.gross_amount.values * rng.uniform(.1, .5, len(paid))).round(2), 0.0),
    })

    # engagement events
    n_ev = n_customers * 12
    ev_cust = rng.choice(ids, n_ev)
    ev_ts = pd.to_datetime("2023-03-01") + pd.to_timedelta(rng.integers(0, 3 * 365 * 24 * 60, n_ev), unit="m")
    events = pd.DataFrame({
        "event_id": [f"E{i:08d}" for i in range(1, n_ev + 1)],
        "customer_id": ev_cust,
        "event_ts": ev_ts,
        "event_type": rng.choice(EVENT_TYPES, n_ev, p=[.25, .25, .2, .1, .1, .1]),
        "device": rng.choice(DEVICES, n_ev, p=[.35, .3, .3, .05]),
    })

    if inject_defects:
        bookings = pd.concat([bookings, bookings.sample(25, random_state=seed)], ignore_index=True)
        bookings.loc[bookings.sample(15, random_state=1).index, "customer_id"] = None
        pay.loc[pay.sample(10, random_state=2).index, "amount"] = -1.0
        events = pd.concat([events, events.sample(40, random_state=seed)], ignore_index=True)

    return {"destinations": dest, "customers": cust, "bookings": bookings,
            "payments": pay, "engagement_events": events}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--customers", type=int, default=5000)
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--out", default="data/raw")
    p.add_argument("--inject-defects", action="store_true")
    a = p.parse_args()

    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    for name, df in build(a.customers, a.seed, a.inject_defects).items():
        df.to_csv(out / f"{name}.csv", index=False)
        print(f"{name:<20} {len(df):>9,} rows -> {out / (name + '.csv')}")


if __name__ == "__main__":
    main()
