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

## Payments

`POST /api/v1/payments/webhook` accepts SePay/PayOS-shaped JSON. Send
`Authorization: Apikey <token>` or `Authorization: Bearer <token>`. The code
recognises `PAW<depositId>` inside `content`/`transferContent`; `bank_tran_id`
is the idempotency key. Never put the token or bank account in client code.

## Frontend responsibilities

- **Mobile customer:** call booking confirmation/dispute only for the logged-in owner.
- **Provider web:** never show or call a direct completed transition; use service-done.
- **Bonita admin:** use admin dispute/withdrawal endpoints and show server error text.
- All clients should render the standard error payload: `status`, `error`, `timestamp`.
