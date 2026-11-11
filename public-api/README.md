# PawCare Public API

Spring Boot API used by the PawCare mobile customer app, Provider portal and Bonita Admin portal.

## Start locally

1. Apply only **new, unapplied** SQL files from `../database/` in numeric order. Do not modify or blindly rerun historical migrations that have already changed a shared database.
2. Configure MySQL and secrets outside Git. At minimum set database credentials, `PAWCARE_JWT_SECRET`, `PAWCARE_WALLET_WEBHOOK_TOKEN` and the VietQR receiving-account configuration.
3. Start from the workspace root:

   ```sh
   ./scripts/start-public-api.sh
   ```

   The API listens on `http://127.0.0.1:8081` by default. Confirm it with:

   ```sh
   curl http://127.0.0.1:8081/api/v1/health
   ```

4. Run the backend tests with:

   ```sh
   mvn -f public-api/pom.xml test
   ```

## Payments

PawCare uses the internal wallet/escrow ledger, VietQR deposit records and a SePay-compatible webhook. VNPAY is no longer part of the active integration.

The webhook accepts `Authorization: Apikey <token>` or `Authorization: Bearer <token>` (or the legacy internal token header), matches a payment code such as `PAW123`, and deduplicates on the bank transaction identifier. Never commit a webhook token or real bank details.

## API references

- [API contract](../docs/API_CONTRACT.md)
- [Wallet and escrow flow](docs/WALLET_ESCROW.md)
- [Bonita booking orchestration](docs/BONITA_BOOKING_ORCHESTRATION.md)
- [Automated test notes](docs/AUTOMATED_TESTING.md)

