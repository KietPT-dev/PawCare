from __future__ import annotations
import numpy as np
import pandas as pd
from joblib import dump, load
from sklearn.ensemble import IsolationForest
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import RobustScaler
from . import MODEL_VERSION
from .schema import FEATURE_COLUMNS

def train(frame: pd.DataFrame, seed: int = 20261127, contamination: float = .02) -> Pipeline:
    # scenario deliberately excluded: it is an evaluation label, never a training feature.
    trained = Pipeline([("scale", RobustScaler()), ("model", IsolationForest(n_estimators=200, contamination=contamination, random_state=seed))]).fit(frame[FEATURE_COLUMNS])
    # Persist calibration computed at training time. A worker scores one event
    # at a time, so normalizing against that one-row batch would always yield 0.
    raw = -trained.decision_function(frame[FEATURE_COLUMNS])
    lower, upper = np.quantile(raw, [.01, .99])
    if upper <= lower:
        raise ValueError("training data cannot calibrate a stable risk score")
    trained.pawcare_score_calibration_ = {"lower": float(lower), "upper": float(upper)}
    return trained

def save(model: Pipeline, path: str, seed: int) -> None: dump({"version":MODEL_VERSION,"seed":seed,"features":FEATURE_COLUMNS,"model":model}, path)
def restore(path: str): return load(path)
def score(model: Pipeline, frame: pd.DataFrame, medium: float=.55, high: float=.75) -> pd.DataFrame:
    if not 0 <= medium < high <= 1: raise ValueError("thresholds must satisfy 0 <= medium < high <= 1")
    calibration = getattr(model, "pawcare_score_calibration_", None)
    if not isinstance(calibration, dict) or calibration.get("upper", 0) <= calibration.get("lower", 0):
        raise ValueError("model lacks score calibration; retrain the model before running the worker")
    raw = -model.decision_function(frame[FEATURE_COLUMNS])
    normalized = np.clip((raw-calibration["lower"])/(calibration["upper"]-calibration["lower"]), 0, 1)
    result=frame[["transaction_id"]].copy(); result["risk_score"]=normalized.round(4)
    result["risk_level"]=np.where(normalized>=high,"HIGH",np.where(normalized>=medium,"MEDIUM","LOW"))
    def why(row):
        reasons=[]
        if row.amount > row.amount_sum_24h*.35: reasons.append("Số tiền cao hơn lịch sử 24 giờ")
        if row.transaction_count_1h >= 6: reasons.append("tần suất giao dịch bất thường")
        if row.account_age_days < 14 and row.amount > 500: reasons.append("tài khoản mới có giá trị giao dịch cao")
        return " và ".join(reasons) if reasons else "Điểm rủi ro dựa trên mẫu giao dịch bất thường"
    result["explanation"]=frame.apply(why,axis=1); result["model_version"]=MODEL_VERSION
    return result
