# PawCare Public API

This service is the public API for Customer and Provider accounts. Bonita remains the Admin/BPMN back-office.

## First run

1. Execute `../database/003_public_auth_and_vnpay.sql` in DBeaver.
2. Set the values in `.env.example` in your shell environment. Never put real secrets in Git.
3. Start with `mvn spring-boot:run`.
4. Register with `POST /api/v1/auth/register`:
   `{ "fullName":"Nguyen Van A", "email":"a@example.test", "password":"Password123", "role":"CUSTOMER" }`
5. Login with `POST /api/v1/auth/login` and send `Authorization: Bearer <accessToken>` to create a payment:
   `POST /api/v1/payments/vnpay/create` with `{ "bookingId": 1 }`.

## VNPAY Sandbox

The app refuses payment creation until VNPAY settings are configured. `/ipn` is public by design, but verifies HMAC-SHA512 signature, transaction reference, amount, and idempotent final state before updating MySQL.

For local testing, expose port 8081 using a temporary HTTPS tunnel and register that public URL as VNPAY Return/IPN URL. Do not use localhost for IPN.
