# PawCare Wallet and Escrow Ledger

## Run order

Run `database/005_wallet_escrow_ledger.sql` once after migrations `001` to `004`.
All balance writes use InnoDB row locks and Spring transactions. Never edit a
wallet balance directly; use the public API/service so an immutable
`wallet_transactions` record is written with the change.

## Required environment configuration

```bash
PAWCARE_WALLET_WEBHOOK_TOKEN=<long-random-secret>
PAWCARE_VIETQR_BANK_CODE=VCB
PAWCARE_VIETQR_ACCOUNT_NO=<business-account-number>
PAWCARE_VIETQR_ACCOUNT_NAME=PawCare
```

The bank account values belong on the server only. The mobile client receives a
generated VietQR image URL but never receives the webhook secret.

## Booking contract

`POST /api/v1/bookings` now accepts a `paymentMethod` field:

```json
{
  "petId": 1,
  "providerId": 2,
  "serviceId": 3,
  "bookingStart": "2026-11-02 09:00:00",
  "customerNote": "Nhẹ nhàng với bé",
  "paymentMethod": "VIETQR"
}
```

- `WALLET`: deducts `available_balance`, increases `locked_balance`, then sets
  booking status to `PENDING_APPROVAL`.
- `VIETQR`: creates one deposit with a code such as `PAW42`, returns `qrUrl`,
  and leaves booking in `PENDING_PAYMENT` until the webhook succeeds.

Provider booking lists exclude unpaid `PENDING_PAYMENT` rows. Once escrow is
held, a provider can use the normal lifecycle:
`PENDING_APPROVAL -> CONFIRMED -> CHECKED_IN -> IN_SERVICE -> COMPLETED`.

Reject/cancel releases escrow. Completion pays 90% to provider and credits 10%
to the platform wallet. The scheduled expiry task cancels/release funded bookings
whose appointment has passed while still awaiting provider approval.

## Webhook

`POST /api/payments/webhook` (also available at `/api/v1/payments/webhook`)
requires `X-PawCare-Webhook-Token`. The normaliser accepts common SePay/PayOS
names: transaction id (`id`, `transaction_id`, `referenceCode`), transfer
content (`content`, `description`, `orderCode`) and amount (`amount`,
`transferAmount`). The content must include `PAW{id}`.

The unique `bank_tran_id` makes a repeated callback idempotent. A production
bank/PayOS adapter should validate its provider signature before forwarding the
event to this endpoint.

## Wallet and withdrawal endpoints

- `GET /api/v1/wallets/me`
- `GET /api/v1/wallets/me/transactions`
- `POST /api/v1/wallets/withdraw`
- `GET /api/v1/admin/withdrawals?status=PENDING` (ADMIN)
- `PUT /api/v1/admin/withdrawals/{id}` (ADMIN; `APPROVED` or `REJECTED`)

Creating a withdrawal reserves money in `locked_balance`. Approval consumes the
reserve; rejection returns it to `available_balance`. Actual bank disbursement
can be performed through Bonita and its case id stored in `bonita_case_id`.
