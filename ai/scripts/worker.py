"""Optional internal HTTP worker. Dry-run is the safe default.

The worker never opens a MySQL connection and deliberately logs identifiers only.
"""
import hashlib
import os
import pathlib
import sys
import time

import pandas as pd
import requests

sys.path.insert(0, str(pathlib.Path(__file__).parents[1] / "src"))
from pawcare_ai.risk import restore, score
from pawcare_ai.schema import FEATURE_COLUMNS

ENABLED = os.getenv("PAWCARE_AI_ENABLED", "false").lower() == "true"
BASE = os.getenv("PAWCARE_API_BASE_URL", "").rstrip("/")
TOKEN = os.getenv("PAWCARE_AI_WORKER_TOKEN", "")
MODEL_NAME = "isolation_forest"


def request(method, path, body=None):
    """Make bounded, authenticated requests only after explicit enablement."""
    if not ENABLED:
        print(f"dry-run {method} {path}")
        return None
    if not BASE or not TOKEN:
        raise RuntimeError("PAWCARE_API_BASE_URL and PAWCARE_AI_WORKER_TOKEN are required when enabled")
    for attempt in range(3):
        try:
            response = requests.request(method, BASE + path, json=body,
                headers={"X-PawCare-AI-Token": TOKEN}, timeout=10)
            response.raise_for_status()
            return response
        except requests.RequestException:
            if attempt == 2:
                raise
            time.sleep(2 ** attempt)


def model_features(event):
    """Translate the documented camelCase HTTP contract to the local model schema."""
    features = event.get("features")
    if not isinstance(features, dict):
        return None
    api_names = {
        "amount": "amount", "hour_of_day": "hourOfDay", "day_of_week": "dayOfWeek",
        "account_age_days": "accountAgeDays", "transaction_count_10m": "transactionCount10m",
        "transaction_count_1h": "transactionCount1h", "transaction_count_24h": "transactionCount24h",
        "amount_sum_24h": "amountSum24h", "prior_failed_attempts": "priorFailedAttempts",
    }
    result = {"transaction_id": str(event.get("eventId", ""))}
    for model_name in FEATURE_COLUMNS:
        value = features.get(api_names[model_name])
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            return None
        result[model_name] = value
    return result


def result_payload(row):
    return {
        "modelName": MODEL_NAME, "modelVersion": str(row["model_version"]),
        "riskScore": float(row["risk_score"]), "riskLevel": str(row["risk_level"]),
        "explanationSummary": str(row["explanation"]),
        "featureSnapshot": {key: row[key] for key in FEATURE_COLUMNS},
    }


def valid_result(payload):
    return (set(payload) == {"modelName", "modelVersion", "riskScore", "riskLevel", "explanationSummary", "featureSnapshot"}
            and 0 <= payload["riskScore"] <= 1 and payload["riskLevel"] in {"LOW", "MEDIUM", "HIGH"})


def main():
    response = request("GET", "/api/v1/internal/ai/scoring-events")
    if response is None:
        return
    model_data = restore(os.getenv("PAWCARE_AI_MODEL", "models/isolation_forest.joblib"))
    seen = set()
    for event in response.json():
        event_id = str(event.get("eventId", ""))
        key = hashlib.sha256(event_id.encode()).hexdigest()
        row = model_features(event)
        if not event_id or key in seen:
            continue
        if row is None:
            print(f"skip scoring event={event_id}: incomplete feature contract")
            continue
        scored = score(model_data["model"], pd.DataFrame([row])).iloc[0]
        payload = result_payload({**row, **scored.to_dict()})
        if valid_result(payload):
            request("POST", f"/api/v1/internal/ai/scoring-events/{event_id}/result", payload)
            seen.add(key)


if __name__ == "__main__":
    main()
