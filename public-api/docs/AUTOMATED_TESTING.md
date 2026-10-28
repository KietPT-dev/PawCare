# Automated verification

Start the Public API with its database/JWT environment variables, then run:

```zsh
cd /Applications/BonitaStudioCommunity-2025.2-u0.app/Contents/Eclipse/workspace/PawCare/public-api
export PAWCARE_E2E_ALLOW_DB_SETUP=true
./scripts/test-e2e.sh
```

The script needs the `mysql` command plus `PAWCARE_DB_USERNAME` and `PAWCARE_DB_PASSWORD`. It creates separate records named `AUTO-E2E`, then calls the real HTTP API to verify: Provider registration, service/staff/schedule creation, Customer registration/JWT/pet, availability, recommendation, booking, collision prevention, all Provider booking transitions, review, and the expected `503` when VNPAY is not configured.

The test changes a generated Provider from `PENDING` to `APPROVED` using SQL only to enable the automated test. The actual Bonita approval screen must still be demonstrated manually once. Real VNPAY redirect/IPN also needs Sandbox credentials and an HTTPS public callback URL, so it cannot be completed locally without those values.
