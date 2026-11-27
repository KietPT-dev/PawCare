from __future__ import annotations
import numpy as np
import pandas as pd
from .schema import TRANSACTION_COLUMNS, TRANSACTION_TYPES

def generate_transactions(rows: int = 85_000, seed: int = 20261127, anomaly_rate: float = 0.02) -> pd.DataFrame:
    """Generate non-PII, synthetic records. Scenario is evaluation-only metadata."""
    if rows < 1 or not 0.01 <= anomaly_rate <= 0.03:
        raise ValueError("rows must be positive and anomaly_rate must be 1%-3%")
    r = np.random.default_rng(seed); n_anomaly = round(rows * anomaly_rate)
    when = pd.Timestamp("2026-01-01", tz="UTC") + pd.to_timedelta(r.integers(0, 180 * 86400, rows), unit="s")
    kinds = r.choice(TRANSACTION_TYPES, rows, p=[.25,.14,.14,.12,.12,.23])
    age = r.integers(7, 1800, rows); amount = np.round(r.lognormal(4.0, .8, rows), 2)
    c10 = r.poisson(.35, rows); c1 = c10 + r.poisson(1.1, rows); c24 = c1 + r.poisson(7, rows)
    scenario = np.full(rows, "NORMAL", dtype=object)
    idx = r.choice(rows, n_anomaly, replace=False); labels = np.array(["HIGH_AMOUNT", "BURST_ACTIVITY", "RAPID_WITHDRAWAL", "NEW_ACCOUNT_HIGH_VALUE", "NIGHT_UNUSUAL", "REPEATED_AMOUNT"])
    assigned = r.choice(labels, n_anomaly); scenario[idx] = assigned
    for name in labels:
        ix = idx[assigned == name]
        if name == "HIGH_AMOUNT": amount[ix] *= r.uniform(20, 60, len(ix))
        elif name == "BURST_ACTIVITY": c10[ix] = r.integers(8, 25, len(ix)); c1[ix] = c10[ix] + r.integers(5, 30, len(ix)); c24[ix] = c1[ix] + r.integers(10, 80, len(ix))
        elif name == "RAPID_WITHDRAWAL": kinds[ix] = "WITHDRAWAL"; amount[ix] *= r.uniform(5, 20, len(ix)); c10[ix] = r.integers(3, 12, len(ix))
        elif name == "NEW_ACCOUNT_HIGH_VALUE": age[ix] = r.integers(0, 14, len(ix)); amount[ix] *= r.uniform(12, 40, len(ix))
        elif name == "NIGHT_UNUSUAL": when.values[ix] = (when[ix].normalize() + pd.to_timedelta(r.integers(0, 4, len(ix)), unit="h")).values; amount[ix] *= r.uniform(6, 18, len(ix)); c1[ix] = r.integers(6, 20, len(ix))
        else: amount[ix] = 499.99; c24[ix] = r.integers(12, 40, len(ix))
    out = pd.DataFrame({"transaction_id": [f"syn_tx_{seed}_{i:06d}" for i in range(rows)], "profile_id": [f"syn_profile_{x:05d}" for x in r.integers(0, max(100, rows//8), rows)], "transaction_type": kinds, "amount": np.round(amount,2), "occurred_at": when.astype(str), "hour_of_day": when.hour, "day_of_week": when.dayofweek, "account_age_days": age, "transaction_count_10m": c10, "transaction_count_1h": c1, "transaction_count_24h": c24, "amount_sum_24h": np.round(amount * (1 + c24 * r.uniform(.25, .9, rows)), 2), "prior_failed_attempts": r.poisson(.12, rows), "is_synthetic": True, "scenario": scenario})
    return out[TRANSACTION_COLUMNS]

def generate_growth(days: int = 90, seed: int = 20261127) -> pd.DataFrame:
    r=np.random.default_rng(seed); dates=pd.date_range("2026-01-01", periods=days, freq="D")
    rows=[]
    for table, base, daily in [("wallet_transactions", 900_000, 2600), ("chat_messages", 400_000, 1800), ("notifications", 550_000, 2100)]:
        values=base + daily*np.arange(days) + r.normal(0, daily*.18, days)
        rows.extend({"date":str(d.date()), "table":table, "row_count":max(0,round(v))} for d,v in zip(dates,values))
    return pd.DataFrame(rows)

def generate_query_telemetry(rows: int = 300, seed: int = 20261127) -> pd.DataFrame:
    """Synthetic, read-only query telemetry for the M8 advisor."""
    r=np.random.default_rng(seed); tables=np.array(["wallet_transactions","chat_messages","notifications"])
    scan=r.uniform(0,1,rows); freq=r.integers(1,1000,rows); selectivity=r.uniform(.001,1,rows); cols=r.choice(["profile_id","occurred_at","profile_id,occurred_at","status"],rows)
    label=np.where((freq>200)&(scan>.35)&(selectivity<.2),np.where(np.char.find(cols.astype(str),",")>=0,"COMPOSITE_BTREE_CANDIDATE","BTREE_CANDIDATE"),"NO_INDEX")
    return pd.DataFrame({"table":r.choice(tables,rows),"candidate_columns":cols,"query_frequency":freq,"scan_ratio":scan,"table_size":r.integers(10_000,2_000_000,rows),"selectivity":selectivity,"cardinality":r.integers(2,500_000,rows),"skew":r.uniform(0,1,rows),"candidate_column_count":[x.count(",")+1 for x in cols],"label":label})
