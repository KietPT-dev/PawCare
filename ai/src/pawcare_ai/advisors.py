from __future__ import annotations
import numpy as np
import pandas as pd
from sklearn.tree import DecisionTreeClassifier

INDEX_FEATURES=["query_frequency","scan_ratio","table_size","selectivity","cardinality","skew","candidate_column_count"]
def train_index_advisor(telemetry: pd.DataFrame, seed: int=20261127):
    return DecisionTreeClassifier(max_depth=4, random_state=seed).fit(telemetry[INDEX_FEATURES], telemetry["label"])
def recommend_index(model, telemetry: pd.DataFrame) -> list[dict]:
    out=[]
    for _, row in telemetry.iterrows():
        label=model.predict(pd.DataFrame([row[INDEX_FEATURES]]))[0]; confidence=float(model.predict_proba(pd.DataFrame([row[INDEX_FEATURES]])).max())
        cols=[x.strip() for x in str(row["candidate_columns"]).split(",") if x.strip()]
        out.append({"table":row["table"],"candidate_columns":cols[:2] if label=="COMPOSITE_BTREE_CANDIDATE" else cols[:1],"recommendation":label,"confidence":round(confidence,3),"reason":"Read-only recommendation based on synthetic query telemetry; review query frequency, scan ratio, and selectivity.","expected_review_required":True,"review":"Admin/Dev must validate with EXPLAIN ANALYZE before any change."})
    return out
def forecast_growth(growth: pd.DataFrame, threshold: int=1_500_000) -> list[dict]:
    from sklearn.linear_model import LinearRegression
    results=[]
    for table, group in growth.groupby("table"):
        group=group.sort_values("date"); n=len(group); x=np.arange(n).reshape(-1,1); y=group.row_count.to_numpy(); model=LinearRegression().fit(x,y); slope=float(model.coef_[0]); r2=float(model.score(x,y));
        day=None if slope<=0 else int(np.ceil((threshold-model.intercept_)/slope));
        results.append({"table":table,"threshold":threshold,"predicted_days_to_threshold":day,"confidence":round(max(0,r2),3),"assumption":"Linear row-growth trend continues; input is synthetic/read-only.","warning": None if n>=60 and r2>=.5 else "Insufficient history or non-linear trend; validate before capacity decisions.","recommendation":"Capacity planning only. No partitioning, table creation, or DDL is performed."})
    return results
