# PawCare AI risk worker

Independent, synthetic-only decision support for a graduation project. It never opens a MySQL connection, runs DDL, or writes business tables. Risk output is an **anomaly/risk score**, never fraud confirmation.

## Setup and reproducibility

`python -m venv .venv && .venv/bin/pip install -r requirements.txt`

All commands run from `ai/`; seed defaults to `20261127` and is configurable.

```bash
PYTHONPATH=src python scripts/generate_data.py --rows 85000 --seed 20261127
PYTHONPATH=src python scripts/train_risk.py
PYTHONPATH=src python scripts/evaluate_risk.py
PYTHONPATH=src python scripts/operational_advice.py > recommendations.json
PYTHONPATH=src python scripts/worker.py                 # dry run (default)
PAWCARE_AI_ENABLED=true PAWCARE_API_BASE_URL=http://localhost:8080 PAWCARE_AI_WORKER_TOKEN=... PYTHONPATH=src python scripts/worker.py
pytest -q
```

The generator creates 85,000+ local rows; generated CSVs and joblib models are ignored by Git. `data/sample/` holds only a small synthetic sample. Transaction scenarios are evaluation labels only and are expressly excluded from Isolation Forest features.

## Model behavior

Isolation Forest uses amount, timing, account age, velocity, 24h amount and prior-failure features with robust scaling. Scores are normalized to 0–1; defaults are MEDIUM `>=.55`, HIGH `>=.75`. Evaluation reports precision, recall, and recall@high-risk against synthetic `scenario`.

Index Advisor M8 is a read-only Decision Tree that outputs only `NO_INDEX`, `BTREE_CANDIDATE`, or `COMPOSITE_BTREE_CANDIDATE` JSON. It never recommends partial indexes (unsupported in MySQL) and requires Admin/Dev review with `EXPLAIN ANALYZE`.

Growth Forecast M10 applies linear regression to >=60 daily observations for `wallet_transactions`, `chat_messages`, and `notifications`. It returns capacity advice and warnings, never partitions or issues DDL.

## HTTP guardrails

HTTP is disabled unless `PAWCARE_AI_ENABLED=true`, `PAWCARE_API_BASE_URL`, and
`PAWCARE_AI_WORKER_TOKEN` are all present. It reads only
`GET /api/v1/internal/ai/scoring-events` and can POST results/recommendations to
the documented internal endpoints. Every request uses
`X-PawCare-AI-Token`; it never uses an Authorization bearer token. The worker
reads `eventId`, maps camelCase API features to the local model schema, and
posts the camelCase result contract (`modelName`, `modelVersion`, `riskScore`,
`riskLevel`, `explanationSummary`, `featureSnapshot`). It skips incomplete
features without posting a result. Requests use bounded retries and in-memory
duplicate suppression; tokens, PII, and raw financial payloads are not logged.
Production callers should enforce idempotency server-side too.
