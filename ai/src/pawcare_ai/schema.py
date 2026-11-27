TRANSACTION_COLUMNS = [
    "transaction_id", "profile_id", "transaction_type", "amount", "occurred_at",
    "hour_of_day", "day_of_week", "account_age_days", "transaction_count_10m",
    "transaction_count_1h", "transaction_count_24h", "amount_sum_24h",
    "prior_failed_attempts", "is_synthetic", "scenario",
]
TRANSACTION_TYPES = ["DEPOSIT", "ESCROW_HOLD", "ESCROW_RELEASE", "PROVIDER_PAYOUT", "WITHDRAWAL", "BOOKING_PAYMENT"]
SCENARIOS = ["NORMAL", "HIGH_AMOUNT", "BURST_ACTIVITY", "RAPID_WITHDRAWAL", "NEW_ACCOUNT_HIGH_VALUE", "NIGHT_UNUSUAL", "REPEATED_AMOUNT"]
FEATURE_COLUMNS = ["amount", "hour_of_day", "day_of_week", "account_age_days", "transaction_count_10m", "transaction_count_1h", "transaction_count_24h", "amount_sum_24h", "prior_failed_attempts"]
