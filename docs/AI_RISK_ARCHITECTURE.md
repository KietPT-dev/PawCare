# PawCare AI risk architecture

PawCare uses MySQL 8 transactional outbox rows as the hand-off point for an
external Python Isolation Forest worker. The worker has no MySQL credentials:
it leases a minimal event over the internal HTTP API, returns a bounded score,
and can submit an INDEX or CAPACITY_FORECAST recommendation. The API stores the
result idempotently and makes the database state canonical.

Only an authenticated Admin can mark a score or recommendation reviewed,
dismissed, or (for recommendations) approved. Approval records review metadata
only: it does not lock accounts, refund money, change any ledger/payment row,
or execute DDL. Index Advisor output is a proposal, never a `CREATE INDEX` job.
Forecast output is similarly advisory and never partitions tables.

At present, scoreable outbox writes occur only with a successful
`PAYMENT_DEPOSIT_PAID` payment event. This deliberately narrow v1 scope avoids
claiming coverage for wallet, withdrawal, or booking events that do not yet
have every safe feature required by the model. When AI is disabled or its
tables are unavailable, the optional write cannot cause a money movement to
fail. Leases, unique dedupe keys and a unique score-per-outbox-event make
retries safe.

Feature snapshots are constrained to real, coarse payment-deposit features:
`amount`, `hourOfDay`, `dayOfWeek`, `accountAgeDays`, `transactionCount10m`,
`transactionCount1h`, `transactionCount24h`, `amountSum24h`, and
`priorFailedAttempts`; the delivery API additionally derives `eventAgeSeconds`.
The outbox stores only this allow-listed snapshot. Do not send raw PII, bank
payloads, account numbers, payment tokens, passwords, or internal tokens.
Aggregates that cannot provide every model feature are not enqueued. Simulated
AI data must never be mixed into ledger or payment business records.

The persisted Isolation Forest stores score calibration quantiles learned from
its training set. The worker uses that calibration for every event, including a
single leased event; it must never normalize against the current one-row batch.
Retrain the local model after upgrading a model version or feature set before
starting the worker.
