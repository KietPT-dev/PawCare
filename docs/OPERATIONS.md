# PawCare local operations

## Required local configuration

Copy only non-secret variable names into your shell or ignored `.env.local`:

`PAWCARE_DB_URL`, `PAWCARE_DB_USERNAME`, `PAWCARE_DB_PASSWORD`,
`PAWCARE_JWT_SECRET`, `PAWCARE_WALLET_WEBHOOK_TOKEN`,
`PAWCARE_VIETQR_BANK_CODE`, `PAWCARE_VIETQR_ACCOUNT_NO`,
`PAWCARE_VIETQR_ACCOUNT_NAME`, `PAWCARE_BONITA_WORKFLOW_ENABLED`,
`PAWCARE_BONITA_USERNAME`, `PAWCARE_BONITA_PASSWORD`,
`PAWCARE_MAIL_PROVIDER`, `PAWCARE_RESEND_API_KEY`, `PAWCARE_MAIL_FROM`,
`PAWCARE_MAIL_REPLY_TO`, and `PAWCARE_APP_DEEP_LINK_BASE`.

Do not commit values for any of them. A real bank account, SePay token, Bonita
technical-user password and JWT secret are manual deployment inputs.

## Transactional email (Resend)

Set `PAWCARE_MAIL_PROVIDER=RESEND`, a Resend sending API key in
`PAWCARE_RESEND_API_KEY`, and a sender verified by Resend in
`PAWCARE_MAIL_FROM`. For the PawCare domain configuration, the sender is
`PawCare <noreply@mail.pawcare.click>`. Configure
`PAWCARE_APP_DEEP_LINK_BASE=pawcare://auth` so verification and reset emails
open the installed customer app rather than a web page. `PAWCARE_MAIL_REPLY_TO`
is optional.

Leave the provider disabled when mail configuration is absent; account flows
remain non-enumerating and no action-token link is logged. Rotate a Resend key
by creating a replacement key in Resend, changing the deployment secret,
restarting the API, confirming delivery, then revoking the old key. Never add a
real key, recipient address, raw reset token, or `.env.local` to Git.

For a deliberate local smoke check, set the variables in ignored `.env.local`,
start the API, authenticate as a test account, then call
`POST /api/v1/auth/email-verification/request` or
`POST /api/v1/auth/password-reset/request`. Confirm receipt in the selected
test mailbox and open the `pawcare://auth/...` deep link from an installed app.

## Run and verify

```sh
mvn -f public-api/pom.xml test
./scripts/start-public-api.sh
cd pawcare-provider-web && npm ci && npm run dev
cd pawcare-customer-mobile && flutter pub get && flutter run
```

Run manual database scripts strictly in order through `009`. Migration `009`
uses a normal `ALTER TABLE` because older MySQL installations do not reliably
support `ADD COLUMN IF NOT EXISTS`; record it as applied and never rerun it.

## Future migration runner

The scripts remain manual to preserve current MySQL/Bonita environments. Before
production, introduce Flyway with a baseline at the schema already deployed,
then run each future `VNNN__description.sql` exactly once in CI/CD. Do not add
Flyway to a deployed database until that baseline is reviewed.

## OAuth/MFA

OAuth and MFA require a chosen identity provider, client IDs, redirect URLs,
email/SMS delivery, and a recovery policy. They are intentionally not enabled
until those real credentials and policies exist.
