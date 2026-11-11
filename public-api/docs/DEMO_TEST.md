# PawCare Public API demo checklist

This checklist verifies the live wallet/escrow flow. It does not use VNPAY.

## Preconditions

1. Apply any new database migration once, in numeric order.
2. Start MySQL and the Public API. Verify `GET /api/v1/health` returns `UP`.
3. Configure `PAWCARE_WALLET_WEBHOOK_TOKEN` and VietQR settings in the local environment; never paste those values into source code or Git.
4. Sign in as a Customer, Provider and Admin test account.

## Main success flow

1. Customer creates a booking using `paymentMethod: "VIETQR"` or an already funded wallet. The response contains payment/deposit data and an identifier of the form `PAW<id>`.
2. For VietQR, make a sandbox/test bank transfer whose content includes the returned code. SePay calls `POST /api/v1/payments/webhook` with `Authorization: Apikey <token>` (or `Bearer <token>`).
3. Confirm the booking becomes `PENDING_APPROVAL`, payment is held in escrow, and a duplicate callback does not create another deposit or ledger entry.
4. Provider accepts, checks in, starts the service, then reports `SERVICE_DONE`. Money must remain locked.
5. Customer either confirms completion, which settles 90% to Provider and 10% to Platform, or opens a dispute.
6. Admin resolves a dispute to Provider or Customer and verify the ledger records and notifications.
7. Provider requests a withdrawal; Admin approves or rejects it. This is a ledger approval flow, not an automated real-bank payout.

## Negative checks

- Provider cannot move a booking directly from `IN_SERVICE` to `COMPLETED`.
- A Customer cannot confirm or dispute another Customer's booking.
- A rejected/cancelled booking releases escrow exactly once.
- A webhook with the wrong token returns `401`; a duplicate `bank_tran_id` is idempotent.

For endpoint payloads, roles and expected responses, use the repository-level [API contract](../../docs/API_CONTRACT.md).

