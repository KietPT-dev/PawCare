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

## Marketplace discovery

`GET /api/v1/providers?status=APPROVED&sort=DEFAULT&page=0&size=20` returns
active Providers. `size` is capped at 100; `X-Page` and `X-Page-Size` echo the
effective page. Allowed `sort` values are `DEFAULT`, `RATING`, `NEWEST` and
`NEAREST`.

`NEAREST` requires an authenticated Customer whose saved address has
`geocodeStatus: RESOLVED`; otherwise the API returns `409`. It orders with the
server-side Haversine distance and includes scalar `distance_km`. The API never
pretends an un-geocoded address is a valid location.

Each Provider includes:

- `average_rating`: an average calculated from visible reviews;
- `review_count`: the number of visible reviews;
- `created_at`: scalar timestamp formatted `yyyy-MM-ddTHH:mm:ss`.
- `cover_image_url`: optional public Provider cover image;
- `distance_km`: present for `NEAREST` only.

Providers without visible reviews return `average_rating: 0` and
`review_count: 0`; the client must show “Chưa có đánh giá” rather than treat
`0` as a real score.

“Gần tôi” needs Provider coordinates and a granted device location permission.
Until both exist, clients must show the unavailable/fallback state rather than
pretending a geographical filter ran.

## Addresses and Provider cover images

`PUT /api/v1/auth/me` accepts the existing `address` string and optional
`addressLine1`, `ward`, `district`, `province`. `PUT /api/v1/provider/me`
accepts the same fields. A structured address is joined into the legacy
`address` field for compatibility. Both responses expose `latitude`,
`longitude` and `geocodeStatus` once migration 015 has run.

Address updates clear previous coordinates and queue geocoding. By default the
status becomes `NOT_CONFIGURED`, which is deliberate and safe. To enable real
geocoding set `PAWCARE_GEOCODING_PROVIDER=MAPBOX` and keep
`PAWCARE_GEOCODING_API_KEY` only in deployment secrets. The built-in Mapbox
adapter uses its forward-geocoding API; no secret is committed and no fallback
coordinates are fabricated.

Authenticated Providers manage their cover through:

- `POST /api/v1/provider/me/cover` with multipart field `file` (JPEG, PNG or
  WebP, maximum 5 MiB by default); and
- `DELETE /api/v1/provider/me/cover`.

Local development stores files outside source assets in
`PAWCARE_PROVIDER_COVER_DIRECTORY` and serves them under
`PAWCARE_PROVIDER_COVER_PUBLIC_PATH`. Production should supply an object-store
implementation of `ProviderCoverStorage` and its credentials as deployment
secrets.

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
