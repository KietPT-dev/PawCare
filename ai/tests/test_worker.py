import importlib.util
import pathlib
from unittest.mock import Mock


WORKER = pathlib.Path(__file__).parents[1] / "scripts" / "worker.py"
spec = importlib.util.spec_from_file_location("pawcare_worker", WORKER)
worker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worker)

FEATURES = {"amount": 500.0, "hourOfDay": 9, "dayOfWeek": 2, "accountAgeDays": 30,
            "transactionCount10m": 1, "transactionCount1h": 2, "transactionCount24h": 4,
            "amountSum24h": 800.0, "priorFailedAttempts": 0, "eventAgeSeconds": 3}


def test_dry_run_never_calls_network(monkeypatch):
    network = Mock()
    monkeypatch.setattr(worker.requests, "request", network)
    monkeypatch.setattr(worker, "ENABLED", False)
    assert worker.request("GET", "/api/v1/internal/ai/scoring-events") is None
    network.assert_not_called()


def test_request_uses_internal_token_header(monkeypatch):
    response = Mock(); response.raise_for_status.return_value = None
    network = Mock(return_value=response)
    monkeypatch.setattr(worker.requests, "request", network)
    monkeypatch.setattr(worker, "ENABLED", True)
    monkeypatch.setattr(worker, "BASE", "http://api")
    monkeypatch.setattr(worker, "TOKEN", "secret")
    worker.request("GET", "/api/v1/internal/ai/scoring-events")
    assert network.call_args.kwargs["headers"] == {"X-PawCare-AI-Token": "secret"}


def test_missing_feature_is_skipped_without_post(monkeypatch):
    response = Mock(); response.json.return_value = [{"eventId": 8, "features": {"amount": 1}}]
    request = Mock(side_effect=[response])
    monkeypatch.setattr(worker, "request", request)
    monkeypatch.setattr(worker, "restore", Mock())
    worker.main()
    assert request.call_count == 1


def test_result_payload_is_camel_case():
    row = {"model_version": "v1", "risk_score": .5, "risk_level": "LOW", "explanation": "safe"}
    row.update({"amount": 1, "hour_of_day": 1, "day_of_week": 1, "account_age_days": 1,
                "transaction_count_10m": 1, "transaction_count_1h": 1, "transaction_count_24h": 1,
                "amount_sum_24h": 1, "prior_failed_attempts": 0})
    payload = worker.result_payload(row)
    assert set(payload) == {"modelName", "modelVersion", "riskScore", "riskLevel", "explanationSummary", "featureSnapshot"}
    assert "risk_score" not in payload and payload["featureSnapshot"]["hourOfDay"] == 1
