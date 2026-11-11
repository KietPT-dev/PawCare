# PawCare API contract

The Public API is the canonical source of business state. Bonita receives only
durable outbox events and must never overwrite a booking, wallet or payment state.

## Base URL and health

`GET /api/v1/health` returns `200 { status: "UP", database: "UP" }` when the
API can make a safe `SELECT 1`; it returns `503` without database internals when
the database is unavailable.

## Booking and escrow

| Actor | Endpoint | Valid transition |
| --- | --- | --- |
| Provider | `POST /api/v1/bookings/{id}/service-done` | `IN_SERVICE -> SERVICE_DONE`; escrow remains locked |
| Customer | `POST /api/v1/bookings/{id}/confirm-completion` | `SERVICE_DONE -> COMPLETED`; settles 90% provider / 10% platform |
| Customer | `POST /api/v1/bookings/{id}/disputes` | `SERVICE_DONE -> DISPUTED`; escrow remains locked |
| Admin | `POST /api/v1/admin/disputes/{id}/resolve` | `DISPUTED -> COMPLETED` (release) or `CANCELLED` (refund) |

Provider rejection, customer cancellation and expiry call the same escrow release
operation. Repeated requests are safe because the ledger checks existing hold,
release and payout transactions.

### SERVICE_DONE confirmation SLA

`SERVICE_DONE` is never paid automatically. The configured confirmation window
is `PAWCARE_SERVICE_DONE_CONFIRMATION_HOURS` (default: `72`). A scheduler sends
one deduplicated reminder during the final
`PAWCARE_SERVICE_DONE_REMINDER_HOURS_BEFORE` hours (default: `24`). At expiry,
the booking becomes `SYSTEM_REVIEW`; escrow remains locked and an Admin must
choose the existing refund or provider-release decision. Every timeout writes a
status-history row, audit event, notifications, and a Bonita outbox event.

## Wallet withdrawal lifecycle

| Transition | Effect on provider wallet |
| --- | --- |
| `PENDING -> APPROVED` | Administrative approval only; amount stays locked. |
| `APPROVED -> PROCESSING` | Creates a local/manual payout reference; no bank call is made. |
| `PROCESSING -> PAID` | Decreases locked balance and records `WITHDRAWAL`. |
| `PENDING -> REJECTED` or `PROCESSING -> FAILED` | Returns the locked amount to available balance. |

Use `PUT /api/v1/admin/withdrawals/{id}` with a validated body such as
`{ "status": "APPROVED", "adminNote": "..." }`. `PAID` must be used only
after a real-world payout reconciliation. The bundled payout adapter is local
and deliberately cannot contact a bank.

## Reporting

- `GET /api/v1/provider/reports?from=YYYY-MM-DD&to=YYYY-MM-DD&timezone=Asia/Ho_Chi_Minh&granularity=DAY&page=0&size=50`
- `GET /api/v1/admin/reports/finance` with the same filters returns GMV, fee,
  escrow, payout/withdrawal totals, booking status counts, ledger page, and a
  `series` suitable for charts.
- `GET /api/v1/admin/reports/finance.csv` exports the filtered Admin booking
  summary. All API timestamps are formatted strings, never Java date objects.

The deployment database is configured in `Asia/Ho_Chi_Minh`; clients must send
an IANA timezone name so the requested reporting context is explicit.

## Payments

`POST /api/v1/payments/webhook` accepts SePay/PayOS-shaped JSON. Send
`Authorization: Apikey <token>` or `Authorization: Bearer <token>`. The code
recognises `PAW<depositId>` inside `content`/`transferContent`; `bank_tran_id`
is the idempotency key. Never put the token or bank account in client code.

## Account recovery and verification

`POST /api/v1/auth/password-reset/request` accepts `{ "email": "..." }` and
always returns an accepted response so an attacker cannot enumerate accounts.
`POST /api/v1/auth/password-reset/confirm` accepts `{ "token": "...",
"newPassword": "..." }`. Email verification follows the equivalent
`/email-verification/request` and `/email-verification/confirm` endpoints.
Tokens are stored only as hashes, expire after 30 minutes, are single-use and
revoke prior tokens of the same purpose. The deployment still needs an actual
mail sender to deliver the raw token; PawCare deliberately does not log or
return it.

## Frontend responsibilities

- **Mobile customer:** call booking confirmation/dispute only for the logged-in owner.
- **Provider web:** never show or call a direct completed transition; use service-done.

## Reviews and notifications

- `POST /api/v1/provider/reviews/{reviewId}/reply` lets the authenticated owner
  of a provider post or replace a response to a review. Body:
  `{ "content": "..." }` (1–5000 characters). The API verifies that the
  review belongs to that provider.
- `PUT /api/v1/notifications/read-all` marks the current authenticated user's
  unread notifications as read and returns `{ "success": true, "updated": n }`.
- **Bonita admin:** use admin dispute/withdrawal endpoints and show server error text.
- All clients should render the standard error payload: `status`, `error`, `timestamp`.
